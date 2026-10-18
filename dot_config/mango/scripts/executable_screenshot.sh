#!/bin/sh
# Region screenshot: slurp to select, grim saves it, satty annotates and copies.
set -eu

for t in still slurp grim satty wl-copy; do
	if ! command -v "$t" >/dev/null 2>&1; then
		command -v notify-send >/dev/null 2>&1 &&
			notify-send -a screenshot "Screenshot failed" "$t is not installed"
		exit 1
	fi
done

dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
out="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

# Freeze the screen while selecting, so the region matches what you see.
still -c 'slurp | grim -g- -' > "$out" || true
[ -s "$out" ] || { rm -f "$out"; exit 0; }
notify-send -a screenshot -i "$out" "Screenshot saved" "$out" || true
exec satty --filename "$out" --fullscreen current-screen \
	--copy-command wl-copy --actions-on-enter save-to-clipboard --early-exit copy
