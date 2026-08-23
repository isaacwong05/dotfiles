# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal NixOS dotfiles for a niri/Wayland desktop. All configs are symlinked from `~/git/dotfiles` into `~/.config`, so edits here go live immediately.

## Applying changes

```bash
rb           # nh os switch ~/git/dotfiles/nixos  — rebuild & switch NixOS config
nixup        # nix flake update + rebuild + optional git push
checkup      # health check (disk, generations, failed units); --clean to gc
```

The flake hostname is `nixos` (`nixosConfigurations.nixos` in `flake.nix`). The flake lives at `~/git/dotfiles/nixos/`.

## Repository structure

| path                                  | what it is                                                                               |
| ------------------------------------- | ---------------------------------------------------------------------------------------- |
| `nixos/flake.nix`                     | Flake inputs and the single `nixosConfigurations.nixos` output                           |
| `nixos/configuration.nix`             | System config: boot (limine), hardware (NVIDIA prime offload), packages, services, users |
| `nixos/home.nix`                      | home-manager config: idle/lockscreen (swayidle + swaylock-plugin), GTK theme, cursor     |
| `nixos/overlays/whisper-dict.nix`     | Custom packages: `whisper-dict`, `whisper-dict-daemon`, mode-switch scripts, ggml models |
| `nixos/overlays/lockscreen-tools.nix` | Custom builds of `windowtolayer` and `lavat` from flake non-flake sources                |
| `nixos/packages/tuxedo.nix`           | Tuxedo keyboard driver package                                                           |
| `nixos/scripts/`                      | `update.sh` (nixup) and `checkup.sh` shell scripts                                       |
| `niri/config.kdl`                     | Niri compositor config: keybinds, layout, output, window rules                           |
| `niri/scripts/`                       | Helper scripts called from niri keybinds                                                 |
| `ghostty/config`                      | Ghostty terminal config                                                                  |
| `nvim/`                               | Neovim config (LazyVim-based)                                                            |
| `.zshrc`                              | Zsh config: zinit plugins, aliases, starship, zoxide                                     |

## Nix patterns used here

- **Flake-based** (`nix-command` + `flakes` experimental features enabled).
- **home-manager** runs as a NixOS module (`home-manager.nixosModules.home-manager`), not standalone.
- **Overlays** are applied in `flake.nix` via `nixpkgs.overlays`; `lockscreen-tools.nix` takes `{ inputs }` so it can reference non-flake sources (`windowtolayer-src`, `lavat-src`).
- **`specialArgs`** passes flake inputs into `configuration.nix` so packages like `noctalia`, `herdr`, etc. are available as function arguments.
- Nix formatter: `nixfmt`. Linting: `statix` (lint), `deadnix` (unused bindings).

## Whisper dictation system

Hold-to-talk via `Mod+D` (niri keybind). The evdev daemon (`whisper-dict-daemon`) reads raw `/dev/input` events so it sees key release (unlike niri binds). It runs as a systemd user service started with `graphical-session.target`. The daemon Python source is `overlays/whisper-dict-daemon.py` with `@placeholder@` tokens substituted at build time with Nix store paths.

Switch language modes at runtime (no rebuild):

```bash
dten   # whisper-dict-mode-en — base.en model, English only, fast
dtzh   # whisper-dict-mode-zh — small model, auto-detect, traditional Chinese via opencc
```

## Key aliases

```bash
rb        # nixos-rebuild (nh os switch)
nixedit   # edit configuration.nix
nixflake  # edit flake.nix
nixup     # update flake + rebuild
checkup   # system health check
```
