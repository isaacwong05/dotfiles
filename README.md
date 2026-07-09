# dotfiles

my personal config for nixos.

## overview

a [niri](https://github.com/YaLTeR/niri) scrolling-tiling wayland setup on nixos, themed around a minimal monochrome look.

## contents

| path       | description                                              |
| ---------- | -------------------------------------------------------- |
| `nixos/`   | nixos system config (flake, configuration.nix, home.nix) |
| `niri/`    | niri compositor config, keybinds, and scripts            |
| `ghostty/` | ghostty terminal config                                  |
| `nvim/`    | neovim config (lazyvim-based)                            |
| `.zshrc`   | zsh config (zinit, starship, zoxide)                     |

## stack

- **os:** nixos (flake-based, with home-manager)
- **compositor:** niri
- **shell (desktop):** noctalia (quickshell)
- **terminal:** ghostty
- **editor:** neovim / lazyvim
- **shell:** zsh + starship + zinit
- **bootloader:** limine
- **login:** greetd + tuigreet

## usage

clone and symlink the bits you want into `~/.config` (so edits in the repo go live automatically and can't drift):

```bash
git clone git@github.com:isaacwong05/dotfiles.git ~/git/dotfiles
ln -s ~/git/dotfiles/niri    ~/.config/niri
ln -s ~/git/dotfiles/ghostty ~/.config/ghostty
ln -s ~/git/dotfiles/nvim    ~/.config/nvim
ln -s ~/git/dotfiles/.zshrc  ~/.zshrc
```

for the nixos config, point your rebuild at the flake:

```bash
nh os switch ~/git/dotfiles/nixos   # or: sudo nixos-rebuild switch --flake ~/git/dotfiles/nixos#nixos
```
