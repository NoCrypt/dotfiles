# dotfiles

Managed with chezmoi source naming.

- `dot_config/` — maps to `~/.config/` (`dot_` = leading dot). `private_` = private file mode, `executable_` = executable bit.
- `etc/`, `usr/`, `boot/` — system files that live outside `$HOME`; copy them with `sudo`, e.g.
  `sudo cp etc/sddm.conf.d/*.conf /etc/sddm.conf.d/`,
  `sudo cp -r usr/share/sddm/themes/orbital/* /usr/share/sddm/themes/orbital/` and
  `sudo cp -r boot/grub/themes/ncpt /boot/grub/themes/` (then `sudo grub-mkconfig -o /boot/grub/grub.cfg`).
  Recorded here for reference/restore, not applied by chezmoi (see `.chezmoiignore`).
- `scripts/` — machine setup kept in the repo only, not applied by chezmoi: `post-install.sh` (the lean Arch installer) and `pkglist` (the packages it installs).

## Preview

![mango + mangobar + kitty/fastfetch on the laptop panel](screenshot.png)

## Contents

| Path | What |
| --- | --- |
| `dot_config/kitty/` | kitty terminal (JetBrainsMono Nerd Font, GitHub Dark colors) |
| `dot_config/mango/` | mangowm (dwindle, Super-based binds, blur, borders); `keybinds.sh` (Super+/ cheatsheet); `scripts/knob.sh` (volume knob: plain = volume, Ctrl = brightness, Ctrl+press = which screen, Alt+press = audio output); `scripts/idle.sh` (power-aware idle: AC = screen off only, battery = screen off / lock / suspend, 30 s screen-off while locked, swapped on plug); `scripts/caffeine.sh` (bar coffee toggle; pauses idle management while on); `scripts/screenshot.sh` (Super+Shift+S frozen region → satty); `scripts/screenshot-full.sh` (Super+S full screen, copy; Super+Ctrl+S → satty); `scripts/clipboard.sh` (Super+V cliphist picker); `scripts/record.sh` (Super+J GPU recording, `~/video`, notifications); `scripts/nightlight.sh` (Super+Alt+N wlsunset); `scripts/panel.sh` (Super+Alt+P panel off/on); `scripts/bar.sh` (Super+H bar toggle); `scripts/ocr.sh` (bar title right-click → tesseract); `wlogout/` power menu |
| `dot_config/mango/wallpaper/` | wallpapers (`miku-dark.png`, `miku.jpg`) |
| `dot_config/mangobar/` | status bar — athos-gruv layout, GitHub Dark, rounder/spaced, fuzzel app-list, wlogout power menu, `custom/caffeine` (coffee toggle = prevent idle), `custom/brightness` (scroll = brightness, click = switch screen), `custom/record` (red recording capsule), tray icons from the `ncpt-tray` glyph theme |
| `dot_config/gtk-3.0/` | GTK3 icon theme = `ncpt-tray` (used by mangobar's tray lookup) |
| `dot_local/share/icons/ncpt-tray/` | Nerd Font glyph overrides for tray icons (`nm-*`, `blueman-tray`), inherits Adwaita |
| `dot_config/mako/` | notification daemon — GitHub Dark, 14 pt JetBrainsMono, 420 px wide |
| `dot_config/swaylock/` | lock screen — swaylock-effects: blurred screenshot + GitHub Dark clock ring |
| `dot_config/fuzzel/` | launcher (GitHub Dark) |
| `dot_config/fontconfig/` | monospace → JetBrainsMono Nerd Font |
| `dot_config/fastfetch/` | fastfetch config + logo image (`miku.png`) |
| `dot_config/private_fish/` | fish shell (ctrl-arrow / ctrl-backspace word binds) |
| `dot_config/opencode/` | OpenCode CLI: github-transparent theme, openrouter-credit plugin |
| `etc/sddm.conf.d/` | SDDM: orbital theme, X11 greeter, cursor theme |
| `etc/fstab` | btrfs subvols (`@`,`@home`,`@var`), ext4 `/boot`, vfat ESP |
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
