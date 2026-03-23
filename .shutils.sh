# -*- mode: sh -*-

style_normal='\033[0m'
style_red='\033[31m'
style_red_bold='\033[31;1;1m'
style_green='\033[32m'
style_cyan='\033[36m'
style_blue='\033[34m'

echo_red() {
  echo -e "${style_red}$@${style_normal}"
}

echo_red_bold() {
  echo -e "${style_red_bold}$@${style_normal}"
}

echo_green() {
  echo -e "${style_green}$@${style_normal}"
}

echo_cyan() {
  echo -e "${style_cyan}$@${style_normal}"
}

echo_blue() {
  echo -e "${style_blue}$@${style_normal}"
}

command_exists() {
  command=$1
  if ! testcommand="$(type -p "$1")" || [[ -z $testcommand ]]; then
    echo false
  else
    echo true
  fi
}

prepend_path() {
  p=$1
  if [ -d $p ]; then
    if [[ $PATH != *"$p"* ]]; then
      export PATH=$p:$PATH
    fi
  fi
  unset p
}

append_path() {
  p=$1
  if [ -d $p ]; then
    if [[ $PATH != *"$p"* ]]; then
      export PATH=$PATH:$p
    fi
  fi
  unset p
}

path_remove() {
  # only work in zsh
  path=("${(@)path:#"$1"}")
}

send_title() {
  if [ $# -eq 0 ]; then
    title=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
	echo "Setting title to '$title'"
    printf '\033]2;%s\007' "$title"
  else
    printf '\033]2;%s\007' "$1"
  fi
}

tn() {
  if [ $# -eq 0 ]; then
    title=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
	echo "Creating tmux session '$title'"
	tmux new -A -s "$title"
  else
	echo "Creating tmux session '$1'"
	tmux new -A -s "$1"
  fi
}

fh() {
  print -z $(([ -n "$ZSH_NAME" ] && fc -l 1 || history 0) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

_bak_copy() {
  local src normalized_src base_name dir_name timestamp backup_path

  src=$1
  normalized_src=${src%/}

  if [ -z "$normalized_src" ]; then
    normalized_src=$src
  fi

  if [ ! -e "$normalized_src" ]; then
    echo_red_bold "Not found: $src"
    return 1
  fi

  base_name=$(basename "$normalized_src")
  dir_name=$(dirname "$normalized_src")
  timestamp=$(date '+%Y-%m-%d-%H-%M-%S')
  backup_path="$dir_name/${base_name}_$timestamp"

  if [ -e "$backup_path" ]; then
    echo_red_bold "Backup already exists: $backup_path"
    return 1
  fi

  if cp -Rp "$normalized_src" "$backup_path"; then
    echo_green "$normalized_src -> $backup_path"
    return 0
  fi

  echo_red_bold "Backup failed: $normalized_src"
  return 1
}

bak() {
  if [ $# -eq 0 ]; then
    echo_red_bold "Usage: bak <file_or_dir> [...]"
    return 1
  fi

  local src

  for src in "$@"; do
    _bak_copy "$src"
  done
}

unbak() {
  emulate -L zsh
  setopt local_options nonomatch

  local force=false
  local arg normalized_arg arg_name original_name dir_name target_path backup_path
  local -a matches

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force)
        force=true
        shift
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo_red_bold "Usage: unbak [-f] <backup_or_original> [...]"
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -eq 0 ]; then
    echo_red_bold "Usage: unbak [-f] <backup_or_original> [...]"
    return 1
  fi

  for arg in "$@"; do
    normalized_arg=${arg%/}

    if [ -z "$normalized_arg" ]; then
      normalized_arg=$arg
    fi

    arg_name=$(basename "$normalized_arg")
    original_name=${arg_name%_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]}

    if [ "$original_name" != "$arg_name" ]; then
      backup_path=$normalized_arg

      if [ ! -e "$backup_path" ]; then
        echo_red_bold "Backup not found: $arg"
        continue
      fi

      target_path="$(dirname "$backup_path")/$original_name"
    else
      target_path=$normalized_arg
      dir_name=$(dirname "$target_path")
      matches=("$dir_name/${arg_name}"_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N))

      if [ ${#matches[@]} -eq 0 ]; then
        echo_red_bold "No backup found for: $arg"
        continue
      fi

      backup_path="${matches[-1]}"
    fi

    if [ -e "$target_path" ]; then
      if [ "$force" != true ]; then
        echo_red_bold "Target already exists: $target_path"
        continue
      fi

      if ! _bak_copy "$target_path"; then
        echo_red_bold "Failed to backup existing target: $target_path"
        continue
      fi

      if ! rm -rf -- "$target_path"; then
        echo_red_bold "Failed to remove existing target: $target_path"
        continue
      fi
    fi

    if cp -Rp "$backup_path" "$target_path"; then
      echo_green "$backup_path -> $target_path"
    else
      echo_red_bold "Restore failed: $backup_path"
    fi
  done
}

lsbak() {
  emulate -L zsh
  setopt local_options nonomatch

  local arg normalized_arg arg_name original_name dir_name
  local -a matches

  if [ $# -eq 0 ]; then
    matches=(./*_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N))

    if [ ${#matches[@]} -eq 0 ]; then
      echo_red_bold "No backups found in current directory"
      return 1
    fi

    printf '%s\n' "${matches[@]}"
    return 0
  fi

  for arg in "$@"; do
    normalized_arg=${arg%/}

    if [ -z "$normalized_arg" ]; then
      normalized_arg=$arg
    fi

    arg_name=$(basename "$normalized_arg")
    original_name=${arg_name%_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]}
    dir_name=$(dirname "$normalized_arg")
    matches=("$dir_name/${original_name}"_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N))

    if [ ${#matches[@]} -eq 0 ]; then
      echo_red_bold "No backup found for: $arg"
      continue
    fi

    printf '%s\n' "${matches[@]}"
  done
}
