#!/bin/sh
# Region screenshot: slurp to select, grim saves it, satty annotates and copies.
set -eu

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
out="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

# Freeze the screen while selecting, so the region matches what you see.
still -c 'slurp | grim -g- -' > "$out" || true
[ -s "$out" ] || { rm -f "$out"; exit 0; }
notify-send -a screenshot -i "$out" "Screenshot saved" "$out" || true
exec satty --filename "$out" --fullscreen current-screen \
	--copy-command wl-copy --actions-on-enter save-to-clipboard --early-exit copy
