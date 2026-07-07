# dotfiles

Personal configuration files for my NixOS setup.

## Overview

A [niri](https://github.com/YaLTeR/niri) scrolling-tiling Wayland setup on NixOS, themed around a minimal monochrome aesthetic.

## Contents

| Path       | Description                                       |
| ---------- | ------------------------------------------------- |
| `niri/`    | niri compositor config, keybinds, and scripts     |
| `ghostty/` | Ghostty terminal configuration                    |
| `nvim/`    | Neovim config (LazyVim-based)                     |
| `.zshrc`   | Zsh shell configuration (zinit, starship, zoxide) |

## Stack

- **OS:** NixOS (flake-based, with Home Manager)
- **Compositor:** niri
- **Shell (desktop):** Noctalia (Quickshell)
- **Terminal:** Ghostty
- **Editor:** Neovim / LazyVim
- **Shell:** Zsh + Starship + zinit
- **Bootloader:** Limine
- **Login:** greetd + tuigreet

## Notes

The full system configuration (packages, services, hardware) lives in my NixOS flake, not this repo — these are the user-level config files that sit in `~/.config`.

## Usage

Clone and symlink (or copy) the relevant directories into `~/.config`:

```bash
git clone git@github.com:isaacwong05/dotfiles.git
cp -r dotfiles/niri ~/.config/
cp -r dotfiles/ghostty ~/.config/
cp -r dotfiles/nvim ~/.config/
cp dotfiles/.zshrc ~/
```
