#!/bin/sh
# Full screenshot of the monitor under the pointer; saved and copied.
set -eu

die() {
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a screenshot "Screenshot failed" "$1"
	exit 1
}

for t in mmsg jq grim wl-copy; do
	command -v "$t" >/dev/null 2>&1 || die "$t is not installed"
done
if [ "${1:-}" = satty ]; then
	command -v satty >/dev/null 2>&1 || die "satty is not installed"
fi

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
out="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

mon=$(mmsg get cursorpos | jq -r '.monitor') || die "could not read the pointer position"
case "$mon" in '' | null) die "no monitor under the pointer" ;; esac
grim -o "$mon" "$out"
wl-copy < "$out"
notify-send -a screenshot -i "$out" "Screenshot saved" "$out" || true

if [ "${1:-}" = satty ]; then
	exec satty --filename "$out" --fullscreen current-screen \
		--copy-command wl-copy --actions-on-enter save-to-clipboard --early-exit copy
fi
