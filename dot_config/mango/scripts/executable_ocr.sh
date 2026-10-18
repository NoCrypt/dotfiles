#!/bin/sh
# OCR a frozen screen region into the clipboard (right-click on the bar title).
set -eu

for t in still slurp grim tesseract wl-copy; do
	if ! command -v "$t" >/dev/null 2>&1; then
		command -v notify-send >/dev/null 2>&1 &&
			notify-send -a ocr "OCR failed" "$t is not installed"
		exit 1
	fi
done

tmp=$(mktemp --suffix=.png)
trap 'rm -f "$tmp"' EXIT

still -c 'slurp | grim -g- -' >"$tmp" || true
[ -s "$tmp" ] || exit 0

text=$(tesseract "$tmp" - 2>/dev/null | tr -d '\f')
[ -n "$text" ] || exit 0

printf '%s\n' "$text" | wl-copy
