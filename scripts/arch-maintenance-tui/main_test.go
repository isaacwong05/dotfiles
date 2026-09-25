package main

import (
	"testing"

	tea "github.com/charmbracelet/bubbletea"
)

func TestLineWriterStreamsCompleteLinesAndFlushesPartialLine(t *testing.T) {
	stream := make(chan streamMsg, 4)
	writer := &lineWriter{stream: stream}
	if _, err := writer.Write([]byte("one\ntwo")); err != nil {
		t.Fatal(err)
	}
	writer.flush()
	close(stream)

	var got []string
	for message := range stream {
		got = append(got, message.line)
	}
	want := []string{"one", "two"}
	if len(got) != len(want) || got[0] != want[0] || got[1] != want[1] {
		t.Fatalf("got %#v, want %#v", got, want)
	}
}

func TestSelectedPackagesPreservesOrphanOrder(t *testing.T) {
	model := model{
		data:     snapshot{orphans: []string{"alpha", "beta", "gamma"}},
		selected: map[string]bool{"gamma": true, "alpha": true},
	}
	got := model.selectedPackages()
	want := []string{"alpha", "gamma"}
	if len(got) != len(want) || got[0] != want[0] || got[1] != want[1] {
		t.Fatalf("got %#v, want %#v", got, want)
	}
}

func TestCurrentRowsUsesCombinedUpdateLists(t *testing.T) {
	model := model{tab: updates, data: snapshot{updates: []string{"linux"}, aur: []string{"foo-bin"}}}
	got := model.currentRows()
	if len(got) != 2 || got[0] != "linux" || got[1] != "foo-bin" {
		t.Fatalf("got %#v", got)
	}
}

func TestSpaceTogglesOrphanSelection(t *testing.T) {
	m := model{tab: orphans, data: snapshot{orphans: []string{"unused"}}, selected: map[string]bool{}}
	updated, _ := m.key(tea.KeyMsg{Type: tea.KeySpace})
	got := updated.(model).selected["unused"]
	if !got {
		t.Fatal("space should select the highlighted orphan")
	}
}

func TestRunStreamEmitsOutputAndCompletion(t *testing.T) {
	stream := make(chan streamMsg, 4)
	runStream([]string{"printf", "hello\\n"}, stream)
	var lines []string
	for message := range stream {
		if message.line != "" {
			lines = append(lines, message.line)
		}
		if message.done && message.err != nil {
			t.Fatal(message.err)
		}
	}
	if len(lines) != 1 || lines[0] != "hello" {
		t.Fatalf("got %#v", lines)
	}
}
