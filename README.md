# dotfiles

personal configuration for my arch linux laptop running hyprland 🥀

the repo lives in `~/dotfiles`; most application configurations are
symlinked into `~/.config`.

the active configuration is:

| component           | software                                                  |
| ------------------- | --------------------------------------------------------- |
| os                  | arch linux                                                |
| compositor          | hyprland with a modular lua configuration                 |
| desktop shell       | quickshell                                                |
| dynamic island      | tide island, installed as an arch package                 |
| launcher and search | walker and elephant                                       |
| terminal            | ghostty                                                   |
| editor              | neovim / lazyvim                                          |
| shell               | zsh + starship + zinit + zoxide                           |
| audio               | pipewire + wireplumber                                    |
| screensaver         | omarchy-like/lavat scripts with a quickshell idle service |
| dictation           | dusky stt user service                                    |

## repository layout

| path           | description                                                        |
| -------------- | ------------------------------------------------------------------ |
| `hypr/`        | hyprland lua configuration, keybinds, rules, monitors, and scripts |
| `quickshell/`  | notifications, power menu, and idle screensaver qml                |
| `config/`      | portable application configuration and user systemd units          |
| `ghostty/`     | ghostty terminal configuration                                     |
| `nvim/`        | neovim/lazyvim configuration                                       |
| `scripts/`     | arch maintenance, snapshot, and helper scripts                     |
| `.zshrc`       | zsh configuration, aliases, plugins, and environment               |
| `etc-staging/` | files intended to be copied manually into `/etc`                   |

## applying changes

```bash
# reload hyprland
hyprctl reload

# reload user service definitions
systemctl --user daemon-reload

# restart the notification shell after changing its qml
systemctl --user restart notifications.service
```

useful checks:

```bash
systemctl --user --failed
systemctl --user status notifications.service omarchy-screensaver-idle.service tide-island.service
hyprctl monitors
hyprctl clients
```

## tracked user services

- `notifications.service`: quickshell notification daemon and notification center
- `omarchy-screensaver-idle.service`: idle screensaver shell
- `arch-maintenance-report.service` / `.timer`: weekly arch maintenance report

other services, including tide island, elephant, dusky stt, and wallpaper
daemons, are installed or configured outside this repository.

## system snapshots

```bash
sudo pacman -s timeshift
system-snapshot setup
sudo timeshift-gtk
system-snapshot create
```

## credits and licenses

this repository mixes personal configuration with adapted third-party code.
`LICENSE` covers my original work only. third-party code, themes, and assets
keep their upstream licenses and attribution.

| source                                                                    | used here                                                                                                                                           | license          |
| ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------- |
| [omarchy](https://github.com/omacom/omarchy)                              | screensaver launcher and effects adapted under `hypr/scripts/`, i pretty much yoinked the screensavers because i thought it looked cool. sorry DHH. | MIT              |
| [lavat](https://github.com/AngelJumbo/lavat)                              | terminal screensaver launched by the omarchy/lavat wrappers                                                                                         | MIT              |
| [tide island](https://github.com/enhaoswen/Tide-island)                   | `quickshell/tide-island/qml/island/TrayPanelLayer.qml` and ipc integration                                                                          | GPL-3.0-only     |
| [cava](https://github.com/karlstav/cava)                                  | `config/cava/` configuration and shader examples                                                                                                    | MIT              |
| [eye of phi](https://www.shadertoy.com/view/7stfzB) by chunderfpv         | adapted as `config/cava/shaders/eye_of_phi.frag`                                                                                                    | upstream terms   |
| [lazyvim](https://github.com/LazyVim/LazyVim)                             | base for the `nvim/` configuration                                                                                                                  | Apache-2.0       |
| [superfile](https://github.com/yorukot/superfile)                         | bundled themes and configuration format                                                                                                             | MIT              |
| [quickshell](https://git.outfoxxed.me/quickshell/quickshell)              | qml runtime and api used by the desktop shell                                                                                                       | LGPL-3.0-only    |
| [sonora](https://github.com/sonorahq/sonora)                              | app launched by `hypr/scripts/sonora-scratch`                                                                                                       | GPL-3.0-or-later |
| [tailtui](https://github.com/Phundahl/tailtui)                            | launcher, scratchpad integration, and `config/tailtui/`                                                                                             | MIT              |
| [hyprscratch](https://github.com/sashetophizika/hyprscratch)              | scratchpad launcher and window rules                                                                                                                | MIT              |
| [hyprmoncfg](https://github.com/crmne/hyprmoncfg)                         | generated monitor rules in `hypr/`                                                                                                                  | MIT              |
| [openwhispr](https://github.com/OpenWhispr/openwhispr)                    | hotkey integration in `hypr/openwhispr-binds.lua`                                                                                                   | MIT              |
| [tuxedo](https://github.com/webstonehq/tuxedo)                            | `config/tuxedo/` and keyboard. such a goated todolist bindings                                                                                      | MIT              |
| [terminaltexteffects](https://github.com/ChrisBuilds/terminaltexteffects) | terminal effects used by the screensaver scripts                                                                                                    | MIT              |
| [anifetch](https://github.com/Notenlish/anifetch)                         | animated fetch command used by `.zshrc` and `scripts/ orb` for larping                                                                              | MIT              |
| [awww](https://codeberg.org/LGFae/awww)                                   | animated wallpaper daemon started by `hypr/conf/startup.lua`                                                                                        | GPL-3.0-or-later |
