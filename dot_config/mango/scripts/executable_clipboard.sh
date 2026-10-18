#!/bin/sh
# Clipboard history picker: cliphist entries through fuzzel, selected entry to wl-copy.
set -eu

sel=$(cliphist list | fuzzel --dmenu --prompt '  ') || exit 0
[ -n "$sel" ] || exit 0
printf '%s' "$sel" | cliphist decode | wl-copy
