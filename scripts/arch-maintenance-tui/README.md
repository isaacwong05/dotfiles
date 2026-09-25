# Arch maintenance TUI

Build and run from the repository root:

```sh
go build -o ~/.local/bin/arch-maintenance-tui ./scripts/arch-maintenance-tui
arch-maintenance-tui
```

The TUI starts with read-only checks. Actions require confirmation and stream
stdout/stderr into the Activity panel:

- `Tab` / `h` / `l`: switch panels
- `1`–`5`: jump to a panel
- `j` / `k`: move or scroll
- `Space`: select an orphan package
- `a` / `n`: select all / none on Orphans
- `d`: remove selected orphan packages
- `u`: update official packages
- `a`: update AUR packages on the Updates panel
- `c`: clean the package cache from Dashboard or Activity
- `r`: refresh checks
- `q`: quit

The weekly systemd timer remains report-only because it has no interactive
terminal. Use the TUI manually for updates and package removal.
