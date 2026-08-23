# arch migration plan — replacing nixos on this machine

> **read this entirely before starting.** this is a wipe-and-reinstall of the
> linux side of a dual-boot machine. windows stays untouched. if you follow
> the steps in order, nothing on windows can be harmed. the only partition
> that gets wiped is `nvme0n1p5` (the 197G ext4 nixos root).

## disk layout (do not change, reference only)

```
nvme0n1 (953.9G NVMe)
├─ p1  vfat   260M   EFI System (ESP) → /boot   Limine + Windows Boot Manager
├─ p2         16M    Microsoft reserved (MSR)                    DO NOT TOUCH
├─ p3  ntfs   755G   Windows C: drive                            DO NOT TOUCH
├─ p4  ntfs   853M   Windows recovery                            DO NOT TOUCH
├─ p5  ext4   197G   Linux filesystem  ← WIPE + INSTALL ARCH HERE
└─ p6  vfat   512M   second ESP (unused)                         LEAVE ALONE
```

key ids (verified 2025-08-23):
- windows ESP partition guid: `88f3bef0-f939-4420-97c0-431e89278101` (p1)
- nixos/arch root PARTUUID: `a57178ab-c69a-444a-82ff-b3e993ce2bc1` (p5)
- p5 filesystem uuid (will change after mkfs): `cb3186ae-...`

## decisions

- backup: none (cloud only). dotfiles repo is on github. browser/obsidian sync
  handles the rest. **see phase 0 step 4 for the two tiny things to grab anyway.**
- arch partition layout: single ext4 root on p5 (197G), /home on it. no swap.
- second ESP (p6): leave untouched.
- windows fast startup: disable (phase 0 step 2).
- secure boot: temporarily disable for the install (phase 1), re-enable after
  arch is signed with sbctl (phase 4).

---

## phase 0 — pre-flight (in nixos, while it still boots)

### 1. verify dotfiles repo is clean and pushed
```bash
cd ~/git/dotfiles && git status && git log --oneline -3
```
should show clean tree, latest commit `7e3a8e1` (or newer) on `main`. if not,
commit + push before doing anything else — this repo is your restore source.

### 2. disable windows fast startup
boot into windows, then **one** of:
- gui: control panel → power options → "choose what the power buttons do" →
  "change settings that are currently unavailable" → uncheck "turn on fast
  startup" → save.
- cmd (admin): `powercfg /h off` (also disables hibernation entirely).

this stops windows from hibernating the ntfs volume, which would lock p3 and
risk corruption when linux is running. required for safe dual-boot.

### 3. flash the arch iso to a usb
download the latest arch iso from <https://archlinux.org/download/>. flash it:
```bash
# on linux (replace /dev/sdX with the usb device, NOT a partition):
sudo dd if=archlinux-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
# or use ventoy if you already have a ventoy usb — just drop the iso on it.
```
verify the usb boots before you wipe anything.

### 4. grab the two tiny irreplaceable files (strongly recommended, ~5m)
even though you're skipping a full backup, these two are painful to lose and
trivial to save. copy them to a usb, or to the unused p6 esp, or to a secure
cloud drop:
```bash
# option A: a usb stick
cp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub /run/media/isaac/USB/
cp -r ~/.config/Bitwarden /run/media/isaac/USB/

# option B: the unused p6 esp (mount it temporarily)
sudo mount /dev/nvme0n1p6 /mnt
sudo cp ~/.ssh/id_ed25519 ~/.ssh/id_ed25519.pub /mnt/
sudo cp -r ~/.config/Bitwarden /mnt/
sudo umount /mnt
```
why: the ssh key is trusted by github + any servers you ssh to — losing it
means regenerating and re-adding the public key everywhere. bitwarden local
state holds your session/vault cache; losing it forces a fresh login + sync.

### 5. screenshot / write down the current limine.conf
you can't read `/boot` as a non-root user (fmask=0077). run:
```bash
sudo cat /boot/limine/limine.conf
```
save the output somewhere (usb, phone photo). you'll reuse the windows entry
and the terminal palette from it. the nixos generation entries get replaced
with a static arch entry in phase 2.

