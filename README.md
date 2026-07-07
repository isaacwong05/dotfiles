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

clone and copy the bits you want into `~/.config`:

```bash
git clone git@github.com:isaacwong05/dotfiles.git
cp -r dotfiles/niri ~/.config/
cp -r dotfiles/ghostty ~/.config/
cp -r dotfiles/nvim ~/.config/
cp dotfiles/.zshrc ~/
```

for the nixos config, point your rebuild at the flake:

```bash
sudo nixos-rebuild switch --flake ./dotfiles/nixos#nixos
```
