#!/bin/sh
# Left-click handler for screenshot notifications: open the saved file in satty.
set -eu
id=${1:?usage: notif-open.sh <notification-id>}
path=$(makoctl list -j |
	jq -r --argjson id "$id" '.[] | select(.id == $id) | .body // empty')
[ -n "$path" ] && [ -f "$path" ] || exit 0
makoctl dismiss -n "$id" || true
exec satty --filename "$path" --fullscreen current-screen \
	--copy-command wl-copy --actions-on-enter save-to-clipboard --early-exit copy
