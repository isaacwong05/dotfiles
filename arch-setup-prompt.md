# arch setup prompt

paste this into an agent (pi / claude code / etc.) on a **fresh arch install**
with `paru` already installed and a working network. it assumes the dotfiles
repo exists at `github.com:isaacwong05/dotfiles.git`.

---

## prompt

i just installed arch linux (base system, paru for AUR, zsh not yet set as
default shell). i have a dotfiles repo that tracks all my configs and a full
inventory of what was installed on my previous nixos setup.

**read these first, in order, before doing anything:**

1. `~/git/dotfiles/README.md` — the full installed-software index organized
   by role, importance, and stack layer. this is your shopping list.
2. `~/git/dotfiles/nixos-archive/configuration.nix` — the old system config.
   use it to recover exact service settings, env vars, bus ids, locale, and
   anything the README summarizes. **do not run nix.** it's reference only.
3. `~/git/dotfiles/nixos-archive/home.nix` — gtk theme, cursor, swayidle
   timeouts, lockscreen command.
4. `~/git/dotfiles/niri/config.kdl` — compositor config + keybinds to copy in.
5. `~/git/dotfiles/.zshrc` — shell config. **strip the nixos aliases**
   (`rb`, `nixedit`, `nixflake`, `nixup`, `checkup`, the `af` anifetch alias
   pointing at `~/nixos-logo.mp4`). replace `rb`/`nixup`/`checkup` with
   paru/pacman equivalents or just drop them. keep everything else.

**skip entirely — do not install:**

- noctalia shell (bar/launcher/notifications). i'm writing my own quickshell
  panel instead. so: no `noctalia` package, no noctalia config, no noctalia
  widget references. leave a placeholder for "my own quickshell" and move on.
- everything in the README's "nix tooling" and "nix-only — drop on arch"
  sections (nh, nvd, nix-tree, nixfmt, statix, deadnix, nixd, nix-search-tv,
  nix-init, nix-output-monitor). these are nix-only.
- the nixos-archive/ dir — it's reference material, nothing to install from it.

**do this, in order:**

### 1. clone the repo
```bash
git clone git@github.com:isaacwong05/dotfiles.git ~/git/dotfiles
```

### 2. base packages (pacman + paru)
work through the README "by importance" section top-down. install the
**essential** and **daily** tiers first, then **occasional**. use pacman for
repo packages, paru for AUR-only. group the installs into a few `paru -S --needed`
calls rather than one giant line, and tell me what's AUR-only vs official.

packages i know are AUR or flake-only and need attention:
- `claude-code`, `herdr`, `helium-browser`, `vicinae`, `anifetch`, `wlctl`,
  `tuxedo`, `golazo`, `ani-cli` — check AUR first; if not packaged, flag it
  and i'll decide whether to skip or build from source.
- `spotify-player` — AUR has it. the nixos config pinned v0.24.1 because
  0.23.0 had a token bug; make sure the AUR pkg is >= 0.24.1.
- `whisper-cpp` — AUR. the dictation stack depends on it.

### 3. shell
- set zsh as my default shell: `chsh -s $(which zsh)`.
- symlink `.zshrc`: `ln -sf ~/git/dotfiles/.zshrc ~/.zshrc` (after you've
  de-nixified the aliases in the repo copy — edit the repo file directly).
- zinit plugins install on first zsh launch, no manual step needed.
- starship: `paru -S starship` (the .zshrc calls `starship init zsh`).
- zoxide: enable zsh integration is already in .zshrc via the `z` alias; just
  install the package.

### 4. configs — symlink the hand-edited ones, copy the rest
```bash
ln -sf ~/git/dotfiles/niri     ~/.config/niri
ln -sf ~/git/dotfiles/ghostty  ~/.config/ghostty
ln -sf ~/git/dotfiles/nvim     ~/.config/nvim
# config/ tree: copy or symlink per-dir, your call — but keep them in the repo
```
the `config/` dir has: btop, cava, fastfetch, gh, git, glow, herdr, lazygit,
niri-screensaver, nixmate, noctalia (SKIP — see above), spotify-player,
starship.toml, superfile, tuxedo, vicinae (SKIP if it depends on noctalia),
xsettingsd, zed, autostart. symlink the ones that are pure config; skip
noctalia entirely.

