# Dotfiles — ~/git/dotfiles

Isaac's personal NixOS + niri + LazyVim + zsh + ghostty dotfiles. Repo on GitHub:
`git@github.com:isaacwong05/dotfiles.git`.

## Layout

| Path | What | Format |
|------|------|--------|
| `nixos/flake.nix` | System flake (nixpkgs-26.05, home-manager, noctalia, quickshell, helium-browser, whisper-dictation, anifetch) | Nix |
| `nixos/configuration.nix` | System config (limine bootloader, greetd/tuigreet, kernel, etc.) | Nix |
| `nixos/home.nix` | home-manager config for user `isaac` (gtk, cursor, packages) | Nix |
| `nixos/hardware-configuration.nix` | Hardware config — edit with care | Nix |
| `nixos/packages/*.nix` | Custom/local packages (e.g. `tuxedo.nix`) | Nix |
| `niri/config.kdl` | Main niri compositor config | KDL |
| `niri/noctalia.kdl` | Noctalia shell config | KDL |
| `niri/scripts/` | niri-bound shell scripts | shell |
| `ghostty/config` | Ghostty terminal config | ghostty k/v |
| `ghostty/config.ghostty` | (alternate/legacy — confirm which is live before editing) | ghostty k/v |
| `ghostty/themes/noctalia` | Custom theme | — |
| `nvim/` | LazyVim config; deployed by copy to `~/.config/nvim` | Lua |
| `nvim/lua/plugins/*.lua` | lazy.nvim plugin specs (one file per plugin/area) | Lua |
| `nvim/lua/config/{autocmds,keymaps,lazy,options}.lua` | LazyVim core overrides | Lua |
| `.zshrc` | zsh config (zinit, starship, zoxide, aliases) | shell |

## Deployment

The repo is deployed via **symlinks** (see `README.md`), so the repo IS the live
config — no copy step, no drift:

```
~/.zshrc            -> ~/git/dotfiles/.zshrc
~/.config/nvim      -> ~/git/dotfiles/nvim
~/.config/niri      -> ~/git/dotfiles/niri
~/.config/ghostty   -> ~/git/dotfiles/ghostty
```

Therefore: **edit the repo files directly** — changes go live immediately. No diffing
against a live copy, no re-copying needed.

- nvim: `lazy-lock.json` and `.neoconf.json` are gitignored (runtime-generated).
- niri hot-reloads `config.kdl` on save; run `niri validate` after structural edits.
- zsh: `zsh -n ~/.zshrc` to syntax-check; `exec zsh` to reload.

Nix files are the source of truth too — edit the repo, then rebuild. Never edit
`/etc/nixos/` or anything under `/run/current-system/`.

## Validation commands

- **NixOS:** `nh os test ~/git/dotfiles/nixos` (build + activate without switching
  generations — safe dry run) or `nh os switch ~/git/dotfiles/nixos` (alias `rb`).
  `nix flake check` for flake-level checks. `nix fmt` to format.
- **niri:** `niri validate` to check `config.kdl` syntax. niri hot-reloads config on
  save; no restart needed for most changes.
- **nvim (LazyVim):** `nvim --headless "+Lazy! sync" +qa` to install/update plugins
  after editing specs. `nvim --headless "+checkhealth" +qa` for a health check.
- **zsh:** `zsh -n ~/.zshrc` for syntax check; `exec zsh` to reload.

## Conventions

- Nix: follow existing style (2-space indent, `lib.mkForce` where overrides are
  intentional, keep `specialArgs`/`inputs` in sync with `flake.nix`).
- When adding a flake input, update both `inputs` and `specialArgs`/module references.
- LazyVim plugins: one spec per file under `nvim/lua/plugins/`, prefer `lazy = true`
  unless startup load is required, include keymaps in the spec via `keys = {}`.
- Keep the monochrome/minimal aesthetic; don't introduce color themes unasked.
- Commit with clear messages; the repo is public on GitHub.

## Git commit style

Match the existing history (`git log --oneline`). Conventions:

- All lowercase.
- No conventional-commit prefix (no `feat:`, `fix:`, etc.).
- Terse, comma- and `+`-separated list of what changed.
- No body unless something genuinely needs explaining.
- One logical change per commit when feasible; batch tightly-related edits.

Examples from this repo:

```
sync nixos config, add tuxedo + anifetch
update readme
add nixos configs
added a readme
Initial dotfiles
```

So a typical commit message looks like:

```
switch to symlinks, sync zshrc + niri config, add nvim gitignore
```

## Don't

- Don't run `sudo` rebuilds without telling me first — prefer `nh os test` then
  `nh os switch` (alias `rb`).
- Don't edit `hardware-configuration.nix` unless I ask.
- Don't bump `nixpkgs` or other flake input branches without confirmation.
