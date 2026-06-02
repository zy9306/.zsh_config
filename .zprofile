# -*- mode: sh -*-

# Login-shell environment setup.
export ZDOTDIR="${ZDOTDIR:-$HOME/.zsh_config}"

if [[ -d /opt/homebrew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
  export HOMEBREW_REPOSITORY="/opt/homebrew"

  typeset -U path PATH fpath FPATH
  path=("$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin" $path)
  fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)

  [[ -n ${MANPATH-} ]] && export MANPATH=":${MANPATH#:}"
  export INFOPATH="$HOMEBREW_PREFIX/share/info:${INFOPATH:-}"
fi

if [[ -r "$HOME/.orbstack/shell/init.zsh" ]]; then
  source "$HOME/.orbstack/shell/init.zsh"
fi