### 5. bootloader — limine (manual, not a standard arch bootloader)
this is the non-standard part. arch defaults to systemd-boot or grub; i use
[limine](https://limine-bootloader.org/) instead, and this machine **dual-boots
windows 11 25h2**. on nixos a module handled all of this; on arch it's manual.

reference: `nixos-archive/configuration.nix` `boot.loader.limine.*` and
`boot.loader.limine.extraEntries`.

**install:**
- `paru -S limine` (AUR — check it's not flagged out-of-date; if the AUR pkg
  is stale or missing, stop and ask before building from source).
- `efibootmgr` (to manage the UEFI boot entry).

**EFI system partition (ESP):**
- find the ESP: `lsblk -f` and look for the vfat partition mounted at
  `/boot` or `/efi`. if it's not mounted, mount it (typically `/boot` for
  limine). show me the layout before touching it.
- `boot.loader.efi.canTouchEfiVariables = true` was set, so writing EFI vars
  is expected.

**deploy limine to the ESP:**
- run `limine deploy <esp-device>` (e.g. `limine deploy /dev/nvme0n1pX`) to
  install/refresh the limine binary on the ESP. do this after every limine
  package upgrade.
- create the UEFI boot entry pointing at limine's EFI binary via
  `efibootmgr -c -d <disk> -p <part> -L "Limine" -l '\\EFI\\BOOT\\BOOTX64.EFI'`
  (adjust the path to where `limine deploy` put it — check and show me).

**limine.conf** — write to `/boot/limine/limine.conf` (or wherever the ESP
mounts). port these exact settings from the old `extraConfig`:
- `timeout: 5`
- `remember_last_entry: no`
- terminal palette (monochrome white-on-black):
  `term_palette: 0f0f0f;e8e8e8;ffffff;f0f0f0;c8c8c8;e0e0e0;d8d8d8;f5f5f5`
  `term_palette_bright: 1a1a1a;ffffff;ffffff;ffffff;e8e8e8;f5f5f5;eeeeee;ffffff`
  `term_background: 0f0f0f` / `term_foreground: f0f0f0`
  `term_background_bright: 1a1a1a` / `term_foreground_bright: ffffff`
  `interface_branding_colour/interface_help_color: ffffff` (and bright)
- no wallpapers (`maxGenerations` wallpaper list was force-empty).

**arch kernel entries** — nixos auto-managed up to 5 generations; arch has no
generations, so write a static entry pointing at the installed kernel +
initramfs. for the `linux` package on a standard arch layout that's usually:
```
/Arch Linux
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    module_path: boot():/initramfs-linux.img
    cmdline: root=PARTUUID=<root-partuuid> rw
```
- get the root PARTUUID from `blkid` for the root partition — show it to me.
- if i'm on `linux-lts` instead, adjust filenames (`vmlinuz-linux-lts`,
  `initramfs-linux-lts.img`).
- add a fallback entry pointing at `initramfs-linux-fallback.img`.

**windows dual-boot entry** — port exactly from `extraEntries`:
```
/+Other systems and bootloaders
//Windows Boot Manager
    comment: Windows 11 25H2
    protocol: efi_chainload
    image_path: guid(88F3BEF0-F939-4420-97C0-431E89278101):/efi/Microsoft/Boot/bootmgfw.efi
```
that GUID (`88F3BEF0-F939-4420-97C0-431E89278101`) is the windows ESP
partition guid from this machine. verify it still matches with
`blkid` / `lsblk -o +PARTUUID` before relying on it — if the windows install
was reinstalled or partitions changed, the guid differs and the entry won't
boot. show me the current windows ESP guid so i can confirm.

