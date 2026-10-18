#!/bin/sh
# Super+Q: minimize apps that have a tray icon; close everything else.
# Tray apps are detected via StatusNotifierWatcher (PID match), so new ones
# work without editing this script.
set -u

command -v mmsg >/dev/null 2>&1 &&
	command -v jq >/dev/null 2>&1 &&
	command -v busctl >/dev/null 2>&1 || exit 0

json=$(mmsg get focusing-client 2>/dev/null) || exit 0
id=$(printf '%s' "$json" | jq -r '.id // empty' 2>/dev/null)
pid=$(printf '%s' "$json" | jq -r '.pid // empty' 2>/dev/null)
app=$(printf '%s' "$json" | jq -r '.appid // empty' 2>/dev/null)
[ -n "$id" ] || exit 0

tray=0
# Fallbacks for apps whose tray lives in a helper process.
case "$app" in
vesktop | com.ayugram.desktop | org.localsend.localsend_app) tray=1 ;;
esac

if [ "$tray" -eq 0 ] && [ -n "$pid" ]; then
	items=$(busctl --user --json=short get-property \
		org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
		org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems 2>/dev/null |
		jq -r '.data[]' 2>/dev/null | cut -d/ -f1 | sort -u)
	for name in $items; do
		owner=$(busctl --user status "$name" 2>/dev/null |
			awk -F= '/^PID=/{print $2; exit}')
		if [ "$owner" = "$pid" ]; then
			tray=1
			break
		fi
	done
fi

if [ "$tray" -eq 1 ]; then
	mmsg dispatch minimized client,"$id" >/dev/null 2>&1
else
	mmsg dispatch killclient client,"$id" >/dev/null 2>&1
fi
