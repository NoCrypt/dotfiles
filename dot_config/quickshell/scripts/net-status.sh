#!/bin/sh
# Prints: ifname|kind|ssid|dbm|rx_bytes|tx_bytes   (empty ifname = no default route)
dev=$(ip -o route show default 2>/dev/null | awk '{ for (i = 1; i < NF; i++) if ($i == "dev") { print $(i + 1); exit } }')
if [ -z "$dev" ]; then echo "||||0|0"; exit 0; fi

kind=other
if [ -d "/sys/class/net/$dev/wireless" ]; then
	kind=wifi
elif [ "$(cat "/sys/class/net/$dev/type" 2>/dev/null)" = 1 ]; then
	kind=ethernet
fi

ssid=''; dbm=''
if [ "$kind" = wifi ] && command -v iw >/dev/null 2>&1; then
	link=$(iw dev "$dev" link 2>/dev/null)
	ssid=$(printf '%s\n' "$link" | sed -n 's/^[[:space:]]*SSID: //p' | head -n 1)
	dbm=$(printf '%s\n' "$link" | sed -n 's/^[[:space:]]*signal: \(-\{0,1\}[0-9]*\).*/\1/p' | head -n 1)
fi

rx=$(cat "/sys/class/net/$dev/statistics/rx_bytes" 2>/dev/null || echo 0)
tx=$(cat "/sys/class/net/$dev/statistics/tx_bytes" 2>/dev/null || echo 0)
printf '%s|%s|%s|%s|%s|%s\n' "$dev" "$kind" "$ssid" "$dbm" "$rx" "$tx"
