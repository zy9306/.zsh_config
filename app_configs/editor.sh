if [[ $(command_exists nvim) == true ]]; then
  export EDITOR=nvim
  alias vim="nvim"
  alias vi="nvim"
elif [[ $(command_exists vim) == true ]]; then
  export EDITOR=vim
fi

