# Remove macOS Finder metadata file for current directory only.
# Skip .git and node_modules paths (and their subdirectories).
remove_local_ds_store() {
  case "$PWD/" in
  */.git | */.git/* | */node_modules | */node_modules/*)
    return
    ;;
  esac

  [[ -f "$PWD/.DS_Store" ]] && command rm -f -- "$PWD/.DS_Store"
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd remove_local_ds_store
remove_local_ds_store
