# set npm: npm config set prefix '~/.npm_packages'
if [ ! -d $HOME/.fnm ]; then
  mkdir -p $HOME/.fnm
fi

prepend_path "$HOME/.fnm"

if [[ $(command_exists fnm) == true ]]; then
  eval "$(fnm env)"
fi

# npm config set prefix '~/.npm_packages'
if [[ $(command_exists npm) == true ]]; then
  prepend_path "$HOME/.npm_packages/bin"
fi
