if status is-interactive
# Commands to run in interactive sessions can go here
	fastfetch (test "$TERM_PROGRAM" = "vscode"; and echo "-l"; and echo "none")
end
set fish_greeting

bind ctrl-h backward-kill-word
bind ctrl-left backward-word
bind ctrl-right forward-word
bind ctrl-backspace backward-kill-word

alias cm="sync && sudo sysctl vm.drop_caches=3"
# usbreset: rebind the USB controller (05:00.3) that hard-locks when the phone charges off the hub.
# The kernel only reports the death in its log (no sysfs flag), so check that; -f rebinds anyway.
function usbreset
	set -l dev 0000:05:00.3
	set -l stamp $XDG_RUNTIME_DIR/xhci-reset
	set -l since
	test -f $stamp; and set since --since "@"(cat $stamp)
	set -l dead (journalctl -k -b $since --no-pager | grep -cF "xhci_hcd $dev: xHCI host controller not responding")

	if test $dead -eq 0 -a "$argv[1]" != -f
		echo "usbreset: $dev is alive, nothing to do (-f to force)"
		return 0
	end

	set -l now (date +%s) # read before the check, so a death during it is caught next run
	echo $dev | sudo tee /sys/bus/pci/drivers/xhci_hcd/unbind >/dev/null
	sleep 1
	echo $dev | sudo tee /sys/bus/pci/drivers/xhci_hcd/bind
	echo $now >$stamp
end
alias gcp="git cherry-pick"
alias glo="git log --oneline"
alias gco="git checkout"


starship init fish | source
zoxide init fish | source

function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	command rm -f -- "$tmp"
end

set -gx GPG_TTY (tty)

# uv
fish_add_path "/home/ncpt/.local/bin"

# opencode
fish_add_path /home/ncpt/.opencode/bin
