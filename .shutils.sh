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

typeset -U path PATH

command_exists() {
  (( $+commands[$1] ))
}

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

tsd() {
  local confirm current_session

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: tsd [--all]

  Without arguments, delete the current tmux session.
  --all     Delete all tmux sessions after confirmation.
  -h        Show this help.
  --help    Show this help.
EOF
    return 0
  fi

  if [ $# -gt 1 ]; then
    echo_red_bold "Usage: tsd [--all]"
    return 1
  fi

  if [ "$1" = "--all" ]; then
    if ! tmux ls >/dev/null 2>&1; then
      echo_red_bold "No tmux sessions found"
      return 1
    fi

    printf 'Delete all tmux sessions? [y/N] '
    read confirm

    case "$confirm" in
      y|Y|yes|YES)
        tmux kill-server
        ;;
      *)
        echo_red_bold "Cancelled"
        return 1
        ;;
    esac

    return $?
  fi

  if [ $# -ne 0 ]; then
    echo_red_bold "Usage: tsd [--all]"
    return 1
  fi

  if [ -z "$TMUX" ]; then
    echo_red_bold "Not inside a tmux session"
    return 1
  fi

  current_session=$(tmux display-message -p '#S' 2>/dev/null)

  if [ -z "$current_session" ]; then
    echo_red_bold "Failed to determine current tmux session"
    return 1
  fi

  tmux kill-session -t "$current_session"
}

fh() {
  print -z $(([ -n "$ZSH_NAME" ] && fc -l 1 || history 0) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

_bak_default_desc() {
  date '+%Y-%m-%d-%H-%M-%S'
}

_bak_is_legacy_backup_name() {
  case "$1" in
    *_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

_bak_is_backup_name() {
  case "$1" in
    *_bak_*)
      return 0
      ;;
  esac

  _bak_is_legacy_backup_name "$1"
}

_bak_original_name() {
  local name

  name=$1

  case "$name" in
    *_bak_*)
      printf '%s\n' "${name%_bak_*}"
      return 0
      ;;
  esac

  if _bak_is_legacy_backup_name "$name"; then
    printf '%s\n' "${name%_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]}"
    return 0
  fi

  printf '%s\n' "$name"
}

_bak_copy() {
  local src desc normalized_src base_name dir_name backup_path

  src=$1
  desc=$2
  normalized_src=${src%/}

  if [ -z "$normalized_src" ]; then
    normalized_src=$src
  fi

  if [ ! -e "$normalized_src" ]; then
    echo_red_bold "Not found: $src"
    return 1
  fi

  if [ -n "$desc" ] && [[ "$desc" == */* ]]; then
    echo_red_bold "Backup description cannot contain '/': $desc"
    return 1
  fi

  if [ -z "$desc" ]; then
    desc=$(_bak_default_desc)
  fi

  base_name=$(basename "$normalized_src")
  dir_name=$(dirname "$normalized_src")
  backup_path="$dir_name/${base_name}_bak_$desc"

  if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
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
  local desc='' src

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: bak [-d desc] <file_or_dir> [...]

  -d, --desc <desc>  Use <desc> in backup name: <path>_bak_<desc>
  -h, --help         Show this help
EOF
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--desc)
        if [ $# -lt 2 ]; then
          echo_red_bold "Usage: bak [-d desc] <file_or_dir> [...]"
          return 1
        fi
        desc=$2
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -h|--help)
        cat <<'EOF'
Usage: bak [-d desc] <file_or_dir> [...]

  -d, --desc <desc>  Use <desc> in backup name: <path>_bak_<desc>
  -h, --help         Show this help
EOF
        return 0
        ;;
      -* )
        echo_red_bold "Usage: bak [-d desc] <file_or_dir> [...]"
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -eq 0 ]; then
    echo_red_bold "Usage: bak [-d desc] <file_or_dir> [...]"
    return 1
  fi

  for src in "$@"; do
    _bak_copy "$src" "$desc"
  done
}

replace() {
  local src target backup_desc normalized_src normalized_target

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: replace <src> <target> <target_bak_desc>

  Backup <target> to <target>_bak_<target_bak_desc>, then copy <src> to <target>
EOF
    return 0
  fi

  if [ $# -ne 3 ]; then
    echo_red_bold "Usage: replace <src> <target> <target_bak_desc>"
    return 1
  fi

  src=$1
  target=$2
  backup_desc=$3
  normalized_src=${src%/}
  normalized_target=${target%/}

  if [ -z "$normalized_src" ]; then
    normalized_src=$src
  fi

  if [ -z "$normalized_target" ]; then
    normalized_target=$target
  fi

  if [ ! -e "$normalized_src" ]; then
    echo_red_bold "Source not found: $src"
    return 1
  fi

  if [ ! -e "$normalized_target" ] && [ ! -L "$normalized_target" ]; then
    echo_red_bold "Target not found: $target"
    return 1
  fi

  if [ -z "$backup_desc" ]; then
    echo_red_bold "Backup description cannot be empty"
    return 1
  fi

  if ! _bak_copy "$normalized_target" "$backup_desc"; then
    return 1
  fi

  if ! rm -rf -- "$normalized_target"; then
    echo_red_bold "Failed to remove target: $normalized_target"
    return 1
  fi

  if cp -Rp "$normalized_src" "$normalized_target"; then
    echo_green "$normalized_src -> $normalized_target"
    return 0
  fi

  echo_red_bold "Replace failed: $normalized_src -> $normalized_target"
  return 1
}

unbak() {
  emulate -L zsh
  setopt local_options nonomatch

  local force=false
  local arg normalized_arg arg_name original_name dir_name target_path backup_path
  local -a matches

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: unbak [-f] <backup_or_original> [...]

  -f, --force  Backup and replace existing target before restoring
  -h, --help   Show this help
EOF
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force)
        force=true
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage: unbak [-f] <backup_or_original> [...]

  -f, --force  Backup and replace existing target before restoring
  -h, --help   Show this help
EOF
        return 0
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
    original_name=$(_bak_original_name "$arg_name")

    if _bak_is_backup_name "$arg_name"; then
      backup_path=$normalized_arg

      if [ ! -e "$backup_path" ] && [ ! -L "$backup_path" ]; then
        echo_red_bold "Backup not found: $arg"
        continue
      fi

      target_path="$(dirname "$backup_path")/$original_name"
    else
      target_path=$normalized_arg
      dir_name=$(dirname "$target_path")
      matches=(
        "$dir_name/${arg_name}_bak_"*(N)
        "$dir_name/${arg_name}"_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N)
      )

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

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: lsbak [backup_or_original ...]

  Without arguments, list backups in the current directory.
  With arguments, list backups matching each original or backup path.
EOF
    return 0
  fi

  if [ $# -eq 0 ]; then
    matches=(
      ./*_bak_*(N)
      ./*_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N)
    )

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
    original_name=$(_bak_original_name "$arg_name")
    dir_name=$(dirname "$normalized_arg")
    matches=(
      "$dir_name/${original_name}_bak_"*(N)
      "$dir_name/${original_name}"_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N)
    )

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
