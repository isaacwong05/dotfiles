package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

const (
	dashboard = iota
	orphans
	updates
	services
	activity
)

var tabs = []string{"Dashboard", "Orphans", "Updates", "Services", "Activity"}

var (
	activeTab     = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#ffffff")).Background(lipgloss.Color("#444444")).Padding(0, 1)
	inactiveTab   = lipgloss.NewStyle().Foreground(lipgloss.Color("#888888")).Padding(0, 1)
	titleStyle    = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("#ffffff"))
	mutedStyle    = lipgloss.NewStyle().Foreground(lipgloss.Color("#888888"))
	dangerStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("#ff7777"))
	selectedStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("#ffffff"))
)

type snapshot struct {
	disk     string
	cache    string
	orphans  []string
	updates  []string
	aur      []string
	services []string
	journal  []string
}

type refreshMsg struct{ data snapshot }

type streamMsg struct {
	line string
	done bool
	err  error
}

type pendingTask struct {
	label string
	args  []string
}

type model struct {
	tab        int
	cursor     int
	width      int
	height     int
	data       snapshot
	selected   map[string]bool
	output     []string
	offset     int
	running    bool
	stream     <-chan streamMsg
	task       string
	status     string
	confirming *pendingTask
	lastError  error
}

func main() {
	if !authenticate() {
		fmt.Fprintln(os.Stderr, "sudo authentication failed; the TUI can still be used for read-only checks")
	}
	program := tea.NewProgram(model{selected: map[string]bool{}, status: "loading…"}, tea.WithAltScreen())
	if _, err := program.Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func authenticate() bool {
	if os.Geteuid() == 0 {
		return true
	}
	sudo, err := exec.LookPath("sudo")
	if err != nil {
		return false
	}
	if exec.Command(sudo, "-n", "-v").Run() == nil {
		return true
	}
	if !stdinIsTerminal() {
		return false
	}
	fmt.Println("Authenticate for maintenance actions (read-only browsing still works):")
	cmd := exec.Command(sudo, "-v")
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	return cmd.Run() == nil
}

func stdinIsTerminal() bool {
	info, err := os.Stdin.Stat()
	return err == nil && info.Mode()&os.ModeCharDevice != 0
}

func (m model) Init() tea.Cmd { return loadSnapshot }

func loadSnapshot() tea.Msg {
	data := snapshot{
		disk:    queryOne("df", "-h", "/"),
		cache:   queryOne("du", "-sh", "/var/cache/pacman/pkg"),
		orphans: queryLines("pacman", "-Qtdq"),
		services: append(
			queryLines("systemctl", "--failed", "--no-legend", "--no-pager"),
			queryLines("systemctl", "--user", "--failed", "--no-legend", "--no-pager")...,
		),
		journal: queryLines("journalctl", "-b", "-p", "3", "-n", "30", "--no-pager"),
	}
	if commandExists("checkupdates") {
		data.updates = queryLines("checkupdates")
	}
	if commandExists("paru") {
		data.aur = queryLines("paru", "-Qua")
	}
	return refreshMsg{data: data}
}

func commandExists(name string) bool { _, err := exec.LookPath(name); return err == nil }

func queryOne(name string, args ...string) string {
	lines := queryLines(name, args...)
	if len(lines) == 0 {
		return "unavailable"
	}
	if name == "df" && len(lines) > 1 {
		return lines[len(lines)-1]
	}
	return lines[0]
}

func queryLines(name string, args ...string) []string {
	path, err := exec.LookPath(name)
	if err != nil {
		return nil
	}
	cmd := exec.Command(path, args...)
	output, err := cmd.Output()
	if err != nil && len(output) == 0 {
		return nil
	}
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(lines) == 1 && lines[0] == "" {
		return nil
	}
	return limitLines(lines, 100)
}

func limitLines(lines []string, limit int) []string {
	if len(lines) <= limit {
		return lines
	}
	return append(append([]string{}, lines[:limit]...), fmt.Sprintf("… (%d more)", len(lines)-limit))
}

func (m model) InitTask(task pendingTask) tea.Cmd {
	return func() tea.Msg {
		stream := make(chan streamMsg, 256)
		go runStream(task.args, stream)
		return streamStarted{task: task.label, stream: stream}
	}
}

type streamStarted struct {
	task   string
	stream <-chan streamMsg
}

func runStream(args []string, stream chan<- streamMsg) {
	defer close(stream)
	cmd := exec.Command(args[0], args[1:]...)
	writer := &lineWriter{stream: stream}
	cmd.Stdout, cmd.Stderr = writer, writer
	err := cmd.Run()
	writer.flush()
	stream <- streamMsg{done: true, err: err}
}

type lineWriter struct {
	mu     sync.Mutex
	stream chan<- streamMsg
	buf    string
}

func (w *lineWriter) Write(p []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	w.buf += string(p)
	for {
		index := strings.IndexByte(w.buf, '\n')
		if index < 0 {
			break
		}
		line := strings.TrimRight(w.buf[:index], "\r")
		w.buf = w.buf[index+1:]
		w.stream <- streamMsg{line: line}
	}
	return len(p), nil
}

func (w *lineWriter) flush() {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.buf != "" {
		w.stream <- streamMsg{line: w.buf}
		w.buf = ""
	}
}

func waitStream(stream <-chan streamMsg) tea.Cmd {
	return func() tea.Msg {
		message, ok := <-stream
		if !ok {
			return streamMsg{done: true}
		}
		return message
	}
}

func privileged(args ...string) []string {
	if os.Geteuid() == 0 {
		return args
	}
	if commandExists("sudo") {
		return append([]string{"sudo", "-n"}, args...)
	}
	if commandExists("doas") {
		return append([]string{"doas", "-n"}, args...)
	}
	return args
}

func (m model) Update(message tea.Msg) (tea.Model, tea.Cmd) {
	switch message := message.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = message.Width, message.Height
	case refreshMsg:
		m.data = message.data
		m.status = "ready"
		m.cursor = min(m.cursor, max(0, len(m.currentRows())-1))
	case streamStarted:
		m.running, m.task, m.stream = true, message.task, message.stream
		m.output, m.offset, m.status, m.lastError = nil, 0, "running", nil
		return m, waitStream(m.stream)
	case streamMsg:
		if message.line != "" {
			m.output = append(m.output, message.line)
			if m.following() {
				m.offset = max(0, len(m.output)-m.outputHeight())
			}
		}
		if message.done {
			m.running = false
			m.lastError = message.err
			if message.err != nil {
				m.status = "failed: " + message.err.Error()
			} else {
				m.status = "finished"
			}
			return m, loadSnapshot
		}
		return m, waitStream(m.stream)
	case tea.KeyMsg:
		return m.key(message)
	}
	return m, nil
}

