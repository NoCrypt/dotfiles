#!/bin/sh
# Toggle wlsunset (night light) for the current session.
set -u

if ! command -v wlsunset >/dev/null 2>&1; then
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a nightlight "Night light failed" "wlsunset is not installed"
	exit 1
fi

if pgrep -x wlsunset >/dev/null; then
	pkill -x wlsunset
else
	setsid wlsunset -T 3501 -t 3500 >/dev/null 2>&1 &
fi
