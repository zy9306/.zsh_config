if [[ $(command_exists eza) == true ]]; then
  alias ls="eza -h --group --group-directories-first --color=always --git --time-style long-iso"
fi

alias ll='ls -al'
alias la='ls -a'
alias l='ls -l'

