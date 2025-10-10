if [[ $(command_exists proxychains4) == true ]]; then
  alias pc="proxychains4"
  export PROXYCHAINS_CONF_FILE="$HOME/.proxychains.conf"
fi

