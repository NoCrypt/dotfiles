#!/bin/sh
# OCR a frozen screen region into the clipboard (right-click on the bar title).
set -eu

command -v tesseract >/dev/null 2>&1 || exit 0

tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT

still -c 'slurp | grim -g- -' >"$tmp" || true
[ -s "$tmp" ] || exit 0

text=$(tesseract "$tmp" - 2>/dev/null | tr -d '\f')
[ -n "$text" ] || exit 0

printf '%s\n' "$text" | wl-copy
