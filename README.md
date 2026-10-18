# dotfiles

Managed with chezmoi source naming.

- `dot_config/` — maps to `~/.config/` (`dot_` = leading dot). `private_` = private file mode, `executable_` = executable bit.
- `etc/`, `usr/`, `boot/` — reference copies of system files that live outside `$HOME`, kept in
  sync with `scripts/sync-system.sh` (see [System files](#system-files)); not applied by chezmoi
  (see `.chezmoiignore`).
- `scripts/` — machine setup kept in the repo only, not applied by chezmoi: `post-install.sh` (the lean Arch installer), `pkglist` (the packages it installs) and `sync-system.sh` (system file sync).

## System files

`etc/`, `usr/` and `boot/` are reference copies of files outside `$HOME`. Keep them in sync with:

```sh
scripts/sync-system.sh status   # diff repo vs system, read-only
scripts/sync-system.sh pull     # copy system -> repo
scripts/sync-system.sh push     # copy repo -> system (sudo)
```

All three accept `--dry-run`. `push` backs up every file it overwrites to
`/var/backups/dotfiles-sync/<timestamp>/` and reruns `grub-mkconfig` (GRUB files) or
`mkinitcpio -P` (`mkinitcpio.conf`) when needed.

`etc/fstab` is included in `status`/`pull` but never pushed: a stale fstab can make the machine
unbootable.

## Preview

![mango + mangobar + kitty/fastfetch on the laptop panel](screenshot.png)

## Contents

| Path | What |
| --- | --- |
| `dot_config/kitty/` | kitty terminal (JetBrainsMono Nerd Font, GitHub Dark colors) |
| `dot_config/mango/` | mangowm (dwindle, Super-based binds, blur, borders); `keybinds.sh` (Super+/ cheatsheet); `scripts/knob.sh` (volume knob: plain = volume, Ctrl = brightness, Ctrl+press = which screen, Alt+press = audio output); `scripts/idle.sh` (power-aware idle: AC = screen off only, battery = screen off / lock / suspend, 30 s screen-off while locked, swapped on plug); `scripts/caffeine.sh` (bar coffee toggle; pauses idle management while on); `scripts/screenshot.sh` (Super+Shift+S frozen region → satty); `scripts/screenshot-full.sh` (Super+S full screen, copy; Super+Ctrl+S → satty); `scripts/clipboard.sh` (Super+V cliphist picker); `scripts/record.sh` (Super+J GPU recording, `~/video`, notifications); `scripts/nightlight.sh` (Super+Alt+N wlsunset); `scripts/panel.sh` (Super+Alt+P panel off/on); `scripts/bar.sh` (Super+H bar toggle); `scripts/ocr.sh` (bar title right-click → frozen region → tesseract); `wlogout/` power menu |
| `dot_config/mango/wallpaper/` | wallpapers (`miku-dark.png`, `miku.jpg`) |
| `dot_config/mangobar/` | status bar — athos-gruv layout, GitHub Dark, rounder/spaced, fuzzel app-list, wlogout power menu, `custom/caffeine` (coffee toggle = prevent idle), `custom/brightness` (scroll = brightness, click = switch screen), `custom/record` (red recording capsule), tray icons from the `ncpt-tray` glyph theme |
| `dot_config/gtk-3.0/` | GTK3 icon theme = `ncpt-tray` (used by mangobar's tray lookup) |
| `dot_config/kdeglobals`, `dot_config/dolphinrc`, `dot_local/share/dolphin/` | Dolphin file manager — GitHub Dark KDE palette, Noto Sans 11, Papirus-Dark icons, Details view with previews |
| `dot_local/share/icons/ncpt-tray/` | Nerd Font glyph overrides for tray icons (`nm-*`, `blueman-tray`), inherits Adwaita |
| `dot_config/mako/` | notification daemon — GitHub Dark, 14 pt JetBrainsMono, 420 px wide |
| `dot_config/swaylock/` | lock screen — swaylock-effects: blurred screenshot + GitHub Dark clock ring |
| `dot_config/fuzzel/` | launcher (GitHub Dark) |
| `dot_config/fontconfig/` | monospace → JetBrainsMono Nerd Font |
| `dot_config/fastfetch/` | fastfetch config + logo image (`miku.png`) |
| `dot_config/private_fish/` | fish shell (ctrl-arrow / ctrl-backspace word binds) |
| `dot_config/opencode/` | OpenCode CLI: github-transparent theme, openrouter-credit plugin |
| `etc/sddm.conf.d/` | SDDM: orbital theme, X11 greeter, cursor theme |
| `etc/fstab` | btrfs subvols (`@`,`@home`,`@var`), ext4 `/boot`, vfat ESP; no snapshots configured |
| `boot/grub/themes/ncpt/` | GRUB theme — flat black, GitHub Dark accents, `DejaVu Sans` menu |
| `etc/default/grub` | GRUB_TIMEOUT=1; `GRUB_THEME=/boot/grub/themes/ncpt/theme.txt` |
| `etc/mkinitcpio.conf` | no `kms` hook — NVIDIA kept out of the initramfs |
| `etc/systemd/zram-generator.conf.d/` | zram0 (zstd, 50% RAM) |
| `etc/xdg/reflector/` | reflector mirrorlist config (freedif excluded) |
| `etc/pacman.conf` | repos incl. chaotic-aur |
| `usr/share/sddm/scripts/Xsetup` | reverse-PRIME: power on the external monitor; dark the laptop panel when docked |
| `usr/share/sddm/themes/orbital/` | orbital theme + image background (`Main.qml` edited to add it) |
| `scripts/post-install.sh` | lean Arch installer (mango + mangobar, GRUB, NVIDIA/ASUS, PipeWire, NetworkManager, SDDM); run as root on a fresh install |
| `scripts/pkglist` | packages that installer pulls in — `post-install.sh --list`; regenerate with `bash scripts/post-install.sh --list > scripts/pkglist` |

Wallpapers and images are included. Excluded: credentials (`~/.config/gh`,
`~/.ssh`, the OpenCode credential store) and caches.

Third-party bits vendored for convenience: the `mangobar` bar layout (athos-megas),
the `wlogout` power menu + icons (DreamMaoMao), and the SDDM `orbital` theme
(Rizmi/ryoku).
