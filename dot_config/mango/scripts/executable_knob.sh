#!/bin/sh
# Volume-knob helper. Plain knob turn/press is bound straight to wpctl in
# mango's config.conf; the Ctrl and Alt variants run this script:
#   up | down   brightness of the selected screen
#   screen      select the next brightness-controllable screen
#   sink        switch the default audio output to the next sink
#   show        the bar's custom/brightness module: "icon NN%" of that screen
# The selected screen is kept for the session in $XDG_RUNTIME_DIR.
set -eu

step=5
state="${XDG_RUNTIME_DIR:-/tmp}/knob-brightness-screen"

# "panel" = built-in panel (brightnessctl), "ddc:N" = external monitor (ddcutil)
screens() {
	echo panel
	if command -v ddcutil >/dev/null 2>&1; then
		ddcutil detect --brief 2>/dev/null | sed -n 's/^Display \([0-9]*\)$/ddc:\1/p'
	fi
}

# The bar shows the selected screen's brightness; for a DDC display the value is
# cached, since a ddcutil read costs as much as a write and would hold up a turn.
ddc_value() {  # $1 = display number
	cache="$state-ddc$1.value"
	if [ ! -f "$cache" ] ||
		[ "$(( $(date +%s) - $(stat -c %Y "$cache") ))" -gt 60 ]; then
		v="$(ddcutil --display "$1" getvcp 10 2>/dev/null | sed 's/.*= *//;s/,.*//')"
		if [ -n "$v" ]; then printf '%s\n' "$v" > "$cache"; fi
	fi
	cat "$cache" 2>/dev/null || true
}

# Redraw the bar's brightness module. The guard keeps a bar whose config has no
# such module from being killed by a signal it does not handle.
bar_refresh() {
	grep -q '"signal": 8' "$HOME/.config/mangobar/config.jsonc" 2>/dev/null &&
		pkill -RTMIN+8 -x mangobar 2>/dev/null
	return 0
}

# ddcutil costs ~0.3 s per run (it re-arms its DRM watcher on every call), so a
# fast knob turn would leave a queue of writes lagging behind the hand. One run
# at a time drains the queue; turns made meanwhile only add their step to it.
ddc_turn() {  # $1 = display number, $2 = +N/-N
	queue="$state-ddc$1"
	exec 9>>"$queue"
	flock 9
	printf '%s\n' "$2" >> "$queue"
	flock -u 9
	exec 8>>"$queue.lock"
	flock -n 8 || return 0     # another run is already draining this display
	while :; do
		flock 9
		steps="$(cat "$queue")"
		: > "$queue"
		flock -u 9
		total=0
		for s in $steps; do
			case "$s" in
			+*) total=$((total + ${s#+})) ;;
			-*) total=$((total - ${s#-})) ;;
			esac
		done
		[ "$total" -ne 0 ] || break
		if [ "$total" -gt 0 ]; then sign='+'; count="$total"
		else sign='-'; count="${total#-}"; fi
		ddcutil --display "$1" setvcp 10 "$sign" "$count" || break
		if [ -f "$queue.value" ]; then
			v=$(( $(cat "$queue.value") + total ))     # keep the bar in step
			if [ "$v" -gt 100 ]; then v=100; fi
			if [ "$v" -lt 0 ]; then v=0; fi
			printf '%s\n' "$v" > "$queue.value"
		fi
		bar_refresh
	done
}

# next_in <current> <list>: the entry after <current>, wrapping to the first
next_in() {
	first=''
	found=''
	for item in $2; do
		if [ -z "$first" ]; then first="$item"; fi
		if [ -n "$found" ]; then echo "$item"; return; fi
		if [ "$item" = "$1" ]; then found=1; fi
	done
	echo "$first"
}

case "${1:-}" in
up | down)
	target="$(cat "$state" 2>/dev/null || echo panel)"
	if [ "$1" = up ]; then dir='+'; else dir='-'; fi
	if [ "$target" != panel ] && command -v ddcutil >/dev/null 2>&1; then
		ddc_turn "${target#ddc:}" "$dir$step"
	else
		brightnessctl set "${step}%${dir}"
		bar_refresh
	fi
	;;
screen)
	target="$(cat "$state" 2>/dev/null || echo panel)"
	next_in "$target" "$(screens)" > "$state"
	bar_refresh
	;;
show)
	target="$(cat "$state" 2>/dev/null || echo panel)"
	if [ "$target" = panel ]; then
		cur="$(brightnessctl get)"; max="$(brightnessctl max)"; mark=''
	else
		cur="$(ddc_value "${target#ddc:}")"; max=100; mark='󰍹 '
	fi
	if [ -n "$cur" ]; then
		pct=$(( (cur * 100 + max / 2) / max ))
		icons="$(printf '%s\n' '󰃚 󰃛 󰃜 󰃝 󰃞 󰃟' | cut -d' ' -f$(( pct / 17 + 1 )))"
		echo "$mark$icons $pct%"
	fi
	;;
sink)
	cur="$(pactl get-default-sink)"
	next="$(next_in "$cur" "$(pactl list short sinks | cut -f2)")"
	if [ -n "$next" ] && [ "$next" != "$cur" ]; then
		pactl set-default-sink "$next"
		for input in $(pactl list short sink-inputs | cut -f1); do
			pactl move-sink-input "$input" "$next"
		done
	fi
	;;
*)
	echo "usage: ${0##*/} up|down|screen|sink|show" >&2
	exit 2
	;;
esac
