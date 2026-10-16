#!/usr/bin/env bash
# post-install.sh - lean Arch setup: MangoWM + mangobar, GRUB + os-prober,
# NVIDIA, ASUS (asusd), PipeWire audio, NetworkManager, power-profiles-daemon.
#
# Run as root on the INSTALLED system (booted, not from the live ISO):
#   sudo TARGET_USER=ncpt ./post-install.sh
#
# Options (environment variables):
#   TARGET_USER         user to configure (default: $SUDO_USER)
#   DISPLAY_MANAGER     sddm | none            (default: sddm)
#   GRUB_INSTALL        1 = also run grub-install (UEFI only)   (default: 0)
#   ASUSCTL_SOURCE      extra | ogc   asusctl from [extra] (asus-linux.org) or
#                       built from github.com/OpenGamingCollective/asusctl 6.4.0,
#                       as Ryoku does                          (default: extra)
#   NVIDIA_DRIVER       override driver package (default: nvidia-open / -dkms)
#   REGDOM              wireless regulatory domain, e.g. US     (default: unset)
#   AUDIO_NO_POWERSAVE  1 = snd_hda_intel power_save=0 (fixes idle hiss/pop)
#
#   ./post-install.sh --list   print the package lists and exit

set -euo pipefail

# ---------------------------------------------------------------- packages --
PKG_BASE=(base-devel git sudo man-db man-pages pciutils linux-firmware sof-firmware)
PKG_BOOT=(grub efibootmgr os-prober ntfs-3g dosfstools)
PKG_NET=(networkmanager wpa_supplicant wireless-regdb iw bluez bluez-utils)
PKG_AUDIO=(pipewire pipewire-alsa pipewire-pulse pipewire-audio wireplumber rtkit alsa-utils)
PKG_POWER=(power-profiles-daemon upower brightnessctl ddcutil)
PKG_DESKTOP=(mangowm xorg-xwayland xdg-desktop-portal xdg-desktop-portal-wlr
             xdg-desktop-portal-gtk polkit polkit-gnome foot fuzzel mako swaybg
             wl-clipboard grim slurp ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji)
# mangobar-git's PKGBUILD lists fewer deps than upstream meson.build requires,
# so everything meson.build asks for is installed up front.
PKG_MANGOBAR_DEPS=(cjson fcft tllist pixman wayland wayland-protocols cairo pango
                   libpulse gdk-pixbuf2 systemd-libs meson ninja)
PKG_AUR=(mangobar-git)

if [[ "${1:-}" == "--list" ]]; then
  for grp in PKG_BASE PKG_BOOT PKG_NET PKG_AUDIO PKG_POWER PKG_DESKTOP PKG_MANGOBAR_DEPS PKG_AUR; do
    declare -n ref="$grp"
    printf '# %s\n' "$grp"
    printf '%s\n' "${ref[@]}"
    echo
  done
  cat <<'EOF'
# Added automatically depending on hardware:
#   intel-ucode | amd-ucode              (CPU vendor)
#   vulkan-intel intel-media-driver      (Intel iGPU)
#   vulkan-radeon                        (AMD GPU)
#   nvidia-open nvidia-utils libva-nvidia-driver egl-wayland   (NVIDIA, Turing+)
#   nvidia-open-dkms + <kernel>-headers  (NVIDIA, non-stock kernel)
#   nvidia-prime                         (NVIDIA + another GPU = hybrid laptop)
#   asusctl                              (ASUS laptops: [extra], or OpenGamingCollective source build with ASUSCTL_SOURCE=ogc)
#   sddm                                 (DISPLAY_MANAGER=sddm)
EOF
  exit 0
fi

