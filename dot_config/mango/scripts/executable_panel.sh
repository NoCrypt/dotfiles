#!/bin/sh
# Toggle the built-in panel off/on; the external monitor keeps its layout.
set -eu

if wlr-randr --json | jq -e '.[] | select(.name == "eDP-1") | .enabled' >/dev/null; then
	wlr-randr --output eDP-1 --off
else
	wlr-randr --output eDP-1 --on
fi
