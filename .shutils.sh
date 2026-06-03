# -*- mode: sh -*-

SHUTILS_DIR="${ZDOTDIR:-$HOME/.zsh_config}/shutils"

source "$SHUTILS_DIR/core.sh"
source "$SHUTILS_DIR/path.sh"
source "$SHUTILS_DIR/git.sh"
source "$SHUTILS_DIR/zsh.sh"
source "$SHUTILS_DIR/tmux.sh"
source "$SHUTILS_DIR/fzf.sh"
source "$SHUTILS_DIR/backup.sh"

unset SHUTILS_DIR
