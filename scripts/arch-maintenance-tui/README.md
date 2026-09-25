# arch maintenance tui

build and run from the repository root:

```sh
go build -o ~/.local/bin/arch-maintenance-tui ./scripts/arch-maintenance-tui
arch-maintenance-tui
```

the tui starts with read-only checks. actions require confirmation and stream
stdout/stderr into the activity panel:

- `Tab` / `h` / `l`: switch panels
- `1`–`5`: jump to a panel
- `j` / `k`: move or scroll
- `Space`: select an orphan package
- `a` / `n`: select all / none on orphans
- `d`: remove selected orphan packages
- `u`: update official packages
- `a`: update aur packages on the updates panel
- `c`: clean the package cache from dashboard or activity
- `r`: refresh checks
- `q`: quit

the weekly systemd timer remains report-only because it has no interactive
terminal. use the tui manually for updates and package removal.
