#!/bin/sh
# Caffeine: while on, idle management is paused, so the machine never blanks,
# locks or suspends. It is only a flag that scripts/idle.sh watches.
#   show    the bar's coffee-cup glyph (full cup = on, slashed cup = off)
#   toggle  turn it on or off
set -eu

flag="${XDG_RUNTIME_DIR:-/tmp}/caffeine"

case "${1:-show}" in
show)
	# UTF-8 bytes as octal escapes: dash's printf has no \U support.
	# U+F0176 (full cup) / U+F0FAA (slashed cup)
	if [ -e "$flag" ]; then printf '\363\260\205\266\n'; else printf '\363\260\276\252\n'; fi
	;;
toggle)
	if [ -e "$flag" ]; then rm -f "$flag"; else : >"$flag"; fi
	"${0%/*}/idle.sh" refresh >/dev/null 2>&1 || true
	pkill -RTMIN+9 -x mangobar 2>/dev/null || true
	;;
*)
	echo "usage: ${0##*/} show|toggle" >&2
	exit 2
	;;
esac
