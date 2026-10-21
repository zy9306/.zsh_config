if command_exists eza; then
	alias ls="eza -h --group --group-directories-first --color=always --git --time-style long-iso --ignore-glob='.DS_Store'"
fi

alias ll='ls -al'
alias la='ls -a'
alias l='ls -l'
