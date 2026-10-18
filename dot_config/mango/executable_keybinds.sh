#!/bin/sh
# Reference of all mango keybinds. Bound to Super+/ in config.conf.
# Usage: keybinds.sh [--list]   (--list prints plain text instead of opening fuzzel)
# The comment line directly above a bind is shown as its description; a bind
# without one falls back to its raw action name.
set -u

conf="${XDG_CONFIG_HOME:-$HOME/.config}/mango/config.conf"

die() {
	command -v notify-send >/dev/null 2>&1 &&
		notify-send -a keybinds "Keybinds failed" "$1"
	exit 1
}

command -v awk >/dev/null 2>&1 || die "awk is not installed"
[ -r "$conf" ] || die "$conf not found"

list() {
	awk '
		/^[ \t]*#/ {
			desc = $0
			sub(/^[ \t]*#[ \t]*/, "", desc)
			next
		}
		/^[ \t]*$/ { desc = ""; next }
		/^[ \t]*(bind|bindc|mousebind|axisbind|gesturebind)[ \t]*=/ {
			# split on the first "=" only; the command after it may contain "="
			eq = index($0, "=")
			kind = substr($0, 1, eq - 1); gsub(/[ \t]/, "", kind)
			n = split(substr($0, eq + 1), a, ",")
			if (desc == "") {
				desc = a[3]
				for (i = 4; i <= n; i++) desc = desc "," a[i]
				sub(/,$/, "", desc)
			}
			if (desc == "") printf "%-11s %s\n", kind, a[1] "+" a[2]
			else printf "%-11s %-26s %s\n", kind, a[1] "+" a[2], desc
			desc = ""
		}
		{ desc = "" }
	' "$conf"
}

if [ "${1:-}" = "--list" ]; then
	list
else
	command -v fuzzel >/dev/null 2>&1 || die "fuzzel is not installed"
	out="$(list)"
	width="$(printf '%s\n' "$out" | awk '{ if (length > m) m = length } END { print (m ? m + 2 : 60) }')"
	printf '%s\n' "$out" | fuzzel --dmenu --lines 25 --width "$width" --prompt "keybinds> "
fi
