# -*- mode: sh -*-

# bat config START
if [[ $(command_exists bat) == true ]]; then
  export BAT_THEME="1337" # use GitHub for white theme, zenburn for black theme.
  alias cat="bat -p --wrap character"
else
  echo_red "bat is not installed, see: https://github.com/sharkdp/bat"
fi
# bat config END

if [[ ! $(command_exists fd) == true ]]; then
  echo_red "fd is not installed, see: https://github.com/sharkdp/fd or download from https://github.com/sharkdp/fd/releases and cp it to /usr/local/bin"
fi

# fzf config START
if [[ $(command_exists fzf) == true ]]; then
  export FZF_DEFAULT_OPTS="--bind ctrl-f:page-down,ctrl-b:page-up --height=50% --no-sort --layout=reverse --color=light"

  if [[ $(command_exists fd) == true ]]; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  else
    echo_red ".app: fzf may need fd for FZF_DEFAULT_COMMAND"
  fi

  # fhe - find history and execute
  fhe() {
    eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history 0) | fzf +s --tac | sed 's/ *[0-9]* *//')
  }
  # fh - find history but not execute
  fh() {
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history 0) | fzf +s --tac | sed 's/ *[0-9]* *//')
  }
else
  echo_red "fzf is not installed see: https://github.com/junegunn/fzf or download from https://github.com/junegunn/fzf-bin/releases and cp it to /usr/local/bin"
fi
# fzf config END

# ripgrep config START
if [[ $(command_exists rg) == false ]]; then
  echo_red "rg is not installed see: https://github.com/BurntSushi/ripgrep/releases"
else
  alias rg="rg --max-columns 250 --max-columns-preview"
fi
# ripgrep config END

# ls config START
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
# ls config END

# navi config START
if [[ $(command_exists navi) == true ]]; then
  export NAVI_PATH=$HOME/.navi-cheat
  alias nax="navi"
  if [[ $(uname -s) == "Linux" ]]; then
    alias na="navi --print | xsel -ib"
  elif [[ $(uname -s) == "Darwin" ]]; then
    alias na="navi --print | pbcopy"
  fi
else
  echo_red "navi is not installed, see: https://github.com/denisidoro/navi"
fi
# navi config END

# tldr config START
if [[ $(command_exists tldr) == true ]]; then
  mkdir -p $HOME/.tealdeer_cache
  export TEALDEER_CACHE_DIR=$HOME/.tealdeer_cache
  alias tl="tldr"
else
  echo_red "tldr is not installed, see: https://github.com/dbrgn/tealdeer"
  echo_red "run tldr --update or download https://github.com/tldr-pages/tldr to $HOME/.tealdeer_cache/tldr-master"
fi
# tldr config END

# proxychains4 config START
if [[ $(command_exists proxychains4) == true ]]; then
  alias pc="proxychains4"
  export PROXYCHAINS_CONF_FILE="$HOME/.proxychains.conf"
fi
# proxychains4 config END

# set editor
if [[ $(command_exists nvim) == true ]]; then
  export EDITOR=nvim
  alias vim="nvim"
  alias vi="nvim"
elif [[ $(command_exists vim) == true ]]; then
  export EDITOR=vim
fi

# kubectl config START
if [[ $(command_exists kubectl) == true ]]; then
  source <(kubectl completion zsh)
fi
# kubectl config END

# extra alias
alias shfmt="shfmt -i 2"