---

## phase 1 — firmware prep

### 6. reboot into uefi/bios
reboot, press the firmware key (usually f2 or del on this machine) to enter
uefi settings.

### 7. disable secure boot (temporary)
find the secure boot setting (usually under "security" or "boot"), set it to
**disabled**. on some firmware you also need to switch from "user mode" to
"setup mode" by clearing the enrolled keys — if there's a "delete/clear
secure boot keys" option, use it; you'll re-enroll fresh keys with sbctl in
phase 4 anyway.

note what you changed so you can undo it later. **do not touch anything else
in firmware.**

### 8. boot the arch iso
plug in the usb from step 3, boot from it (f12 boot menu). the arch live
environment should come up to a root zsh prompt.

---

## phase 2 — install arch (from the live usb)

> from here you're root in the arch live environment. commands are safe to run
> as shown. the only destructive command is the `mkfs.ext4` in step 12, and it
> targets p5 only.

### 9. connect to the network
```bash
# ethernet: automatic, skip this.
# wifi:
iwctl                                          # interactive
# inside iwctl:  station wlan0 scan  →  station wlan0 connect "SSID"
# enter passphrase, quit iwctl
ping -c3 archlinux.org                         # verify
```

### 10. verify the disk layout matches this plan
```bash
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINTS,PARTUUID
```
confirm p5 is the 197G ext4 (the nixos root). **do not proceed if the layout
looks different** — re-read the disk layout at the top of this file and make
sure p5 is still the linux partition. if anything moved, stop and figure out
why before wiping.

### 11. (optional) grab last-minute files off the nixos root before wiping
if you forgot anything in phase 0 step 4, this is your last chance:
```bash
mount -o ro /dev/nvme0n1p5 /mnt
ls /mnt/home/isaac                             # confirm your home is here
cp -r /mnt/home/isaac/.ssh /tmp/               # grab ssh key
cp -r /mnt/home/isaac/.config/Bitwarden /tmp/  # grab bitwarden
# (copy these to a usb afterward)
umount /mnt
```

### 12. wipe p5 and create the arch root filesystem
```bash
mkfs.ext4 -F -L root /dev/nvme0n1p5
```
this is the one destructive step. it wipes nixos and your `/home`. everything
on p1/p2/p3/p4/p6 is untouched.

### 13. mount the new root + the ESP
```bash
mount /dev/nvme0n1p5 /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/boot
```
the ESP (p1) mounts at `/mnt/boot`. limine + the windows boot manager already
live on it — do not format p1.

### 14. pacstrap the base system
```bash
pacstrap -K /mnt base base-devel linux linux-firmware \
    networkmanager zsh neovim git curl wget openssh \
    efibootmgr man-db man-pages texinfo
```
this is the minimal bootable set + the tools you need to install everything
else from the setup prompt later. `paru` and the full package list come after
first boot.

### 15. generate fstab
```bash
genfstab -U /mnt >> /mnt/etc/fstab
```
verify it has entries for `/` (p5) and `/boot` (p1):
```bash
cat /mnt/etc/fstab
```

