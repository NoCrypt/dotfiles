#!/bin/sh
# Clipboard history picker: cliphist entries through fuzzel, selected entry to wl-copy.
set -eu

for t in cliphist fuzzel wl-copy; do
	if ! command -v "$t" >/dev/null 2>&1; then
		command -v notify-send >/dev/null 2>&1 &&
			notify-send -a clipboard "Clipboard picker failed" "$t is not installed"
		exit 1
	fi
done

sel=$(cliphist list | fuzzel --dmenu --prompt '  ') || exit 0
[ -n "$sel" ] || exit 0
printf '%s' "$sel" | cliphist decode | wl-copy
