if [[ ! $(command_exists fd) == true ]]; then
  echo_red "fd is not installed, see: https://github.com/sharkdp/fd or download from https://github.com/sharkdp/fd/releases and cp it to /usr/local/bin"
fi