### 16. chroot in
```bash
arch-chroot /mnt
```
all following steps run inside the chroot (you'll see `[root@archiso /]#`).

### 17. timezone + clock
```bash
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
```

### 18. locale
```bash
# uncomment these two lines in /etc/locale.gen:
#   en_HK.UTF-8 UTF-8
#   en_GB.UTF-8 UTF-8
nvim /etc/locale.gen
locale-gen
echo "LANG=en_HK.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
```

### 19. hostname + network
```bash
echo "nixos" > /etc/hostname          # keep the old hostname, or change it
systemctl enable NetworkManager
```

### 20. root password + user isaac
```bash
passwd                              # set root password
useradd -m -G wheel,input,wireshark -s /usr/bin/zsh isaac
passwd isaac                        # set isaac's password
# uncomment the wheel sudo line:
nvim /etc/sudoers                   # →  %wheel ALL=(ALL:ALL) ALL
```

### 21. install paru (for AUR)
paru isn't in the official repos. install it from AUR as the isaac user:
```bash
su - isaac
cd /tmp
git clone https://aur.archlinux.org/paru-bin.git
cd paru-bin
makepkg -si
exit                                # back to root
```

### 22. bootloader — reuse the existing limine, just edit limine.conf
the limine binary on p1 already works (nixos installed it). you do not need to
reinstall limine for the first boot — just point its config at the arch kernel.

first, find out where the arch kernel/initramfs will live. by default arch
installs them to `/boot` (which is p1, the ESP), so the paths inside limine
are `boot():/vmlinuz-linux` and `boot():/initramfs-linux.img`.

edit the limine config (the ESP is mounted at /boot in the chroot):
```bash
nvim /boot/limine/limine.conf
```
replace the nixos generation entries with a static arch entry. keep the
windows entry and the terminal palette from the old config (the one you saved
in phase 0 step 5). the arch entry:
```
/Arch Linux
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    module_path: boot():/initramfs-linux.img
    cmdline: root=PARTUUID=a57178ab-c69a-444a-82ff-b3e993ce2bc1 rw

/Arch Linux (fallback initramfs)
    protocol: linux
    kernel_path: boot():/vmlinuz-linux
    module_path: boot():/initramfs-linux-fallback.img
    cmdline: root=PARTUUID=a57178ab-c69a-444a-82ff-b3e993ce2bc1 rw
```
keep the windows entry exactly as it was:
```
/+Other systems and bootloaders
//Windows Boot Manager
    comment: Windows 11 25H2
    protocol: efi_chainload
    image_path: guid(88f3bef0-f939-4420-97c0-431e89278101):/efi/Microsoft/Boot/bootmgfw.efi
```
also keep the global `timeout:`, `term_*`, and `interface_*` lines from the
old config (the monochrome palette).

> the kernel files (`vmlinuz-linux`, `initramfs-linux.img`) don't exist yet —
> pacstrap put them on p1 at `/boot/...` during the base install. verify:
> `ls /boot/vmlinuz-linux /boot/initramfs-linux.img`. if present, you're set.

### 23. install limine from AUR (for future upgrades)
so you can run `limine deploy` after limine package upgrades:
```bash
paru -S limine
```
set up the pacman hook so `limine deploy` re-runs after limine upgrades:
```bash
cat > /etc/pacman.d/hooks/limine.hook <<'EOF'
[Trigger]
Operation = Upgrade
Type = Package
Target = limine

[Action]
Description = Re-running limine deploy after upgrade...
When = PostTransaction
Exec = /usr/bin/limine deploy /dev/nvme0n1p1
EOF
```
(`/dev/nvme0n1p1` is the ESP. adjust if your device name differs — verify with
`lsblk`.)

### 24. exit chroot + reboot
```bash
exit                    # leave chroot
umount -R /mnt
reboot
```
remove the usb when prompted. limine should show "Arch Linux" + "Windows Boot
Manager". boot arch.

---

## phase 3 — first boot in arch + restore

### 25. log in as isaac, connect to network
```bash
# if wifi:
nmcli device wifi connect "SSID" password "..."
```

### 26. clone dotfiles + run the restore prompt
```bash
git clone git@github.com:isaacwong05/dotfiles.git ~/git/dotfiles
# you'll need your ssh key for this — restore it from phase 0 step 4 first:
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /path/to/saved/id_ed25519 ~/.ssh/ && chmod 600 ~/.ssh/id_ed25519
cp /path/to/saved/id_ed25519.pub ~/.ssh/
# then:
cat ~/git/dotfiles/arch-setup-prompt.md
```
paste the "## prompt" section of `arch-setup-prompt.md` into your agent (pi /
claude code). it will walk you through steps 2-16 of the restore (packages,
shell, configs, greetd/niri, audio, nvidia, services, portals, theming,
lockscreen, dictation, env vars, quickshell placeholder). the bootloader
(steps 5 of that prompt) is already done by phase 2 above — tell the agent to
skip it.

### 27. restore bitwarden (if you saved it)
```bash
cp -r /path/to/saved/Bitwarden ~/.config/
```

---

## phase 4 — re-enable secure boot

> only do this after arch boots reliably with secure boot off. if anything's
> unstable, fix it first — re-enabling secure boot too early can make the
> machine unbootable and force a firmware reset.

### 28. install sbctl + create keys
```bash
paru -S sbctl
sudo sbctl create-keys
```

### 29. enroll your keys into uefi
```bash
sudo sbctl enroll-keys --microsoft          # keep microsoft keys for windows
```
`--microsoft` keeps the microsoft vendor keys so windows still boots with
secure boot on. do not omit this on a dual-boot machine.

### 30. sign the limine binary + arch kernel + initramfs
```bash
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI        # limine (path may vary)
sudo sbctl sign -s /boot/vmlinuz-linux
sudo sbctl sign -s /boot/initramfs-linux.img
sudo sbctl sign -s /boot/initramfs-linux-fallback.img
```
`-s` makes the signature persistent (sbctl re-signs automatically after kernel
upgrades via a pacman hook). verify the limine efi path with `ls /boot/EFI/`
first — it might be at `/boot/EFI/limine/BOOTX64.EFI` or similar.

### 31. verify before rebooting
```bash
sudo sbctl verify
```
everything should show ✓. if anything shows ✗, do not reboot — fix it first.

### 32. re-enable secure boot in firmware
reboot, enter uefi, set secure boot to **enabled**. save + reboot. both arch
and windows should boot with secure boot on.

### 33. (optional) enroll limine's config hash
limine can verify its own config via a hashed config + enroll. this is the
`enrollConfig` / `panicOnChecksumMismatch` feature from the nixos config. it's
advanced and optional — only do this after steps 28-32 work. see the limine
docs at <https://limine-bootloader.org/docs/secure-boot/> and the
`limine enroll-config` command. skip if unsure.

---

## what you'll lose (no backup)

- `~/.ssh/id_ed25519` — **if you didn't grab it in phase 0 step 4.** regenerate
  with `ssh-keygen -t ed25519`, re-add the pubkey to github (settings → ssh
  keys) and any servers.
- `~/.config/Bitwarden` — forces a fresh `bw login` + sync. vault data is on
  bitwarden's servers, nothing is actually lost, just the local session.
- `~/.config/mozilla` — firefox profile (history, tabs, cookies). if you have
  firefox sync enabled and signed in, it restores. if not, gone.
- `~/.config/BeeperTexts` — beeper account state, re-login required.
- `~/.config/net.imput.helium` (503M) — helium browser state, re-setup required.
- `~/.config/obs-studio` — obs scenes/settings, reconfigure.
- `~/Downloads` (2.4G) — whatever you had there, gone.
- `~/Documents` (35M) — gone unless obsidian-synced.
- everything in `~/.config` that's tracked in the dotfiles repo → restored
  from github. everything not tracked → gone.

---

## rollback

if arch doesn't boot and you want nixos back: you can't, p5 is wiped. options:
- **restore from a nixos usb** if you made one (you didn't, per the no-backup
  decision). nixos is reproducible from the flake in `nixos-archive/`, so you
  could `nixos-install` from a fresh nixos iso pointing at the archived flake
  — this would rebuild the exact system you had. this is your real safety net.
- **windows still boots** regardless — the windows entry in limine is
  untouched, and you can always boot the windows install from the firmware
  boot menu if limine somehow breaks.

the flake at `~/git/dotfiles/nixos-archive/` is a complete nixos
specification. to restore nixos from it: boot a nixos iso, mount p5, run
`sudo nixos-install --flake ~/git/dotfiles/nixos-archive#nixos`. this is why
the archive is in the repo.