**kernel-update hook** — on nixos the module re-ran limine after each
generation; on arch, kernel updates replace `/boot/vmlinuz-linux` and
`/boot/initramfs-linux.img` in place, so the limine.conf paths stay valid and
no redeploy is needed for kernel bumps. BUT `limine deploy` must re-run after
any `limine` package upgrade (the bootloader binary itself changes). set up a
pacman hook `/etc/pacman.d/hooks/limine.hook` that runs `limine deploy` on
the ESP after the `limine` package upgrades — show me the hook before
installing it.

**secure boot** — nixos had `secureBoot.enable`, `enrollConfig`, and
`panicOnChecksumMismatch`. this is advanced and easy to brick a boot from.
DO NOT touch secure boot until i say so. when i'm ready, the plan is:
- `sbctl` to create + enroll keys into UEFI.
- sign the limine binary with sbctl.
- enroll limine's config hash (limine's own `enrollConfig` equivalent) so
  UEFI verifies both the loader and its config.
- test with `sbctl verify` before rebooting.
for now just install `sbctl` and leave secure boot in its current state
(likely setup mode or off). tell me what state the firmware is in.

### 6. display manager + compositor
- install `greetd` and `tuigreet`. port the exact greetd config from
  `nixos-archive/configuration.nix` (the tuigreet flags, theme string,
  `--cmd niri-session`). write it to `/etc/greetd/config.toml`.
