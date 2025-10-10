if [[ $(command_exists exa) == false ]]; then
  echo_red "exa is not installed see: https://github.com/ogham/exa/releases"
  ls=ls
  if [[ $(uname -s) == 'Darwin' ]]; then
    if ! command="$(type -p "gls")" || [[ -z $command ]]; then
      echo_red "gls is not installed, try brew install coreutils"
    else
      ls=gls
    fi
  fi
else
  ls=exa
fi

ls="$ls -h --group --group-directories-first --color=always"

if [[ $(command_exists exa) == true ]]; then
  alias ls="$ls --git --time-style long-iso"
  alias lg="ls -alG" # -G: grid
else
  alias ls=$ls
fi

alias ll='ls -al'
alias la='ls -a'
alias l='ls -l'

