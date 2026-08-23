# dotfiles

my personal config. currently mid-migration from nixos to arch — the
`nixos-archive/` dir is the old flake (reference only), `config/` holds
portable `~/.config` app configs that work on any distro.

## overview

a [niri](https://github.com/YaLTeR/niri) scrolling-tiling wayland setup,
themed around a minimal monochrome look with a noctalia shell.

## repo layout

| path              | description                                                  |
| ----------------- | ------------------------------------------------------------ |
| `niri/`           | niri compositor config, keybinds, scripts                    |
| `ghostty/`        | ghostty terminal config                                      |
| `nvim/`           | neovim config (lazyvim-based)                                |
| `.zshrc`          | zsh config (zinit, starship, zoxide)                         |
| `config/`         | portable `~/.config` app configs (btop, mpv, starship, …)    |
| `nixos-archive/`  | old nixos flake — reference only, no longer maintained       |

## stack at a glance

- **os:** arch (migrating from nixos)
- **compositor:** niri
- **shell (desktop):** noctalia (quickshell)
- **terminal:** ghostty
- **editor:** neovim / lazyvim
- **shell:** zsh + starship + zinit
- **bootloader:** limine (was on nixos)
- **login:** greetd + tuigreet

---

# installed software

sourced from the last nixos config (`nixos-archive/configuration.nix` +
`home.nix`). every package below was installed on the system before the
arch switch; use it as a shopping list for the arch install.

## by role

### window manager & desktop

| package | what |
| --- | --- |
| niri | scrolling-tiling wayland compositor |
| noctalia | quickshell-based desktop shell (bar, launcher, notifications) |
| quickshell | qt-based shell framework (noctalia dep) |
| xwayland-satellite | rootless xwayland for wayland compositors |
| swaylock-plugin | screen locker (runs a command per locked surface) |
| swayidle | idle daemon (lock at 5m, power-off monitors at 10m) |
| windowtolayer | puts a locked surface into the layer shell (for lavat lockscreen) |
| greetd + tuigreet | display manager + tui greeter |
| polkit | privilege escalation helper |
| xdg-desktop-portal-wlr | wayland portal (screenshare, file dialogs) |
| xdg-desktop-portal-gtk | gtk file chooser portal |
| dconf | gsettings backend |
| gvfs | virtual filesystem (trash, mtp, sftp in nautilus) |

### shell & prompt

| package | what |
| --- | --- |
| zsh | shell |
| starship | prompt |
| zinit | plugin manager |
| zsh-vi-mode | vi mode for zsh |
| zsh-completions | extra completions |
| fzf-tab | fzf-powered tab completion |
| zsh-history-substring-search | search history by substring |
| zsh-autopair | auto-close brackets/quotes |
| zoxide | smarter `cd` (`z`) |

### terminal & editor

| package | what |
| --- | --- |
| ghostty | terminal emulator |
| neovim | editor |
| lazyvim | neovim distribution (the nvim/ config) |
| tree-sitter | parsing for neovim syntax |
| ripgrep | grep replacement (used by nvim/telescope) |
| fd | find replacement |
| fzf | fuzzy finder |
| bat | cat with syntax highlighting |
| eza | ls replacement (`ls` alias) |
| dust | du replacement |
| glow | markdown viewer in terminal |
| hexyl | hex viewer |
| xxd | hex dump |
| tldr | simplified man pages (`wtf` alias) |
| jq | json processor |
| lazygit | git tui |

### file management & archives

| package | what |
| --- | --- |
| superfile | tui file manager (`spf` alias) |
| nautilus | gnome file manager (gui) |
| unzip / zip / p7zip / unrar / xz | archive handlers |

### development

| package | what |
| --- | --- |
| gcc | c compiler |
| gnumake | build tool |
| cmake | build system |
| gdb | debugger |
| python3 | language + scripts (whisper-dict daemon is python) |
| nodejs | js runtime |
| bun | js runtime/toolchain |
| nmap | network scanner |
| claude-code | ai coding agent |
| github-cli | `gh` |
| git | vcs |

### nix tooling (arch: drop these)

| package | what |
| --- | --- |
| nh | nixos rebuild helper (`rb` alias) |
| nix-output-monitor | pretty build output |
| nvd | nix version diff |
| nix-tree | explore nix store |
| nixfmt | nix formatter |
| statix | nix linter |
| deadnix | find dead nix code |
| nixd | nix lsp |
| nix-search-tv | search nixpkgs in a tui |
| nix-init | generate nix derivations |

### media — playback

| package | what |
| --- | --- |
| mpv | video player |
| imv | image viewer |
| zathura | pdf/epub viewer |
| spotify-player | tui spotify client (`spt` alias) |
| playerctl | mpris media control |

### media — creation & capture

| package | what |
| --- | --- |
| obs-studio | screen recorder / streaming |
| wf-recorder | wayland screen recorder |
| grim | wayland screenshots |
| slurp | region selector (pairs with grim) |
| ani-cli | anime streaming in the terminal |

### media — audio system

| package | what |
| --- | --- |
| pipewire | audio/video server |
| wireplumber | pipewire session manager |
| pwvucontrol | pipewire volume control |
| pulseaudio (pipewire pulse) | pulse compat layer |
| rtkit | realtime thread priority for audio |

### dictation (speech-to-text)

custom overlay. hold `Mod+D` to record, release to transcribe via
whisper.cpp, typed into the focused window with wtype.

| package | what |
| --- | --- |
| whisper-cpp | speech-to-text engine |
| whisper-dict-daemon | evdev hold-to-talk daemon (primary) |
| whisper-dict | toggle fallback script |
| whisper-dict-mode-en | switch daemon to english (base.en model) |
| whisper-dict-mode-zh | switch daemon to multilingual (small model) |
| wtype | wayland keyboard input (types transcript) |
| opencc | simplified→traditional chinese conversion |

### gui apps

| package | what |
| --- | --- |
| firefox | browser |
| helium-browser | minimal browser (flake) |
| obsidian | notes |
| anki | flashcards |
| bitwarden-desktop | password manager (gui) |
| bitwarden-cli | password manager (cli, `bw`) |
| beeper | unified chat client |
| vicinae | dashboard/widget shell |

### system & networking

| package | what |
| --- | --- |
| networkmanager | network management |
| tailscale | mesh vpn (`ts`, `tsip`, `tsping` aliases) |
| bluetooth | bt stack |
| upower | power management |
| flatpak | sandboxed app distribution |
| ydotool / ydotoold | virtual keyboard/mouse (uinput) |
| sbctl | secure boot key manager |
| wireshark | packet analyzer |

### theming & decoration

| package | what |
| --- | --- |
| catppuccin-mocha (gtk) | gtk theme |
| papirus-dark | icon theme |
| bibata-cursors | cursor theme (`Bibata-Modern-Classic`, size 24) |
| nerd-fonts jetbrains-mono | terminal font |
| noto-fonts + cjk + emoji | fallback fonts |
| nwg-look | gtk theme/icon picker (gui) |
| qt6ct | qt6 appearance config |
| glib | for `gsettings` |

### fun / eye candy

| package | what |
| --- | --- |
| fastfetch | system info (`ff` alias) |
| anifetch | animated system info (video in terminal, `af` alias) |
| btop | system monitor |
| cmatrix | matrix rain |
| tty-clock | terminal clock |
| lavat | lava lamp in terminal (also used on the lockscreen) |
| golazo | live football scores in terminal |

### task management

| package | what |
| --- | --- |
| tuxedo | keyboard-driven tui for todo.txt (custom nix package) |

### productivity

| package | what |
| --- | --- |
| wl-clipboard | `wl-copy` / `wl-paste` clipboard |
| libnotify | `notify-send` desktop notifications |
| brightnessctl | screen brightness |
| curl / wget | http clients |
| speedtest-cli | bandwidth test |

## by importance

### essential — can't work without

zsh, starship, zinit, neovim, lazyvim, git, github-cli, ghostty, niri,
noctalia, quickshell, ripgrep, fd, fzf, bat, eza, zoxide,
wl-clipboard, pipewire, networkmanager

### daily — used every day

superfile, lazygit, btop, fastfetch, firefox, obsidian, bitwarden
(desktop + cli), spotify-player, mpv, glow, tldr, jq, bun, nodejs,
tailscale, tuxedo, herdr, claude-code

### occasional — when needed

unzip, zip, p7zip, unrar, xz, hexyl, xxd, dust, ani-cli, obs-studio,
wf-recorder, grim, slurp, zathura, imv, pwvucontrol, playerctl,
brightnessctl, nmap, wireshark, gdb, cmake, gcc, gnumake, python3,
beeper, anki, helium-browser, vicinae, speedtest-cli, nautilus

### niche — rarely / for fun

cmatrix, tty-clock, lavat, golazo, anifetch, tree-sitter (as standalone)

### nix-only — drop on arch

nh, nix-output-monitor, nvd, nix-tree, nixfmt, statix, deadnix, nixd,
nix-search-tv, nix-init

## by layer in the stack

```
┌─────────────────────────────────────────────┐
│  apps        firefox, obsidian, mpv, anki …  │
├─────────────────────────────────────────────┤
│  shell gui   noctalia (bar/launcher/notif)   │
├─────────────────────────────────────────────┤
│  compositor  niri (wayland, scrolling-tiling)│
├─────────────────────────────────────────────┤
│  display mgr greetd + tuigreet               │
├─────────────────────────────────────────────┤
│  portals     xdg-desktop-portal-wlr / gtk    │
│             xwayland-satellite, polkit       │
├─────────────────────────────────────────────┤
│  audio       pipewire + wireplumber          │
├─────────────────────────────────────────────┤
│  input       ydotool daemon, evdev (dict)    │
├─────────────────────────────────────────────┤
│  net         networkmanager, tailscale, bt   │
├─────────────────────────────────────────────┤
│  boot        limine + secure boot (sbctl)    │
├─────────────────────────────────────────────┤
│  kernel      linux + nvidia driver           │
└─────────────────────────────────────────────┘
```

## hardware

| | |
| --- | --- |
| cpu | ryzen 7 6800hs (8c/16t) |
| gpu | nvidia (prime offload) + amdgpu (hybrid) |
| nvidia bus | `PCI:1:0:0` |
| amdgpu bus | `PCI:6:0:0` |
| driver | nvidia stable, modesetting + finegrained power mgmt |

## services (systemd)

| service | what |
| --- | --- |
| `tailscaled` | tailscale mesh vpn |
| `NetworkManager` | networking |
| `pipewire` / `wireplumber` | audio |
| `bluetoothd` | bluetooth |
| `greetd` | display manager |
| `ydotool` (user) | virtual input daemon |
| `whisper-dict-daemon` (user) | hold-to-talk dictation |
| `swayidle` (user) | idle lock + monitor power-off |

## locale

| | |
| --- | --- |
| timezone | `Europe/London` |
| default locale | `en_HK.UTF-8` |
| everything else | `en_GB.UTF-8` |
| keyboard | `us` |
