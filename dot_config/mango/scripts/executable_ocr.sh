#!/bin/sh
# OCR the focused window into the clipboard (right-click on the bar title).
set -eu

command -v tesseract >/dev/null 2>&1 || exit 0
geom=$(mmsg get focusing-client | jq -r '"\(.x),\(.y) \(.width)x\(.height)"')
[ -n "$geom" ] || exit 0

tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT
grim -g "$geom" "$tmp"
tesseract "$tmp" - 2>/dev/null | wl-copy
