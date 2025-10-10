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