func (m model) key(message tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.confirming != nil {
		switch message.String() {
		case "y", "enter":
			task := *m.confirming
			m.confirming = nil
			return m, m.InitTask(task)
		case "n", "esc", "q":
			m.confirming = nil
			m.status = "cancelled"
		}
		return m, nil
	}

	switch message.String() {
	case "ctrl+c", "q":
		if !m.running {
			return m, tea.Quit
		}
	case "tab", "right", "l":
		m.tab = (m.tab + 1) % len(tabs)
		m.cursor, m.offset = 0, 0
	case "shift+tab", "left", "h":
		m.tab = (m.tab + len(tabs) - 1) % len(tabs)
		m.cursor, m.offset = 0, 0
	case "1", "2", "3", "4", "5":
		m.tab = int(message.String()[0] - '1')
		m.cursor, m.offset = 0, 0
	case "j", "down":
		if m.tab == activity {
			m.offset = min(m.offset+1, max(0, len(m.output)-m.outputHeight()))
		} else {
			m.cursor = min(m.cursor+1, max(0, len(m.currentRows())-1))
		}
	case "k", "up":
		if m.tab == activity {
			m.offset = max(m.offset-1, 0)
		} else {
			m.cursor = max(m.cursor-1, 0)
		}
	case "g":
		if m.tab == activity {
			m.offset = 0
		} else {
			m.cursor = 0
		}
	case "G":
		if m.tab == activity {
			m.offset = max(0, len(m.output)-m.outputHeight())
		} else {
			m.cursor = max(0, len(m.currentRows())-1)
		}
	case "r":
		if !m.running {
			m.status = "refreshing…"
			return m, loadSnapshot
		}
	case " ":
		if m.tab == orphans && len(m.data.orphans) > 0 {
			if m.selected == nil {
				m.selected = map[string]bool{}
			}
			name := m.data.orphans[m.cursor]
			m.selected[name] = !m.selected[name]
		}
	case "a":
		if m.tab == orphans {
			for _, name := range m.data.orphans {
				m.selected[name] = true
			}
		} else if m.tab == updates {
			if !commandExists("paru") {
				m.status = "paru is not installed"
				return m, nil
			}
			return m.confirmTask("Update AUR packages", []string{"paru", "-Sua", "--noconfirm"})
		}
	case "n":
		if m.tab == orphans {
			m.selected = map[string]bool{}
		}
	case "d":
		if m.tab == orphans {
			packages := m.selectedPackages()
			if len(packages) > 0 {
				return m.confirmTask("Remove selected orphan packages", append(privileged("pacman", "-Rns", "--noconfirm", "--"), packages...))
			}
			m.status = "select orphan packages first"
		}
	case "u":
		return m.confirmTask("Update official packages", privileged("pacman", "-Syu", "--noconfirm"))
	case "c":
		if m.tab == dashboard || m.tab == activity {
			if !commandExists("paccache") {
				m.status = "paccache unavailable; install pacman-contrib"
				return m, nil
			}
			return m.confirmTask("Clean package cache (keep 3 versions)", privileged("paccache", "-r", "-k", "3"))
		}
	case "enter":
		if m.tab == activity && len(m.output) > 0 {
			m.offset = max(0, len(m.output)-m.outputHeight())
		}
	}
	return m, nil
}

