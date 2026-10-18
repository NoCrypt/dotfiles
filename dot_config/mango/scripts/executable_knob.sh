#!/bin/sh
# Volume-knob helper. Plain knob turn/press is bound straight to wpctl in
# mango's config.conf; the Ctrl and Alt variants run this script:
#   up | down   brightness of the selected screen
#   screen      select the next brightness-controllable screen
#   sink        switch the default audio output to the next sink
#   show        the bar's custom/brightness module: "icon NN%" of that screen
# The selected screen is kept for the session in $XDG_RUNTIME_DIR.
set -eu

step=2
state="${XDG_RUNTIME_DIR:-/tmp}/knob-brightness-screen"

# sets $target: "panel" = built-in panel (brightnessctl), "ddc:N" = ddcutil
get_target() {
	target=panel
	if [ -r "$state" ]; then read -r target < "$state" || target=panel; fi
	if [ -z "$target" ]; then target=panel; fi
}

screens() {
	echo panel
	if command -v ddcutil >/dev/null 2>&1; then
		ddcutil detect --brief 2>/dev/null | sed -n 's/^Display \([0-9]*\)$/ddc:\1/p'
	fi
}

# sets $cur. A ddcutil read costs as much as a write, so it is cached for 60 s.
ddc_value() {  # $1 = display number
	cache="$state-ddc$1.value"
	if [ -z "$(find "$cache" -mmin -1 2>/dev/null)" ]; then
		v="$(ddcutil --display "$1" getvcp 10 2>/dev/null | sed -n 's/.*current value = *\([0-9][0-9]*\).*/\1/p')"
		if [ -n "$v" ]; then printf '%s\n' "$v" > "$cache"; fi
	fi
	cur=''
	if [ -r "$cache" ]; then read -r cur < "$cache" || cur=''; fi
}

# Redraw the bar's brightness module; skipped if the bar has no such module
# (an unhandled RTMIN signal would kill it).
bar_refresh() {
	if grep -q '"signal": 8' "$HOME/.config/mangobar/config.jsonc" 2>/dev/null; then
		pkill -RTMIN+8 -x mangobar 2>/dev/null || true
	fi
	return 0
}

# ddcutil costs ~0.3 s per run, so turns are queued and one run at a time
# drains the queue as a single relative write. The drainer gives up its
# lock while still holding the queue lock, so a turn that lands during
# shutdown is never stranded.
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
		if [ -z "$steps" ]; then
			flock -u 8
			flock -u 9
			break
		fi
		flock -u 9
		total=0
		for s in $steps; do total=$((total + s)); done
		[ "$total" -ne 0 ] || continue
		if [ "$total" -gt 0 ]; then sign='+'; count="$total"
		else sign='-'; count="${total#-}"; fi
		ddcutil --noverify --display "$1" setvcp 10 "$sign" "$count" || break
		if [ -f "$queue.value" ]; then
			read -r v < "$queue.value" || v=0
			v=$((v + total))                      # keep the bar in step
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
	get_target
	if [ "$1" = up ]; then dir='+'; else dir='-'; fi
	if [ "$target" != panel ] && command -v ddcutil >/dev/null 2>&1; then
		ddc_turn "${target#ddc:}" "$dir$step"
	elif command -v swayosd-client >/dev/null 2>&1; then
		swayosd-client --brightness "$dir$step" --min-brightness 1
		bar_refresh
	else
		brightnessctl -q set "${step}%${dir}"
		bar_refresh
	fi
	;;
screen)
	get_target
	next_in "$target" "$(screens)" > "$state"
	bar_refresh
	;;
show)
	get_target
	if [ "$target" = panel ]; then
		mark=''
		out="$(brightnessctl -m 2>/dev/null || true)"
		IFS=, read -r _ _ cur _ max <<EOF
$out
EOF
	else
		ddc_value "${target#ddc:}"; max=100; mark='󰍹 '
	fi
	if [ -n "${cur:-}" ]; then
		pct=$(( (cur * 100 + max / 2) / max ))
		set -- 󰃚 󰃛 󰃜 󰃝 󰃞 󰃟
		shift $(( pct / 17 ))
		echo "$mark$1 $pct%"
	fi
	;;
sink)
	cur="$(pactl get-default-sink)"
	next="$(next_in "$cur" "$(pactl list short sinks | cut -f2)")"
	if [ -n "$next" ] && [ "$next" != "$cur" ]; then
		pactl set-default-sink "$next"
		pactl list short sink-inputs | while read -r id _; do
			pactl move-sink-input "$id" "$next"
		done
	fi
	;;
*)
	echo "usage: ${0##*/} up|down|screen|sink|show" >&2
	exit 2
	;;
esac
