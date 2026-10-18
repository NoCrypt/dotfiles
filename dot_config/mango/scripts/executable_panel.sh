#!/bin/sh
# Toggle the built-in panel off/on; the external monitor keeps its layout.
set -eu

die() {
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a panel "Panel toggle failed" "$1"
	exit 1
}

for t in wlr-randr jq; do
	command -v "$t" >/dev/null 2>&1 || die "$t is not installed"
done

enabled=$(wlr-randr --json | jq -r '.[] | select(.name == "eDP-1") | .enabled') ||
	die "wlr-randr could not read outputs"

case "$enabled" in
true) wlr-randr --output eDP-1 --off ;;
false) wlr-randr --output eDP-1 --on ;;
*) die "eDP-1 not found" ;;
esac
