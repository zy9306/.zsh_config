if [[ $(command_exists rg) == false ]]; then
  echo_red "rg is not installed see: https://github.com/BurntSushi/ripgrep/releases"
else
  alias rg="rg --max-columns 250 --max-columns-preview"
fi

