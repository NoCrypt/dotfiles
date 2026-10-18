#!/bin/sh
# Power-aware idle management for mango.
#   AC:      screen off after AC_SCREEN s idle (no lock, no suspend)
#   Battery: screen off after BAT_SCREEN s, lock after BAT_LOCK s, suspend after SUSPEND s
#   Locked:  screen off after LOCKED_SCREEN s (battery keeps the suspend timeout)
# All timeouts count seconds since the LAST INPUT, not since the state began.
# Fullscreen windows (and apps that hold an idle inhibitor) stay unlocked.
# Caffeine (scripts/caffeine.sh) stops idle management entirely while its flag
# exists. The AC adapter and lock state are polled; `refresh` wakes the running
# daemon, or starts one if it died, so idle management always comes back. Edit
# the numbers below.
set -eu

AC_SCREEN=600
BAT_SCREEN=300
BAT_LOCK=2400
SUSPEND=3600
LOCKED_SCREEN=10
POLL=3

run="${XDG_RUNTIME_DIR:-/tmp}"
flag="$run/caffeine"
pidfile="$run/idle.pid"

die() {
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -a idle "Idle management failed" "$1"
	fi
	printf '%s: %s\n' "${0##*/}" "$1" >&2
	exit 1
}

# alive: a daemon is running (the pid in the pidfile still exists)
alive() {
	[ -r "$pidfile" ] || return 1
	read -r pid < "$pidfile" || return 1
	case "$pid" in '' | *[!0-9]*) return 1 ;; esac
	kill -0 "$pid" 2>/dev/null
}

screen() {  # --off | --on
	wlopm "$1" '*'
}

# on battery unless some AC adapter reports online (no forks)
on_ac() {
	for f in /sys/class/power_supply/A*/online; do
		[ -r "$f" ] || continue
		read -r v < "$f" || continue
		[ "$v" = 1 ] && return 0
	done
	return 1
}

# sets $now: caffeine wins, then a locked session, then the AC/battery rules
state() {
	if [ -e "$flag" ]; then now=caffeine
	elif pgrep -x swaylock >/dev/null 2>&1; then
		if on_ac; then now=locked-ac; else now=locked-bat; fi
	elif on_ac; then now=ac
	else now=battery
	fi
}

stop_idle() {
	if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; fi
	pid=''
}

apply() {  # $1 = state
	stop_idle
	off="$0 screen --off"; on="$0 screen --on"
	case "$1" in
	caffeine) return 0 ;;   # no idle manager at all
	locked-ac)  set -- timeout "$LOCKED_SCREEN" "$off" resume "$on" ;;
	locked-bat) set -- timeout "$LOCKED_SCREEN" "$off" resume "$on" \
			timeout "$SUSPEND" 'systemctl suspend' ;;
	ac)         set -- timeout "$AC_SCREEN" "$off" resume "$on" ;;
	battery)    set -- timeout "$BAT_SCREEN" "$off" resume "$on" \
			timeout "$BAT_LOCK" 'swaylock -f -c 000000' \
			timeout "$SUSPEND" 'systemctl suspend' ;;
	esac
	swayidle -w "$@" 7>&- &
	pid=$!
}

for t in setsid swayidle wlopm pgrep flock systemctl; do
	command -v "$t" >/dev/null 2>&1 || die "missing $t"
done

case "${1:-}" in
screen) screen "${2:?screen needs --off or --on}"; exit 0 ;;
refresh)  # wake the daemon; start one if it is gone (crash, old session)
	if alive; then
		kill -USR1 "$pid" 2>/dev/null || true
	else
		setsid "$0" </dev/null >/dev/null 2>&1 &
	fi
	exit 0
	;;
esac

# single instance: a second daemon would fight over swayidle
exec 7>"$run/idle.lock"
flock -w 2 7 || exit 0
pkill -x swayidle 2>/dev/null || true   # clear strays from older versions

pid=''
cur=''
echo $$ > "$pidfile"
trap 'stop_idle; rm -f "$pidfile"' EXIT
trap 'exit 0' TERM INT HUP
trap : USR1

while :; do
	# the compositor is gone (crash/logout): don't linger as an orphan
	[ -S "$run/${WAYLAND_DISPLAY:-wayland-0}" ] || exit 0
	state
	# re-apply on a state change, or if swayidle died on its own
	if [ "$now" != "$cur" ] ||
		{ [ "$now" != caffeine ] && ! kill -0 "$pid" 2>/dev/null; }; then
		cur=$now
		apply "$now"
	fi
	sleep "$POLL" 7>&- & nap=$!
	wait "$nap" || true          # interrupted early by USR1
	kill "$nap" 2>/dev/null || true
done
