if [[ $(command_exists kubectl) == true ]]; then
  source <(kubectl completion zsh)
fi

