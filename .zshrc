# -*- mode: sh -*-

export ZSH_PLUGINS_DIR="$HOME/.zsh_config/plugins"

source $ZDOTDIR/.shutils.sh

source $ZDOTDIR/app_configs/paths.sh

export LC_CTYPE="zh_CN.UTF-8"

autoload -Uz compinit && compinit -d "$ZDOTDIR/.zcompdump"

# HISTORY START
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt BANG_HIST
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt HIST_BEEP
# HISTORY END

if command_exists mise; then
  eval "$(mise activate zsh)"
else
  echo_red "!!! mise is not installed"
fi

# pure theme
if ! command_exists starship; then
  source $ZSH_PLUGINS_DIR/zsh-async/async.zsh
  fpath+=($ZSH_PLUGINS_DIR/pure)
  autoload -Uz promptinit && promptinit
  prompt -s pure
fi

# enhancd START
source $ZSH_PLUGINS_DIR/enhancd/init.sh
export ENHANCD_AWK=awk
if command_exists fzf; then
  ENHANCD_FILTER=fzf:fzy:peco:non-existing-filter
  export ENHANCD_FILTER
fi
# enhancd END

if [ -f $HOME/.my_env ]; then
  source $HOME/.my_env
fi

# make sure source .app_configs at the end
source $ZDOTDIR/app_configs/load.sh

if command_exists starship; then
  export STARSHIP_CONFIG="$HOME/.starship"
  eval "$(starship init zsh)"
else
  echo_red "!!! starship is not installed see: https://github.com/starship/starship"
fi

source $ZSH_PLUGINS_DIR/z/z.sh
source $ZSH_PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh
source $ZSH_PLUGINS_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

bindkey -e