func (m model) confirmTask(label string, args []string) (tea.Model, tea.Cmd) {
	if m.running {
		m.status = "a task is already running"
		return m, nil
	}
	m.confirming = &pendingTask{label: label, args: args}
	m.status = "confirm: y/enter · cancel: n/esc"
	return m, nil
}

func (m model) selectedPackages() []string {
	packages := make([]string, 0)
	for _, name := range m.data.orphans {
		if m.selected[name] {
			packages = append(packages, name)
		}
	}
	return packages
}

func (m model) currentRows() []string {
	switch m.tab {
	case orphans:
		return m.data.orphans
	case updates:
		return append(append([]string{}, m.data.updates...), m.data.aur...)
	case services:
		return m.data.services
	case activity:
		return m.output
	default:
		return nil
	}
}

func (m model) following() bool   { return m.offset >= max(0, len(m.output)-m.outputHeight()-1) }
func (m model) outputHeight() int { return max(3, m.height-9) }

func (m model) View() string {
	if m.width == 0 {
		return ""
	}
	var b strings.Builder
	b.WriteString(titleStyle.Render("ARCH MAINTENANCE TUI"))
	b.WriteString("  ")
	b.WriteString(mutedStyle.Render(time.Now().Format("2006-01-02 15:04")))
	b.WriteString("\n\n")
	for index, tab := range tabs {
		if index == m.tab {
			b.WriteString(activeTab.Render(fmt.Sprintf("%d %s", index+1, tab)))
		} else {
			b.WriteString(inactiveTab.Render(fmt.Sprintf("%d %s", index+1, tab)))
		}
	}
	b.WriteString("\n\n")

	if m.confirming != nil {
		b.WriteString(dangerStyle.Render("CONFIRM: " + m.confirming.label + "?  [y]es / [n]o"))
		b.WriteString("\n\n")
	}
	b.WriteString(m.renderTab())

	if m.tab != activity && (m.running || len(m.output) > 0) {
		b.WriteString("\n\n")
		b.WriteString(titleStyle.Render("Live output"))
		b.WriteString(mutedStyle.Render("  " + m.task))
		b.WriteString("\n")
		b.WriteString(m.renderOutput())
	}

	b.WriteString("\n")
	b.WriteString(mutedStyle.Render("tab/h l panels · j/k move · r refresh · q quit · " + m.status))
	return b.String()
}

func (m model) renderTab() string {
	switch m.tab {
	case dashboard:
		return strings.Join([]string{
			titleStyle.Render("System"),
			"  " + m.data.disk,
			"  pacman cache: " + m.data.cache,
			"",
			fmt.Sprintf("  orphan packages: %d", len(m.data.orphans)),
			fmt.Sprintf("  official updates: %d", len(m.data.updates)),
			fmt.Sprintf("  AUR updates: %d", len(m.data.aur)),
			fmt.Sprintf("  failed services: %d", len(m.data.services)),
			"",
			mutedStyle.Render("u update official · a update AUR (Updates panel) · c clean cache"),
		}, "\n")
	case orphans:
		return m.renderList(m.data.orphans, true, "space select · a all · n none · d remove selected")
	case updates:
		rows := append([]string{"Official updates:"}, m.data.updates...)
		rows = append(rows, "", "AUR updates:")
		rows = append(rows, m.data.aur...)
		return m.renderList(rows, false, "u update official · a update AUR")
	case services:
		return m.renderList(m.data.services, false, "journal errors are in Activity output after refresh")
	case activity:
		if len(m.output) == 0 {
			return strings.Join(append([]string{titleStyle.Render("Activity")}, m.data.journal...), "\n")
		}
		return m.renderOutput()
	default:
		return ""
	}
}

func (m model) renderList(rows []string, selectable bool, hint string) string {
	if len(rows) == 0 {
		return mutedStyle.Render("none\n\n" + hint)
	}
	start := max(0, m.cursor-m.height+10)
	end := min(len(rows), start+max(3, m.height-10))
	var b strings.Builder
	for index, row := range rows[start:end] {
		actual := index + start
		prefix := "  "
		if actual == m.cursor {
			prefix = "> "
		}
		if selectable {
			check := "[ ]"
			if m.selected[row] {
				check = "[x]"
			}
			prefix += check + " "
		}
		if actual == m.cursor {
			b.WriteString(selectedStyle.Render(prefix + row))
		} else {
			b.WriteString(prefix + row)
		}
		b.WriteString("\n")
	}
	b.WriteString("\n")
	b.WriteString(mutedStyle.Render(hint))
	return strings.TrimSuffix(b.String(), "\n")
}

func (m model) renderOutput() string {
	if len(m.output) == 0 {
		return mutedStyle.Render("waiting for output…")
	}
	start := min(m.offset, len(m.output)-1)
	end := min(len(m.output), start+m.outputHeight())
	var b strings.Builder
	for _, line := range m.output[start:end] {
		b.WriteString(clip(line, max(20, m.width-2)))
		b.WriteString("\n")
	}
	return strings.TrimSuffix(b.String(), "\n")
}

func clip(value string, width int) string {
	if len(value) <= width {
		return value
	}
	return value[:max(0, width-1)] + "…"
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

var _ io.Writer = (*lineWriter)(nil)
