# -*- mode: sh -*-

# Login-shell environment setup.
export ZDOTDIR="${ZDOTDIR:-$HOME/.zsh_config}"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

if [[ -r "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh"
fi
