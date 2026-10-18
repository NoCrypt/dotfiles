# dotfiles

Managed with chezmoi source naming.

- `dot_config/` — maps to `~/.config/` (`dot_` = leading dot). `private_` = private file mode, `executable_` = executable bit.
- `etc/`, `usr/`, `boot/` — reference copies of system files that live outside `$HOME`, kept in
  sync with `scripts/sync-system.sh` (see [System files](#system-files)); not applied by chezmoi
  (see `.chezmoiignore`).
- `scripts/` — machine setup kept in the repo only, not applied by chezmoi: `post-install.sh` (the lean Arch installer), `pkglist` (the packages it installs) and `sync-system.sh` (system file sync).

## Bootstrap

On a fresh Arch install, as your user:

```sh
chezmoi init NoCrypt/dotfiles        # clone only, into ~/.local/share/chezmoi
cd ~/.local/share/chezmoi

sudo TARGET_USER="$USER" scripts/post-install.sh   # packages + system config
scripts/sync-system.sh push                        # repo -> /etc, /usr, /boot
chezmoi apply                                      # dotfiles over the defaults
```

The installer enables `NetworkManager`, `bluetooth`, `power-profiles-daemon`, `rtkit-daemon` and
`sddm` (default; `DISPLAY_MANAGER=none` skips it), plus `asusd` and the NVIDIA suspend/resume
units on matching hardware. Before the first `pacman -S` after `push`: `etc/pacman.conf` enables
`[chaotic-aur]`, so install `chaotic-keyring` and `chaotic-mirrorlist` and sign the key first, or
pacman fails on the missing include.

It leaves the rest of the repo's runtime setup to you:

```sh
sudo pacman -S --needed scx-scheds reflector zram-generator
sudo systemctl enable --now scx.service reflector.timer
```

- `scx.service` — sched_ext `scx_bpfland`; the unit is in `etc/systemd/system/`.
- `reflector.timer` — refreshes the mirrorlist using the config in `/etc/xdg/reflector/` (shipped as `etc/xdg/reflector/reflector.conf`).
- `zram-generator` — reads `/etc/systemd/zram-generator.conf.d/` at boot; there is no unit to enable.

`etc/fstab` is pull-only: `push` skips it, since a stale fstab can make the machine unbootable.

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
| `dot_config/mango/` | mangowm — settings, keybinds and helper scripts, listed [below](#mango) |
| `dot_config/mangobar/` | status bar — athos-gruv layout, GitHub Dark, rounder/spaced, fuzzel app-list, wlogout power menu, `custom/caffeine` (coffee toggle = prevent idle), `custom/brightness` (scroll = brightness, click = switch screen), `custom/record` (red recording capsule), tray icons from the `ncpt-tray` glyph theme |
| `dot_config/gtk-3.0/` | GTK3 icon theme = `ncpt-tray` (used by mangobar's tray lookup) |
| `dot_config/kdeglobals`, `dot_config/dolphinrc`, `dot_local/share/dolphin/` | Dolphin file manager — GitHub Dark KDE palette, Google Sans Flex 11, Papirus-Dark icons, Details view with previews |
| `dot_local/share/icons/ncpt-tray/` | Nerd Font glyph overrides for tray icons (`nm-*`, `blueman-tray`), inherits Adwaita |
| `dot_config/mako/` | notification daemon — GitHub Dark, 14 pt JetBrainsMono, 420 px wide; left click a screenshot notification opens it in imv |
| `dot_config/swaylock/` | lock screen — swaylock-effects: blurred screenshot + GitHub Dark clock ring |
| `dot_config/fuzzel/` | launcher (GitHub Dark) |
| `dot_config/fontconfig/` | monospace → JetBrainsMono Nerd Font; sans-serif/sans → Google Sans Flex |
| `dot_local/share/fonts/GoogleSansFlex/` | Google Sans Flex variable font (UI text) + OFL license |
| `dot_config/fastfetch/` | fastfetch config + logo image (`miku.png`) |
| `dot_config/private_fish/` | fish shell (ctrl-h / ctrl-arrow / ctrl-backspace word binds) |
| `dot_config/opencode/` | OpenCode CLI: github-transparent theme, `ponytail` plugin, vendored `openrouter-credit` plugin (not loaded) |
| `etc/sddm.conf.d/` | SDDM: orbital theme, X11 greeter, cursor theme |
| `etc/fstab` | btrfs subvols (`@`,`@home`,`@var`), ext4 `/boot`, vfat ESP; no snapshots configured |
| `boot/grub/themes/minimal/` | GRUB theme — minimal Terminus text on black (`tomdewildt/minimal-grub-theme`) |
| `etc/default/grub` | GRUB_TIMEOUT=1; `GRUB_THEME=/boot/grub/themes/minimal/theme.txt` |
| `etc/mkinitcpio.conf` | no `kms` hook, so nouveau is not loaded before the root subvolume is mounted; the installer's `/etc/mkinitcpio.conf.d/nvidia.conf` drop-in is the exception that embeds the NVIDIA modules |
| `etc/systemd/zram-generator.conf.d/` | zram0 (zstd, 50% RAM; needs `zram-generator`) |
| `etc/xdg/reflector/` | reflector mirrorlist config (freedif excluded; reason not recorded — see the file) |
| `etc/pacman.conf` | repos incl. chaotic-aur (needs `chaotic-keyring` + `chaotic-mirrorlist`, key signed first) |
| `usr/share/sddm/scripts/Xsetup` | reverse-PRIME: power on the external monitor at 2560x1440@165; dark the laptop panel when docked |
| `etc/alsa-card-profile/`, `etc/udev/rules.d/91-pipewire-alsa-port-split.rules`, `etc/modprobe.d/alsa-base.conf`, `usr/lib/firmware/hda-jack-retask.fw` | split the ALC256 speakers and headphone jack into two independent PipeWire sinks (ALSA `indep_hp=yes` + custom ACP profile set) |
| `usr/share/sddm/themes/orbital/` | orbital SDDM theme (stock black background, `themeMode=dark`) |
| `scripts/post-install.sh` | lean Arch installer (mango + mangobar, GRUB, NVIDIA/ASUS, PipeWire, NetworkManager, SDDM); run as root on a fresh install |
| `scripts/pkglist` | packages that installer pulls in — `post-install.sh --list`; regenerate with `bash scripts/post-install.sh --list > scripts/pkglist` |

### mango

| Script | Keybind | What |
| --- | --- | --- |
| `config.conf` | | dwindle on all tags, Super-based binds, blur/borders, dialog float rules, autostart |
| `keybinds.sh` | Super+/ | keybind cheatsheet (fuzzel) |
| `scripts/bar.sh` | Super+H | hide/show mangobar |
| `scripts/caffeine.sh` | bar coffee icon | pause idle management while on |
| `scripts/clipboard.sh` | Super+V | cliphist picker → `wl-copy` |
| `scripts/idle.sh` | autostart | AC: screen off after 600 s; battery: screen off 300 s, lock 2400 s, suspend 3600 s; 10 s screen-off while locked; re-applies on plug/lock changes |
| `scripts/knob.sh` | Ctrl+knob / Ctrl+press / Alt+press | brightness up/down, pick screen, next audio sink (plain knob = volume via `swayosd-client`) |
| `scripts/nightlight.sh` | Super+Alt+N | wlsunset on/off |
| `scripts/ocr.sh` | bar title right-click | frozen region → tesseract → clipboard |
| `scripts/panel.sh` | Super+Alt+P | laptop panel off/on |
| `scripts/powerprofile.sh` | Super+P | cycle power profile quiet → balanced → performance (power-profiles-daemon, asusd follows) with a `swayosd` OSD |
| `scripts/record.sh` | Super+J | GPU recording to `$XDG_VIDEOS_DIR` (default `~/video`), notifications, bar capsule |
| `scripts/screenshot.sh` | Super+Shift+S | frozen region → clipboard + notification (click it to annotate in satty) |
| `scripts/screenshot-full.sh` | Super+S / Super+Ctrl+S | full screen → copy; Super+Ctrl+S also opens satty |
| `scripts/notif-open.sh` | mako left click | open the file a screenshot notification points at in satty |
| `wallpaper/` | | `miku-light.jpg` (used by `swaybg` in `config.conf`), `miku-dark.png`, `miku.jpg` |
| `wlogout/` | Super+Escape | power menu (also the bar power icon) |

Wallpapers and images are included. Excluded: credentials (`~/.config/gh`,
`~/.ssh`, the OpenCode credential store) and caches.

## Known drift

Apps rewrite their own state in `$HOME`, so `chezmoi status` can be dirty after normal use:
Dolphin rewrites `dolphinrc` (`[IconsMode] PreviewSize`), KDE can add recent-color entries to
`kdeglobals`, fish keeps `fish_variables`, and OpenCode writes caches and its skills dir.
`fish_variables` and OpenCode's skills dir are in `.chezmoiignore`; the KDE files are not. Read
`chezmoi diff` before `chezmoi apply` — don't apply blindly.

## Docs

- [PALETTE.md](PALETTE.md) — the GitHub Dark palette and where each value is used.
- [THIRD_PARTY.md](THIRD_PARTY.md) — vendored components (mangobar layout athos-megas, wlogout
  power menu + icons DreamMaoMao, SDDM orbital theme Rizmi/ryoku) with sources and licenses.
- [LICENSE](LICENSE) — MIT for original work.
