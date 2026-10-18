#!/bin/sh
# Toggle mangobar.
if pgrep -x mangobar >/dev/null; then
	pkill -x mangobar
else
	setsid mangobar >/dev/null 2>&1 &
fi
