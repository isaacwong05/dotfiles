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
| `ghostty/config.ghostty` | (alternate/legacy — likely unused; `config` is the live one) | ghostty k/v |
| `ghostty/themes/noctalia` | Custom theme | — |
| `nvim/` | LazyVim config; symlinked to `~/.config/nvim` | Lua |
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

## Branch workflow

`main` is the only long-lived branch: the stable, always-works baseline.
Everything else is a short-lived per-idea branch.

### Flow

1. **Start something new** from `main`:
   ```bash
   git checkout main
   git checkout -b feature/my-new-idea
   ```
   Name branches `feature/<short-description>` (for adding things) or
   `refactor/<short-description>` (for restructuring without behavior change).
2. **Work, break things, commit frequently** on that branch. Frequent messy commits
   are fine — they'll be squashed away.
3. **Validate before merging** — run the relevant check from "Validation commands"
   above (`niri validate`, `zsh -n`, `nh os test`, etc.) until the branch works.
4. **Squash-merge back to `main`** as one clean commit:
   ```bash
   git checkout main
   git merge --squash feature/my-new-idea
   git commit -m "add my new idea"
   git branch -d feature/my-new-idea
   ```
5. The squashed commit message follows the **Git commit style** below — lowercase,
   terse, comma/`+`-separated, no prefix.

### Rules

- **Only `main` is long-lived.** Don't keep `feature`/`refactor` branches around
  after the work is merged — delete them.
- **Branch off `main`, never off another feature branch** unless explicitly stacking
  dependent work.
- **Switching branches changes the live system.** Because `~/.config/{nvim,niri,ghostty}`
  and `~/.zshrc` are symlinks into this repo, `git checkout feature/...` instantly
  changes the running config. Useful for real-world testing, but a half-finished
  branch can leave the shell/editor/compositor in a broken state. Warn the user before
  switching to untested work, and `git checkout main` to restore a known-good config.
- **Validate before the squash merge** — never merge a broken branch into `main`.
- **Don't force-push `main`** and don't rewrite shared history without confirmation.

### Typical session

```bash
git checkout main
git checkout -b feature/telescope-fzf   # start new idea
# ... edit nvim/lua/plugins/telescope-fzf.lua, run nvim --headless "+Lazy! sync" +qa ...
git commit -m "wip: telescope-fzf spec"    # messy, fine
git commit -m "fix: opts path"            # messy, fine
# ... validated and working ...
git checkout main
git merge --squash feature/telescope-fzf
git commit -m "add telescope-fzf-native plugin"
git branch -d feature/telescope-fzf
```

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
