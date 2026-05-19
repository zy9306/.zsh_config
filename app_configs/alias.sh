alias oc="opencode"
alias cx="codex"

alias fd='fd --hidden --follow --no-ignore-vcs'

alias y='yazi'

alias gp="git push origin `git branch --show-current`"

function Y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}
