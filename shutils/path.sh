
typeset -U path PATH

prepend_path() {
  local p

  p=$1
  if [ -d "$p" ]; then
    path=("$p" $path)
    export PATH
  fi
}

append_path() {
  local p

  p=$1
  if [ -d "$p" ]; then
    path+=("$p")
    export PATH
  fi
}

path_remove() {
  # only work in zsh
  path=("${(@)path:#"$1"}")
}

path() {
  local target

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: path <file_or_dir>

  Print the absolute path of <file_or_dir>.
EOF
    return 0
  fi

  if [ $# -ne 1 ]; then
    echo_red_bold "Usage: path <file_or_dir>"
    return 1
  fi

  target=$1

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    echo_red_bold "Not found: $target"
    return 1
  fi

  print -r -- "${target:A}"
}
