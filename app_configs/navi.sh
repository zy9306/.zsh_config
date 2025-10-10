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

