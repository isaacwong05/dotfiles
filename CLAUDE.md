# CLAUDE.md

This file provides guidance to coding agents working in this repository.

## What this repo is

Personal dotfiles for an Arch Linux laptop running Hyprland on Wayland. The
active Hyprland configuration is Lua-based and lives in `hypr/`; most app
configs are symlinked from this repository into `~/.config`.

Do not add NixOS, Niri, or Noctalia configuration here. They are no longer
part of the active setup.

## Applying changes

```bash
# Reload the active compositor configuration
hyprctl reload

# Reload changed user units
systemctl --user daemon-reload
systemctl --user restart notifications.service
```

The repository is at `~/dotfiles`. Changes to symlinked configs are live
immediately; restart the relevant application or user service when needed.

## Repository structure

| path | what it is |
| --- | --- |
| `hypr/` | Hyprland Lua config, monitor layout, keybinds, rules, and scripts |
| `quickshell/` | Power menu, notifications, and idle screensaver QML |
| `config/systemd/user/` | User units maintained by this repository |
| `ghostty/` | Ghostty terminal config |
| `nvim/` | Neovim/LazyVim config |
| `config/` | Portable application configs |
| `scripts/` | Arch maintenance, snapshots, screenshots, and helper scripts |
| `.zshrc` | Zsh, zinit, Starship, zoxide, and local aliases |
| `etc-staging/` | Files intended for `/etc`, copied manually with care |

Tide Island is installed as an Arch package and runs from
`/usr/share/tide-island`; its old vendored source is not part of this repo.

## Active desktop stack

- Arch Linux
- Hyprland + `hyprmoncfg`
- Quickshell notifications and power menu
- Tide Island
- Walker and Elephant for launching/search
- Ghostty
- Neovim/LazyVim
- Zsh + Starship + zinit
- PipeWire/WirePlumber
- Omarchy/lavat screensaver scripts
- Dusky STT user service

## Useful checks

```bash
systemctl --user --failed
systemctl --user status notifications.service omarchy-screensaver-idle.service tide-island.service
hyprctl monitors
hyprctl clients
```

Keep secrets, runtime state, logs, caches, and generated files out of commits.
