if command_exists fzf; then
	export FZF_DEFAULT_OPTS="--exact --bind 'ctrl-f:page-down,ctrl-b:page-up,enter:execute-silent(printf %s {} | pbcopy)+accept' --height=50% --no-sort --layout=reverse --color=light"
	export FZF_DEFAULT_COMMAND='fd --hidden --follow --no-ignore-vcs'
fi
