#!/bin/sh
# Power-profile switcher for Super+P. Cycles quiet -> balanced -> performance
# through power-profiles-daemon (asusd follows ppd) and shows the new profile
# in a swayosd OSD.
#   next   switch to the next profile and show it (default)
#   show   show the current profile without switching
# The OSD is skipped when swayosd-client or swayosd-server is unavailable.
set -eu

osd() {  # $1 = message, $2 = icon
	command -v swayosd-client >/dev/null 2>&1 || return 0
	pgrep -x swayosd-server >/dev/null 2>&1 || return 0
	swayosd-client --custom-message "$1" --custom-icon "$2" -d 1500 >/dev/null 2>&1 || true
}

current() {  # prints power-saver|balanced|performance
	if command -v powerprofilesctl >/dev/null 2>&1; then
		powerprofilesctl get 2>/dev/null && return 0
	fi
	asusctl profile get 2>/dev/null |
		sed -n 's/^Active profile: *//p' | tr '[:upper:]' '[:lower:]'
}

next_profile() {  # $1 = current profile, prints the one after it
	case "$1" in
	power-saver | quiet) echo balanced ;;
	balanced) echo performance ;;
	performance) echo power-saver ;;
	*) echo balanced ;;
	esac
}

describe() {  # $1 = profile id; sets label and icon
	case "$1" in
	performance) label='Performance'; icon='power-profile-performance-symbolic' ;;
	balanced) label='Balanced'; icon='power-profile-balanced-symbolic' ;;
	power-saver | quiet) label='Quiet'; icon='power-profile-power-saver-symbolic' ;;
	*) label="${1:-Unknown}"; icon='power-profile-balanced-symbolic' ;;
	esac
}

case "${1:-next}" in
next)
	if command -v powerprofilesctl >/dev/null 2>&1; then
		if powerprofilesctl set "$(next_profile "$(current)")" >/dev/null 2>&1; then
			ok=1
		else
			ok=''
		fi
	elif command -v asusctl >/dev/null 2>&1; then
		if asusctl profile next >/dev/null 2>&1; then
			ok=1
		else
			ok=''
		fi
	else
		osd 'Unavailable' 'dialog-error-symbolic'
		echo "${0##*/}: neither powerprofilesctl nor asusctl is installed" >&2
		exit 1
	fi
	;;
show) ok=1 ;;
*)
	echo "usage: ${0##*/} next|show" >&2
	exit 2
	;;
esac

if [ -z "${ok:-}" ]; then
	osd 'Switch failed' 'dialog-error-symbolic'
	echo "${0##*/}: failed to switch power profile" >&2
	exit 1
fi

describe "$(current)"
osd "$label" "$icon"