- install `niri`. enable greetd: `systemctl enable greetd`.
- xwayland-satellite: install and autostart it (niri spawns it, or add to
  niri's `spawn-at-startup`).

### 7. audio
- install `pipewire`, `wireplumber`, `pipewire-pulse`, `pipewire-alsa`,
  `pipewire-jack`, `rtkit`, `pwvucontrol`, `playerctl`.
- enable: `systemctl --user enable --now pipewire wireplumber`.

### 8. nvidia hybrid graphics
this machine is ryzen 7 6800hs with nvidia + amdgpu hybrid (prime offload).
from the old config:
- nvidia bus id: `PCI:1:0:0`
- amdgpu bus id: `PCI:6:0:0`
- modesetting + power management + finegrained on, open driver off, stable channel.
install `nvidia`, `nvidia-utils`, `nvidia-prime`, `nvidia-settings` (or the
nvidia-dkms + nvidia-open path — ask me which i want before installing).
set up the prime offload config (env vars + xorg.conf.d snippet or the
wayland equivalent). verify `nvidia-smi` works and `prime-offload` runs.

### 9. networking & system services
- `networkmanager`: install + `systemctl enable --now NetworkManager`.
- `tailscale`: `paru -S tailscale` + `systemctl enable --now tailscaled`.
  set `--operator=isaac` in the tailscaled service so i can up/down without sudo.
- `bluetooth`: `bluez` + `bluez-utils`, `systemctl enable --now bluetooth`.
- `upower`: `systemctl enable --now upower`.
- `polkit`: install `polkit` + a polkit agent (gnome-polkit or similar).
- `flatpak`: install + `flatpak remote-add --if-not-exists flathub`.
- `ydotool`: install `ydotool`, enable the daemon
  (`systemctl enable --now ydotoold`), add me to the `input` group.

### 10. portals
install `xdg-desktop-portal`, `xdg-desktop-portal-gtk`,
`xdg-desktop-portal-wlr`. set the niri default to gtk (see old config).

### 11. theming
from `home.nix`:
- gtk theme: `catppuccin-mocha-standard-blue-dark` (install `catppuccin-gtk-theme`)
- icon theme: `papirus-dark` (`papirus-icon-theme`)
- cursor: `bibata-modern-classic` size 24 (`bibata-cursor-theme`)
- fonts: `nerd-fonts-jetbrains-mono`, `noto-fonts`, `noto-fonts-cjk`,
  `noto-fonts-emoji`.
- `nwg-look` for gtk theme picker, `qt6ct` for qt6 appearance.
apply gtk settings via `gsettings` or `dconf`.

### 12. lockscreen + idle
- `swaylock-plugin`, `swayidle`, `windowtolayer`, `lavat` (AUR/build from
  source for windowtolayer — check AUR first).
- swayidle config from `home.nix`: lock at 5m with
  `swaylock-plugin --command-each 'windowtolayer ghostty -e lavat -g -c FFFFFF -G'`,
  power-off monitors at 10m, lock before-sleep.
- start swayidle as a user service or from niri's `spawn-at-startup`.

### 13. dictation (whisper-cpp push-to-talk) — port manually
this is the one custom thing. the nixos overlay built:
- `whisper-dict-daemon` — a python evdev hold-to-talk daemon
- `whisper-dict` — a toggle fallback shell script
- `whisper-dict-mode-en` / `whisper-dict-mode-zh` — env-switch scripts
source is in `nixos-archive/overlays/whisper-dict-daemon.py` and the overlay
file has the full pipeline. to port:
1. install deps: `python-evdev`, `pipewire` (pw-record), `whisper-cpp`,
   `wtype`, `wl-clipboard`, `libnotify`, `procps`, `opencc`.
2. download the ggml models: `ggml-base.en.bin` (english) and
   `ggml-small.bin` (multilingual) from
   `https://huggingface.co/ggerganov/whisper.cpp`.
3. copy the python daemon, substitute the `@placeholder@` paths with real
   binary paths (or just use `shutil.which` at runtime — simpler).
4. wire it as a systemd user service that starts with the graphical session.
5. bind `Mod+D` in niri to send the key event the daemon watches for (the
   daemon reads /dev/input directly, so the niri bind is just to make sure
   the key isn't swallowed — read the daemon source to get the exact evdev
   key code it listens for).
ask me before you start this — it's fiddly and i want to review each step.

### 14. locale
- timezone: `Europe/London` → `timedatectl set-timezone Europe/London`.
- locale: default `en_HK.UTF-8`, everything else `en_GB.UTF-8`. uncomment
  both in `/etc/locale.gen`, run `locale-gen`, set in `/etc/locale.conf`
  and `~/.config/environment.d/locale.conf`.
- keyboard: `us` layout.

### 15. env vars
from `nixos-archive/configuration.nix` `environment.sessionVariables`, port
the non-nix ones to `~/.config/environment.d/` or `/etc/environment`:
`NIXOS_OZONE_WL=1` (drop the nixos prefix — just `OZONE_WL=1` or
`ELECTRON_OZONE_PLATFORM_HINT=wayland`), `GTK_USE_PORTAL=1`,
`XDG_CURRENT_DESKTOP=niri`, `XDG_SESSION_TYPE=wayland`, `EDITOR=nvim`,
`VISUAL=nvim`.

### 16. my own quickshell panel (placeholder)
i'm going to write my own quickshell panel to replace noctalia. for now:
- install `quickshell` (AUR or build from
  `github:outfoxxed/quickshell`).
- leave an empty `~/.config/quickshell/` dir. don't write any panel code yet —
  i'll do that in a separate session. just make sure quickshell runs
  (`quickshell` binary on PATH).

---

**rules:**

- use `paru -S --needed` so reruns don't reinstall.
- tell me before installing anything from the AUR that's flagged
  out-of-date or orphaned.
- don't enable a service without telling me what it does first.
- after each major step, run a quick check (e.g. `systemctl is-active`,
  `nvidia-smi`, `niri msg version`) and show me the result.
- if something isn't packaged on arch/AUR at all, stop and ask — don't
  silently skip or build from source without my ok.
- keep the diff reviewable: do system config edits in files i can see
  (`/etc/greetd/config.toml`, `/etc/locale.conf`, etc.), show me each one.
- at the end, give me a checklist of what's done, what's pending, and what
  needs my manual decision.
