#!/bin/sh
# Power-aware idle management for mango.
#   AC:      screen off after 20 min (no lock, no suspend)
#   Battery: screen off after 5 min, lock after 40 min, suspend after 1 h
# Fullscreen windows (and apps that hold an idle inhibitor) stay unlocked.
# Caffeine (scripts/caffeine.sh) stops idle management entirely while its flag
# exists. The AC adapter and the caffeine flag are polled, so both take effect
# without a relogin; `refresh` applies the current state at once.
set -eu

flag="${XDG_RUNTIME_DIR:-/tmp}/caffeine"

# turn every output off/on via wlr output power management
screen() {  # --off | --on
	wlr-randr --json | jq -r '.[].name' | while read -r o; do
		wlr-randr --output "$o" "$1" >/dev/null
	done
}

# on battery unless some AC adapter reports online
on_ac() {
	for f in /sys/class/power_supply/A*/online; do
		[ -r "$f" ] || continue
		[ "$(cat "$f")" = 1 ] && return 0
	done
	return 1
}

# what the machine should be doing right now; caffeine wins over everything
state() {
	if [ -e "$flag" ]; then
		echo caffeine
	elif on_ac; then
		echo ac
	else
		echo battery
	fi
}

apply() {  # $1 = state
	pkill -x swayidle 2>/dev/null || true
	case "$1" in
	caffeine) ;;   # leave no idle manager running at all
	ac)
		swayidle -w \
			timeout 1200 "$0 screen --off" resume "$0 screen --on" &
		;;
	battery)
		swayidle -w \
			timeout 300  "$0 screen --off" resume "$0 screen --on" \
			timeout 2400 'swaylock -f -c 000000' \
			timeout 3600 'systemctl suspend' &
		;;
	esac
}

case "${1:-}" in
	screen) screen "${2:?screen needs off or on}" ; exit 0 ;;
	refresh) apply "$(state)" ; exit 0 ;;
esac

cur=$(state)
apply "$cur"
while :; do
	sleep 15
	now=$(state)
	if [ "$now" != "$cur" ]; then
		cur=$now
		apply "$now"
	fi
done
