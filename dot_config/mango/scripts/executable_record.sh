#!/bin/sh
# Screen recorder: record.sh [toggle|start|stop|status]
# Records the first monitor to ~/video; the bar module polls "status".
set -eu

dir="${XDG_VIDEOS_DIR:-$HOME/video}"
state="${XDG_RUNTIME_DIR:-/tmp}/record"
pidfile="$state/pid"
mkdir -p "$dir" "$state"

recording() {
	[ -r "$pidfile" ] || return 1
	pid=$(cat "$pidfile") || return 1
	case "$pid" in '' | *[!0-9]*) return 1 ;; esac
	[ -r "/proc/$pid/comm" ] || return 1
	case "$(cat "/proc/$pid/comm")" in gpu-screen-re*) return 0 ;; esac
	return 1
}

refresh() {
	pkill -RTMIN+8 -x mangobar 2>/dev/null || true
}

notify() {
	notify-send -a record -i /usr/share/icons/AdwaitaLegacy/48x48/legacy/camera-video.png \
		"$1" "${2:-}" || true
}

start() {
	if recording; then
		refresh
		return 0
	fi
	rm -f "$pidfile"
	out="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
	setsid gpu-screen-recorder -w screen -f 60 -a default_output -o "$out" \
		>"$state/log" 2>&1 &
	printf '%s\n' "$!" > "$pidfile"
	notify "Recording started" "$out"
	refresh
}

stop() {
	if recording; then
		kill -INT "$pid" 2>/dev/null || true
		i=0
		while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 50 ]; do
			sleep 0.1
			i=$((i + 1))
		done
		kill -TERM "$pid" 2>/dev/null || true
	fi
	rm -f "$pidfile"
	notify "Recording stopped" "$dir"
	refresh
}

case "${1:-toggle}" in
start) start ;;
stop) stop ;;
toggle)
	if recording; then stop; else start; fi
	;;
status) recording && printf '󰨜\n' || true ;;
*)
	echo "usage: ${0##*/} toggle|start|stop|status" >&2
	exit 2
	;;
esac
