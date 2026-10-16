#!/bin/sh
# Caffeine: while on, idle management is paused, so the machine never blanks,
# locks or suspends. It is only a flag that scripts/idle.sh watches.
#   show    the bar's coffee-cup glyph (full cup = on, slashed cup = off)
#   toggle  turn it on or off
set -eu

flag="${XDG_RUNTIME_DIR:-/tmp}/caffeine"
idle="$(dirname "$0")/idle.sh"

case "${1:-show}" in
show)
	if [ -e "$flag" ]; then printf '\U000F0176\n'; else printf '\U000F0FAA\n'; fi
	;;
toggle)
	if [ -e "$flag" ]; then rm -f "$flag"; else : >"$flag"; fi
	"$idle" refresh >/dev/null 2>&1
	pkill -RTMIN+9 -x mangobar 2>/dev/null || true
	;;
*)
	echo "usage: ${0##*/} show|toggle" >&2
	exit 2
	;;
esac
