#!/bin/sh
# Left-click handler for screenshot notifications: open the saved file in imv.
set -eu
id=${1:?usage: notif-open.sh <notification-id>}
path=$(makoctl list -j |
	jq -r --argjson id "$id" '.[] | select(.id == $id) | .body // empty')
[ -n "$path" ] && [ -f "$path" ] || exit 0
makoctl dismiss -n "$id" || true
exec imv "$path"