# ----------------------------------------------------------------- helpers --
log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!! \033[0m%s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx \033[0m%s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

[[ $EUID -eq 0 ]] || die "run as root (sudo)"
TARGET_USER="${TARGET_USER:-${SUDO_USER:-}}"
[[ -n "$TARGET_USER" ]] || die "set TARGET_USER=<your username>"
id "$TARGET_USER" >/dev/null 2>&1 || die "user '$TARGET_USER' does not exist"
[[ "$TARGET_USER" != root ]] || die "TARGET_USER must be a normal user (makepkg refuses root)"
USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
DISPLAY_MANAGER="${DISPLAY_MANAGER:-sddm}"
GRUB_INSTALL="${GRUB_INSTALL:-0}"
ASUSCTL_SOURCE="${ASUSCTL_SOURCE:-extra}"
[[ "$ASUSCTL_SOURCE" == extra || "$ASUSCTL_SOURCE" == ogc ]] || die "ASUSCTL_SOURCE must be extra or ogc"
AUDIO_NO_POWERSAVE="${AUDIO_NO_POWERSAVE:-0}"
REGDOM="${REGDOM:-}"

SYSTEMD_UP=0
[[ -d /run/systemd/system ]] && SYSTEMD_UP=1
enable_unit() {   # enable (and start, when systemd is actually running)
  if (( SYSTEMD_UP )); then
    systemctl enable --now "$@" || warn "could not enable/start: $*"
  else
    systemctl enable "$@" || warn "could not enable: $*"
  fi
}

# --------------------------------------------------------- hardware probing --
log "Probing hardware"
pacman -Syu --needed --noconfirm pciutils >/dev/null
GPU_INFO="$(lspci -nn | grep -Ei 'vga|3d|display' || true)"
HAS_NVIDIA=0; HAS_INTEL=0; HAS_AMD=0; IS_ASUS=0
grep -qi nvidia <<<"$GPU_INFO"        && HAS_NVIDIA=1
grep -qi 'intel'  <<<"$GPU_INFO"      && HAS_INTEL=1
grep -Eqi 'amd|ati|radeon' <<<"$GPU_INFO" && HAS_AMD=1
grep -qi asus /sys/class/dmi/id/sys_vendor 2>/dev/null && IS_ASUS=1
CPU_VENDOR="$(grep -m1 vendor_id /proc/cpuinfo | awk '{print $3}')"
echo "$GPU_INFO"
echo "nvidia=$HAS_NVIDIA intel=$HAS_INTEL amd=$HAS_AMD asus=$IS_ASUS cpu=$CPU_VENDOR"

PKG_HW=()
case "$CPU_VENDOR" in
  GenuineIntel) PKG_HW+=(intel-ucode) ;;
  AuthenticAMD) PKG_HW+=(amd-ucode) ;;
esac
PKG_HW+=(mesa vulkan-icd-loader)
(( HAS_INTEL )) && PKG_HW+=(vulkan-intel intel-media-driver)
(( HAS_AMD ))   && PKG_HW+=(vulkan-radeon)
if (( IS_ASUS )); then
  if [[ "$ASUSCTL_SOURCE" == ogc ]]; then
    PKG_HW+=(rust clang llvm libusb)     # build deps for the OGC source build
  else
    PKG_HW+=(asusctl)
  fi
fi

if (( HAS_NVIDIA )); then
  if [[ -n "${NVIDIA_DRIVER:-}" ]]; then
    PKG_HW+=("$NVIDIA_DRIVER" nvidia-utils)
  elif pacman -Q linux >/dev/null 2>&1; then
    PKG_HW+=(nvidia-open nvidia-utils)
  else
    PKG_HW+=(nvidia-open-dkms nvidia-utils)
    for k in linux-lts linux-zen linux-hardened; do
      pacman -Q "$k" >/dev/null 2>&1 && PKG_HW+=("$k-headers")
    done
  fi
  PKG_HW+=(libva-nvidia-driver egl-wayland)
  (( HAS_INTEL || HAS_AMD )) && PKG_HW+=(nvidia-prime)
  warn "nvidia-open needs a Turing (GTX 16xx / RTX) or newer GPU. Older cards need a legacy driver: set NVIDIA_DRIVER."
fi

[[ "$DISPLAY_MANAGER" == sddm ]] && PKG_HW+=(sddm)

# ------------------------------------------------------- official packages --
log "Installing official packages"
pacman -Syu --needed --noconfirm \
  "${PKG_BASE[@]}" "${PKG_BOOT[@]}" "${PKG_NET[@]}" "${PKG_AUDIO[@]}" \
  "${PKG_POWER[@]}" "${PKG_DESKTOP[@]}" "${PKG_MANGOBAR_DEPS[@]}" "${PKG_HW[@]}"

