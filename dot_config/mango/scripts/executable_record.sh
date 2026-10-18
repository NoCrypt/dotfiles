#!/bin/sh
# Screen recorder: record.sh [toggle|start|stop|status]
# Records the first monitor to ~/video; the bar module polls "status".
set -eu

dir="${XDG_VIDEOS_DIR:-$HOME/video}"
state="${XDG_RUNTIME_DIR:-/tmp}/record"
pidfile="$state/pid"
lockfile="$state/lock"
mkdir -p "$state"

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
	command -v notify-send >/dev/null 2>&1 || return 0
	# explicit timeout: a success notice must never stay stuck on screen
	notify-send -t 4000 -a record \
		-i /usr/share/icons/AdwaitaLegacy/48x48/legacy/camera-video.png \
		"$1" "${2:-}" || true
}

start() {
	if recording; then
		refresh
		return 0
	fi
	for t in gpu-screen-recorder setsid; do
		if ! command -v "$t" >/dev/null 2>&1; then
			notify "Recording failed" "$t is not installed"
			return 1
		fi
	done
	mkdir -p "$dir" || {
		notify "Recording failed" "cannot create $dir"
		return 1
	}
	rm -f "$pidfile"
	out="$dir/$(date +%Y-%m-%d_%H-%M-%S).mp4"
	setsid gpu-screen-recorder -w screen -f 60 -a default_output -o "$out" \
		>"$state/log" 2>&1 8>&- &
	rpid=$!
	printf '%s\n' "$rpid" > "$pidfile"
	sleep 0.3
	if ! kill -0 "$rpid" 2>/dev/null; then
		rm -f "$pidfile"
		notify "Recording failed" "$(tail -n 1 "$state/log" 2>/dev/null || true)"
		refresh
		return 1
	fi
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
		if kill -0 "$pid" 2>/dev/null; then
			kill -TERM "$pid" 2>/dev/null || true
			i=0
			while kill -0 "$pid" 2>/dev/null && [ "$i" -lt 20 ]; do
				sleep 0.1
				i=$((i + 1))
			done
		fi
		if kill -0 "$pid" 2>/dev/null; then
			# keep the pidfile: status must not lie and the next stop retries
			notify "Recording still running" "PID $pid did not stop"
			refresh
			return 1
		fi
	fi
	rm -f "$pidfile"
	notify "Recording stopped" "$dir"
	refresh
}

case "${1:-toggle}" in
status)
	if recording; then printf '󰨜\n'; fi
	exit 0
	;;
esac

# one start/stop at a time; a second press while one runs is dropped
if ! command -v flock >/dev/null 2>&1; then
	notify "Recording failed" "flock is not installed"
	exit 1
fi
exec 8>>"$lockfile"
flock -n 8 || exit 0

case "${1:-toggle}" in
start) start ;;
stop) stop ;;
toggle)
	if recording; then stop; else start; fi
	;;
*)
	echo "usage: ${0##*/} toggle|start|stop|status" >&2
	exit 2
	;;
esac
