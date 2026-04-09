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

_gw_link_shared_path() {
  local source_path target_path

  source_path=$1
  target_path=$2

  if [ ! -e "$source_path" ]; then
    return 0
  fi

  if [ -e "$target_path" ] || [ -L "$target_path" ]; then
    return 0
  fi

  ln -s "$source_path" "$target_path" || return 1
}

_gw_link_shared_files() {
  local source_root target_root

  source_root=$1
  target_root=$2

  _gw_link_shared_path "$source_root/ai_docs" "$target_root/ai_docs" || return 1
  _gw_link_shared_path "$source_root/draft" "$target_root/draft" || return 1
  _gw_link_shared_path "$source_root/.venv" "$target_root/.venv" || return 1
  _gw_link_shared_path "$source_root/mise.toml" "$target_root/mise.toml" || return 1
  _gw_link_shared_path "$source_root/AGENTS.md" "$target_root/AGENTS.md" || return 1
}

gw() {
  emulate -L zsh

  local branch_name repo_root common_dir original_root repo_name repo_parent dir_branch_name worktree_dir confirm line

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: gw <branch_name>|.|-D|list|-h|--help

  gw <branch_name>  Create or enter a worktree named <repo>-<branch_name>
  gw .              Jump back to the original worktree
  gw -D             Remove the current linked worktree after confirmation
  gw list           List branch names for all worktrees
  gw -h             Show this help
  gw --help         Show this help
EOF
    return 0
  fi

  if [ $# -ne 1 ]; then
    echo_red_bold "Usage: gw <branch_name>|.|-D|list|-h|--help"
    return 1
  fi

  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)

  if [ -z "$repo_root" ] || [ -z "$common_dir" ]; then
    echo_red_bold "Not inside a git repository"
    return 1
  fi

  original_root=$(dirname "$common_dir")

  if [ "$1" = "." ]; then
    cd "$original_root" || return 1
    return 0
  fi

  if [ "$1" = "list" ]; then
    git worktree list --porcelain | while IFS= read -r line; do
      case "$line" in
        'branch refs/heads/'*)
          print -r -- "${line#branch refs/heads/}"
          ;;
        'branch '*)
          if [ "${line#branch }" != "HEAD" ]; then
            print -r -- "${line#branch }"
          fi
          ;;
      esac
    done
    return 0
  fi

  if [ "$1" = "-D" ]; then
    if [ "${repo_root:A}" = "${original_root:A}" ]; then
      echo_red_bold "Current directory is the original worktree"
      return 0
    fi

    printf 'Remove worktree %s? [y/N] ' "$repo_root"
    read confirm

    case "$confirm" in
      y|Y|yes|YES)
        cd "$original_root" || return 1
        git worktree remove "$repo_root" || return 1
        return 0
        ;;
      *)
        echo_red_bold "Cancelled"
        return 1
        ;;
    esac
  fi

  branch_name=$1

  repo_name=$(basename "$repo_root")
  repo_parent=$(dirname "$repo_root")
  dir_branch_name=${branch_name//\//-}
  worktree_dir="$repo_parent/${repo_name}-${dir_branch_name}"

  if [ -e "$worktree_dir" ] && [ ! -d "$worktree_dir" ]; then
    echo_red_bold "Path already exists and is not a directory: $worktree_dir"
    return 1
  fi

  if [ -d "$worktree_dir" ]; then
    _gw_link_shared_files "$original_root" "$worktree_dir" || return 1
    cd "$worktree_dir" || return 1
    return 0
  fi

  if git show-ref --verify --quiet "refs/heads/$branch_name" || git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    git worktree add "$worktree_dir" "$branch_name" || return 1
  else
    git worktree add -b "$branch_name" "$worktree_dir" || return 1
  fi

  _gw_link_shared_files "$original_root" "$worktree_dir" || return 1
  cd "$worktree_dir" || return 1
}
