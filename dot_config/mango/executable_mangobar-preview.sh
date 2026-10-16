#!/bin/sh
# Preview mangobar configs so you can pick one.
# Cycles through ~/.config/mangobar/preview/*, applying each live and restarting the bar.
#
#   Enter = next config
#   s     = save a screenshot of this one (needs grim) then continue
#   k     = keep the current config and quit
#   q     = quit and restore your original config
#
# Your original config.jsonc / style.css are backed up and restored unless you press k.
set -u

LIVE="$HOME/.config/mangobar"
PREV="$LIVE/preview"
SHOTS="$LIVE/preview-shots"
BAK="$(mktemp -d)"
KEEP=0

mkdir -p "$SHOTS"
cp -a "$LIVE/config.jsonc" "$BAK/config.jsonc" 2>/dev/null || true
cp -a "$LIVE/style.css"   "$BAK/style.css"   2>/dev/null || true

restart() {
	pkill -x mangobar 2>/dev/null || true
	sleep 0.4
	setsid mangobar >/tmp/mangobar-preview.log 2>&1 &
	sleep 1.2
}

restore() {
	[ "$KEEP" = 1 ] && return 0
	cp -a "$BAK/config.jsonc" "$LIVE/config.jsonc" 2>/dev/null || true
	cp -a "$BAK/style.css"    "$LIVE/style.css"   2>/dev/null || true
	echo
	echo "restored your original mangobar config"
	restart
}
trap restore EXIT INT TERM

total=$(ls -d "$PREV"/*/ 2>/dev/null | wc -l)
echo "Previewing $total mangobar configs. Look at the top bar after each step."
i=0
for d in "$PREV"/*/; do
	[ -f "$d/config.jsonc" ] || continue
	i=$((i + 1))
	name=$(basename "$d")
	cp "$d/config.jsonc" "$LIVE/config.jsonc"
	[ -f "$d/style.css" ] && cp "$d/style.css" "$LIVE/style.css"
	restart
	if pgrep -x mangobar >/dev/null; then
		status=""
	else
		status="  <- FAILED to start, see /tmp/mangobar-preview.log (skipping)"
	fi
	printf '\n[%d/%d] %s%s\n' "$i" "$total" "$name" "$status"
	[ -n "$status" ] && continue

	printf '  Enter=next  s=screenshot  k=keep this  q=quit > '
	read -r ans </dev/tty || ans=q
	if [ "$ans" = "s" ]; then
		if grim "$SHOTS/$name.png" 2>/dev/null; then
			echo "  saved $SHOTS/$name.png"
		else
			echo "  screenshot failed (is grim working?)"
		fi
		printf '  Enter=next  k=keep this  q=quit > '
		read -r ans </dev/tty || ans=q
	fi
	case "$ans" in
		k) KEEP=1; break ;;
		q) KEEP=0; break ;;
	esac
done

if [ "$KEEP" = 1 ]; then
	echo
	echo "kept: $name  (config.jsonc + style.css copied into $LIVE)"
fi
