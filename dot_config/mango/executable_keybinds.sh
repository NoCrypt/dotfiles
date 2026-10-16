#!/bin/sh
# Reference of all mango keybinds. Bound to Super+/ in config.conf.
# Usage: keybinds.sh [--list]   (--list prints plain text instead of opening fuzzel)
conf="${XDG_CONFIG_HOME:-$HOME/.config}/mango/config.conf"

list() {
	awk '
		/^[ \t]*#/ { next }
		/^[ \t]*(bind|bindc|mousebind|axisbind|gesturebind)[ \t]*=/ {
			# split on the first "=" only; the command after it may contain "="
			eq = index($0, "=")
			kind = substr($0, 1, eq - 1); gsub(/[ \t]/, "", kind)
			n = split(substr($0, eq + 1), a, ",")
			desc = a[3]
			for (i = 4; i <= n; i++) desc = desc "," a[i]
			sub(/,$/, "", desc)
			if (desc == "") printf "%-11s %s\n", kind, a[1] "+" a[2]
			else printf "%-11s %-24s %s\n", kind, a[1] "+" a[2], desc
		}
	' "$conf"
}

if [ "$1" = "--list" ]; then
	list
else
	out="$(list)"
	width="$(printf '%s\n' "$out" | awk '{ if (length > m) m = length } END { print (m ? m + 2 : 60) }')"
	printf '%s\n' "$out" | fuzzel --dmenu --lines 25 --width "$width" --prompt "keybinds> "
fi
