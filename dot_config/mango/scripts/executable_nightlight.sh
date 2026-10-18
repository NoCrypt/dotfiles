#!/bin/sh
# Toggle wlsunset (night light) for the current session.
if pgrep -x wlsunset >/dev/null; then
	pkill -x wlsunset
else
	setsid wlsunset -T 3501 -t 3500 >/dev/null 2>&1 &
fi
