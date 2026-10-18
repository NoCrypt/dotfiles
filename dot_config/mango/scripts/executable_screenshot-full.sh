#!/bin/sh
# Full screenshot of the monitor under the pointer; saved and copied.
set -eu

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
out="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

mon=$(mmsg get cursorpos | jq -r .monitor)
grim -o "$mon" "$out"
wl-copy < "$out"
notify-send -a screenshot -i "$out" "Screenshot saved" "$out" || true

if [ "${1:-}" = satty ]; then
	exec satty --filename "$out" --fullscreen current-screen \
		--copy-command wl-copy --actions-on-enter save-to-clipboard --early-exit copy
fi
