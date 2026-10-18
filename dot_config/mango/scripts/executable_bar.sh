#!/bin/sh
# Toggle mangobar.
set -u

if ! command -v mangobar >/dev/null 2>&1; then
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a bar "Bar toggle failed" "mangobar is not installed"
	exit 1
fi

if pgrep -x mangobar >/dev/null; then
	pkill -x mangobar
else
	setsid mangobar >/dev/null 2>&1 &
fi
