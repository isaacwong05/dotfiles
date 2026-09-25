# claude.md

this file provides guidance to coding agents working in this repository.

## what this repo is

personal dotfiles for an arch linux laptop running hyprland on wayland. the
active hyprland configuration is lua-based and lives in `hypr/`; most app
configs are symlinked from this repository into `~/.config`.

do not add nixos, niri, or noctalia configuration here. they are no longer
part of the active setup.

## applying changes

```bash
# reload the active compositor configuration
hyprctl reload

# reload changed user units
systemctl --user daemon-reload
systemctl --user restart notifications.service
```

the repository is at `~/dotfiles`. changes to symlinked configs are live
immediately; restart the relevant application or user service when needed.

## repository structure

| path | what it is |
| --- | --- |
| `hypr/` | hyprland lua config, monitor layout, keybinds, rules, and scripts |
| `quickshell/` | power menu, notifications, and idle screensaver qml |
| `config/systemd/user/` | user units maintained by this repository |
| `ghostty/` | ghostty terminal config |
| `nvim/` | neovim/lazyvim config |
| `config/` | portable application configs |
| `scripts/` | arch maintenance, snapshots, screenshots, and helper scripts |
| `.zshrc` | zsh, zinit, starship, zoxide, and local aliases |
| `etc-staging/` | files intended for `/etc`, copied manually with care |

tide island is installed as an arch package and runs from
`/usr/share/tide-island`; its old vendored source is not part of this repo.

## active desktop stack

- arch linux
- hyprland + `hyprmoncfg`
- quickshell notifications and power menu
- tide island
- walker and elephant for launching/search
- ghostty
- neovim/lazyvim
- zsh + starship + zinit
- pipewire/wireplumber
- omarchy/lavat screensaver scripts
- dusky stt user service

## useful checks

```bash
systemctl --user --failed
systemctl --user status notifications.service omarchy-screensaver-idle.service tide-island.service
hyprctl monitors
hyprctl clients
```

keep secrets, runtime state, logs, caches, and generated files out of commits.
