# Remove macOS Finder metadata file for current directory only.
# Skip .git and node_modules paths (and their subdirectories).
remove_local_ds_store() {
  case "$PWD/" in
  */.git | */.git/* | */node_modules | */node_modules/*)
    return 0
    ;;
  esac

  [[ -w "$PWD" ]] || return 0
  [[ -f "$PWD/.DS_Store" ]] && command rm -f -- "$PWD/.DS_Store" >/dev/null 2>&1

  return 0
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd remove_local_ds_store
remove_local_ds_store
