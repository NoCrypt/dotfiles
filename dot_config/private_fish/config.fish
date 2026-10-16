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
