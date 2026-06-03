# 重建 zsh 补全缓存。新装命令补全后不生效、补全异常，或想刷新
# .zcompdump/.zcompdump.zwc 时使用。
zsh-rebuild-cache() {
  emulate -L zsh

  local zcompdump zcompdump_zwc

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: zsh-rebuild-cache

  Rebuild the zsh completion dump and compiled cache.
EOF
    return 0
  fi

  if [ $# -ne 0 ]; then
    echo_red_bold "Usage: zsh-rebuild-cache"
    return 1
  fi

  zcompdump="${ZDOTDIR:-$HOME/.zsh_config}/.zcompdump"
  zcompdump_zwc="${zcompdump}.zwc"

  rm -f -- "$zcompdump" "$zcompdump_zwc" || return 1
  autoload -Uz compinit
  compinit -d "$zcompdump" || return 1
  zcompile "$zcompdump" || return 1

  echo_green "Rebuilt zsh completion cache: $zcompdump"
}