# ------------------------------------------------------------ AUR packages --
build_aur() {
  local pkg="$1" dir f
  dir="$(runuser -u "$TARGET_USER" -- mktemp -d)"
  runuser -u "$TARGET_USER" -- git clone --depth 1 "https://aur.archlinux.org/${pkg}.git" "$dir/$pkg"
  ( cd "$dir/$pkg" && runuser -u "$TARGET_USER" -- makepkg --noconfirm )
  for f in "$dir/$pkg"/*.pkg.tar.*; do
    [[ "$f" == *-debug-* ]] && continue
    pacman -U --noconfirm "$f"
  done
  rm -rf "$dir"
}
for p in "${PKG_AUR[@]}"; do
  pacman -Q "$p" >/dev/null 2>&1 || { log "Building AUR package $p"; build_aur "$p"; }
done

# asusctl built from OpenGamingCollective source (same recipe Ryoku uses):
# builds asusctl + asusd + asus-shutdown. Conflicts with tlp.
if (( IS_ASUS )) && [[ "$ASUSCTL_SOURCE" == ogc ]] && ! pacman -Q asusctl >/dev/null 2>&1; then
  log "Building asusctl 6.4.0 from OpenGamingCollective"
  pacman -Q tlp >/dev/null 2>&1 && die "tlp conflicts with asusctl; remove it first"
  odir="$(runuser -u "$TARGET_USER" -- mktemp -d)"
  cat > "$odir/PKGBUILD" <<'PKGEOF'
pkgname=asusctl
pkgver=6.4.0
pkgrel=1
pkgdesc='ASUS laptop control daemon and Aura lighting CLI (OpenGamingCollective)'
arch=('x86_64')
url='https://github.com/OpenGamingCollective/asusctl'
license=('MPL-2.0')
depends=('libusb' 'systemd-libs')
makedepends=('rust' 'clang' 'llvm')
provides=('asusctl')
conflicts=('asusctl-git' 'tlp')
options=('!debug')
source=("$pkgname-$pkgver.tar.gz::$url/archive/refs/tags/$pkgver.tar.gz")
sha256sums=('ba19565a1ed313cbb17b0d8926780023856fe85b9490f6b4fe65b7ede14ee434')

build() {
  cd "$pkgname-$pkgver"
  cargo build --release --locked -p asusctl -p asusd -p asus-shutdown
}

package() {
  cd "$pkgname-$pkgver"
  make DESTDIR="$pkgdir" install-asusctl install-asusd install-asus-shutdown install-data-asusd
  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}
PKGEOF
  chown "$TARGET_USER": "$odir/PKGBUILD"
  ( cd "$odir" && runuser -u "$TARGET_USER" -- makepkg --noconfirm )
  for f in "$odir"/*.pkg.tar.*; do
    [[ "$f" == *-debug-* ]] && continue
    pacman -U --noconfirm "$f"
  done
  rm -rf "$odir"
  udevadm control --reload 2>/dev/null || true
  (( SYSTEMD_UP )) && systemctl daemon-reload || true
fi

# ------------------------------------------------------------------- GRUB ---
log "Configuring GRUB + os-prober"
if [[ "$GRUB_INSTALL" == 1 ]]; then
  [[ -d /sys/firmware/efi ]] || die "not booted in UEFI mode; run grub-install for BIOS yourself"
  ESP=""
  for d in /boot/efi /boot; do
    if mountpoint -q "$d" && [[ "$(findmnt -rno FSTYPE "$d")" == vfat ]]; then ESP="$d"; break; fi
  done
  [[ -n "$ESP" ]] || die "no mounted vfat ESP at /boot/efi or /boot"
  grub-install --target=x86_64-efi --efi-directory="$ESP" --bootloader-id=GRUB
fi

if grep -qE '^#?[[:space:]]*GRUB_DISABLE_OS_PROBER=' /etc/default/grub; then
  sed -i -E 's|^#?[[:space:]]*GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|' /etc/default/grub
else
  echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
fi

if [[ -d /boot/grub ]] || [[ "$GRUB_INSTALL" == 1 ]]; then
  grub-mkconfig -o /boot/grub/grub.cfg
  grep -q 'os-prober' /boot/grub/grub.cfg || true
else
  warn "GRUB is not installed yet. Install it once, then regenerate:"
  warn "  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB"
  warn "  grub-mkconfig -o /boot/grub/grub.cfg"
fi

# ----------------------------------------------------------------- NVIDIA ---
if (( HAS_NVIDIA )); then
  log "Configuring NVIDIA"
  cat > /etc/modprobe.d/nvidia.conf <<'EOF'
options nvidia_drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
blacklist nouveau
options nouveau modeset=0
EOF
  mkdir -p /etc/mkinitcpio.conf.d /etc/pacman.d/hooks
  cat > /etc/mkinitcpio.conf.d/nvidia.conf <<'EOF'
MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
EOF
  cat > /etc/pacman.d/hooks/nvidia-initramfs.hook <<'EOF'
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=nvidia-open
Target=nvidia-open-dkms
Target=nvidia-utils

[Action]
Description=Rebuilding initramfs after NVIDIA driver change
Depends=mkinitcpio
When=PostTransaction
Exec=/usr/bin/mkinitcpio -P
EOF
  mkinitcpio -P
  # needed because of NVreg_PreserveVideoMemoryAllocations=1 (suspend/resume)
  systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service \
    || warn "could not enable nvidia suspend/resume units"
fi

# -------------------------------------------------------------------- ASUS ---
if (( IS_ASUS )); then
  log "ASUS laptop detected: enabling asusd"
  # asusd is also started on demand by udev/D-Bus; enabling may warn about [Install].
  systemctl enable asusd.service 2>/dev/null || warn "asusd.service has no [Install] section (starts on demand)"
  (( SYSTEMD_UP )) && { systemctl start asusd.service || warn "asusd did not start (check journalctl -u asusd)"; }
fi

# -------------------------------------------------- network / audio / power --
log "Network, Bluetooth, power"
if [[ -n "$REGDOM" && -f /etc/conf.d/wireless-regdom ]]; then
  sed -i -E "s|^#(WIRELESS_REGDOM=\"$REGDOM\")|\1|" /etc/conf.d/wireless-regdom
fi
enable_unit NetworkManager.service bluetooth.service power-profiles-daemon.service
systemctl enable rtkit-daemon.service 2>/dev/null || true   # also D-Bus activated

if [[ "$AUDIO_NO_POWERSAVE" == 1 ]]; then
  cat > /etc/modprobe.d/audio-powersave.conf <<'EOF'
options snd_hda_intel power_save=0 power_save_controller=N
EOF
fi

# brightnessctl writes via udev rules that grant the 'video' group access;
# ddcutil (external monitor brightness) needs /dev/i2c-* (i2c-dev, group i2c)
usermod -aG video,i2c "$TARGET_USER"
echo i2c-dev > /etc/modules-load.d/i2c-dev.conf

if [[ "$DISPLAY_MANAGER" == sddm ]]; then
  systemctl enable sddm.service
fi

# ------------------------------------------------ mango + mangobar (user) ---
log "Writing mango and mangobar config for $TARGET_USER"
as_user() { runuser -u "$TARGET_USER" -- "$@"; }
as_user mkdir -p "$USER_HOME/.config/mango" "$USER_HOME/.config/mangobar"

MANGO_CFG="$USER_HOME/.config/mango/config.conf"
if [[ ! -f "$MANGO_CFG" ]]; then
  as_user cp /etc/mango/config.conf "$MANGO_CFG"
  # default config launches rofi; fuzzel is the Wayland-native launcher installed here
  as_user sed -i 's|spawn,rofi -show drun|spawn,fuzzel|' "$MANGO_CFG"
fi
if ! grep -q 'post-install autostart' "$MANGO_CFG"; then
  cat >> "$MANGO_CFG" <<'EOF'

# >>> post-install autostart >>>
exec_once=dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec_once=/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
exec_once=mako
exec_once=swaybg -c 1e1e2e
exec_once=mangobar

# Hybrid NVIDIA laptops: if the compositor picks the wrong GPU, pin the iGPU
# (find the right card with: ls -l /dev/dri/by-path)
# env=WLR_DRM_DEVICES,/dev/dri/card0
# NVIDIA video decode in browsers (dGPU-only setups):
# env=LIBVA_DRIVER_NAME,nvidia
# <<< post-install autostart <<<
EOF
  chown "$TARGET_USER": "$MANGO_CFG"
fi

BAR_CFG="$USER_HOME/.config/mangobar/config.jsonc"
if [[ ! -f "$BAR_CFG" ]]; then
  cat > "$BAR_CFG" <<'EOF'
// mangobar config (JSONC). Module names/keys follow upstream's example config.
{
    "layer": "top",
    "height": 30,
    "modules-left": ["workspaces", "layout", "window"],
    "modules-center": [],
    "modules-right": ["tray", "network", "cpu", "memory", "pulseaudio", "backlight", "battery", "clock#date", "clock#time"],

    "workspaces": { "hide-empty": true, "on-click": "activate", "on-click-right": "toggle" },
    "layout":     { "format": "{}" },
    "window":     { "format": "{}" },
    "network": {
        "format": "{icon} {ifname}",
        "format-wifi": "{signal} {ssid}",
        "format-disconnected": "{icon}",
        "icon-wifi": "󰖩", "icon-ethernet": "󰈀", "icon-disconnected": "󰖪",
        "signal-icons": ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    },
    "cpu":    { "format": " {load}%" },
    "memory": { "format": " {}%" },
    "pulseaudio": {
        "format": "{icon} {volume}% {bt}",
        "format-muted": "󰝟 {volume}% {bt}",
        "icons": ["󰝟", "󰕿", "󰕾"],
        "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        "on-scroll-up": "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 2%+",
        "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"
    },
    "backlight": {
        "format": "{icon} {percent}%",
        "icons": ["󰃚", "󰃛", "󰃜", "󰃝", "󰃞", "󰃟"],
        "on-scroll-up": "brightnessctl set 5%+",
        "on-scroll-down": "brightnessctl set 5%-"
    },
    "battery": {
        "format": "{icon} {percent}% {ac}",
        "icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    },
    "clock#date": { "format": " {:L%b%d·%A}" },
    "clock#time": { "format": " {:L%H:%M}" },
    "tray": { "icon-size": 20, "spacing": 10 }
}
EOF
  chown "$TARGET_USER": "$BAR_CFG"
fi

BAR_CSS="$USER_HOME/.config/mangobar/style.css"
if [[ ! -f "$BAR_CSS" ]]; then
  cat > "$BAR_CSS" <<'EOF'
/* Minimal mangobar style. Full reference: style.css.example in github.com/mangowm/mangobar */
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 15px;
    font-weight: bold;
    color: #ebdbb2;
    background-color: #504945;
    padding: 0px 10px;
    margin: 5px 1px;
    border-radius: 100px;
}
#bar { background: none; margin: 5px 10px; }
#tags { padding: 0px 13px; margin: 0px 2px; }
#tags.active { background-color: #83a598; color: #1b1a1a; }
#tags.occupied { background-color: #504945; color: #ebdbb2; }
EOF
  chown "$TARGET_USER": "$BAR_CSS"
fi

# --------------------------------------------------------------------- done --
cat <<EOF

Done. Reboot, then pick "Mango" in the login screen (or run 'mango' from a tty).

Checks after reboot:
  nvidia-smi                      driver loaded
  cat /sys/module/nvidia_drm/parameters/modeset      -> Y
  powerprofilesctl                power profiles
  wpctl status                    audio devices
  nmcli device                    network
  asusctl -s                      (ASUS) daemon reachable
  sudo os-prober                  other OSes visible to GRUB

Notes:
  * Run 'systemctl --user enable --now asusd-user.service' as $TARGET_USER if you use per-user Aura effects.
  * Group change (video) applies after you log out/in.
EOF
