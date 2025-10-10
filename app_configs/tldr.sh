if [[ $(command_exists tldr) == true ]]; then
  mkdir -p $HOME/.tealdeer_cache
  export TEALDEER_CACHE_DIR=$HOME/.tealdeer_cache
  alias tl="tldr"
else
  echo_red "tldr is not installed, see: https://github.com/dbrgn/tealdeer"
  echo_red "run tldr --update or download https://github.com/tldr-pages/tldr to $HOME/.tealdeer_cache/tldr-master"
fi

