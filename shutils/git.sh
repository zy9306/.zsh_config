_git_print_command() {
  print -r -- "+ ${(@q)@}" >&2
}

_git_run() {
  _git_print_command "$@"
  "$@"
}

_git_repo_has_changes() {
  local repo_dir

  repo_dir=$1

  ! git -C "$repo_dir" diff --quiet --ignore-submodules -- ||
    ! git -C "$repo_dir" diff --cached --quiet --ignore-submodules -- ||
    [ -n "$(git -C "$repo_dir" ls-files --others --exclude-standard)" ]
}

_git_pull_latest_repo() {
  local repo_dir branch

  repo_dir=$1

  echo_cyan "==> $repo_dir"

  if [ -z "$(git -C "$repo_dir" remote)" ]; then
    echo_blue "Skipped: no git remote"
    return 0
  fi

  branch=$(git -C "$repo_dir" symbolic-ref --quiet --short HEAD) || {
    echo_red_bold "Skipped: detached HEAD"
    return 1
  }

  if _git_repo_has_changes "$repo_dir"; then
    _git_run git -C "$repo_dir" stash push -u -m "git-pull-recursive auto stash $(date '+%F %T')" || return 1
  fi

  if git -C "$repo_dir" rev-parse --verify --quiet '@{upstream}' >/dev/null 2>&1; then
    _git_run git -C "$repo_dir" pull --ff-only || return 1
  elif git -C "$repo_dir" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    _git_run git -C "$repo_dir" pull --ff-only origin "$branch" || return 1
  else
    echo_red_bold "No upstream or origin/$branch found"
    return 1
  fi
}

git-pull-recursive() {
  emulate -L zsh

  local root_dir depth find_depth root_dir_set git_marker repo_dir canonical_repo_dir failed total
  local -a repo_dirs
  local -A seen

  root_dir=.
  root_dir_set=0
  depth=3
  failed=0
  total=0
  repo_dirs=()

  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)
        cat <<'EOF'
Usage: git-pull-recursive [-d <depth>|--depth=<depth>] [directory]

  Recursively find git repositories under directory and pull the latest
  upstream branch for each repository.

  If a repository has local changes, run `git stash push -u` before pulling.
  The default recursion depth is 3.

Options:
  -d, --depth <depth>  Recursion depth, default 3
  -h, --help           Show help

Examples:
  git-pull-recursive
  git-pull-recursive ~/projects
  git-pull-recursive -d 5 ~/projects
EOF
        return 0
        ;;
      -d|--depth)
        if [ $# -lt 2 ]; then
          echo_red_bold "Usage: git-pull-recursive [-d <depth>|--depth=<depth>] [directory]"
          return 1
        fi
        depth=$2
        shift 2
        ;;
      --depth=*)
        depth=${1#--depth=}
        shift
        ;;
      -*)
        echo_red_bold "Unknown option: $1"
        echo_red_bold "Usage: git-pull-recursive [-d <depth>|--depth=<depth>] [directory]"
        return 1
        ;;
      *)
        if [ "$root_dir_set" -eq 1 ]; then
          echo_red_bold "Usage: git-pull-recursive [-d <depth>|--depth=<depth>] [directory]"
          return 1
        fi
        root_dir=$1
        root_dir_set=1
        shift
        ;;
    esac
  done

  if [[ ! "$depth" = <-> ]]; then
    echo_red_bold "Depth must be a non-negative integer: $depth"
    return 1
  fi

  if [ ! -d "$root_dir" ]; then
    echo_red_bold "Not a directory: $root_dir"
    return 1
  fi

  root_dir=${root_dir:A}
  find_depth=$((depth + 1))

  while IFS= read -r git_marker; do
    repo_dir=${git_marker:h}
    canonical_repo_dir=${repo_dir:A}

    if [ -n "${seen[$canonical_repo_dir]}" ]; then
      continue
    fi

    if git -C "$canonical_repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      seen[$canonical_repo_dir]=1
      repo_dirs+=("$canonical_repo_dir")
    fi
  done < <(
    find "$root_dir" -maxdepth "$find_depth" -name .git \( \( -type d -prune \) -o -type f \) -print 2>/dev/null |
      sort
  )

  if [ ${#repo_dirs[@]} -eq 0 ]; then
    echo_red_bold "No git repositories found under: $root_dir"
    return 1
  fi

  for repo_dir in "${repo_dirs[@]}"; do
    total=$((total + 1))
    if ! _git_pull_latest_repo "$repo_dir"; then
      failed=$((failed + 1))
    fi
  done

  if [ "$failed" -gt 0 ]; then
    echo_red_bold "Done: $total repositories, $failed failed"
    return 1
  fi

  echo_green "Done: $total repositories"
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

  _git_run ln -s "$source_path" "$target_path" || return 1
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

_gw_prepare_base_branch() {
  local original_root base_branch

  original_root=$1
  base_branch=$2

  if git -C "$original_root" remote get-url origin >/dev/null 2>&1; then
    _git_run git -C "$original_root" fetch --prune origin || return 1
  fi

  if git -C "$original_root" show-ref --verify --quiet "refs/remotes/origin/$base_branch" ||
    git -C "$original_root" show-ref --verify --quiet "refs/heads/$base_branch"; then
    return 0
  fi

  echo_red_bold "Base branch not found: $base_branch"
  echo_red_bold "Use --base=<branch_name> to specify the base branch."
  return 1
}

_gw_print_help() {
  cat <<'EOF'
Usage: gw [--base=<branch_name>] <branch_name>|.|-D|list|-h|--help

  gw                                Show this help
  gw <branch_name>                  Create or enter ../<repo>_worktrees/<repo>-<branch_name>
  gw --base=dev <branch_name>       Create a new worktree branch from dev instead of master
  gw .                              Jump back to the original worktree
  gw -D                             Remove the current linked worktree without confirmation
  gw list                           List branch names for all worktrees
  gw -h, --help                     Show this help
EOF
}

gw() {
  emulate -L zsh

  local branch_name repo_root common_dir original_root repo_name repo_parent dir_branch_name worktree_parent worktree_dir line
  local base_branch arg
  local base_ref
  local -a args

  if [ $# -eq 0 ]; then
    _gw_print_help
    return 0
  fi

  base_branch=master
  args=()

  for arg in "$@"; do
    case "$arg" in
      --base=*)
        base_branch=${arg#--base=}
        if [ -z "$base_branch" ]; then
          echo_red_bold "Usage: gw [--base=<branch_name>] <branch_name>|.|-D|list|-h|--help"
          return 1
        fi
        ;;
      *)
        args+=("$arg")
        ;;
    esac
  done

  set -- "${args[@]}"

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    _gw_print_help
    return 0
  fi

  if [ $# -ne 1 ]; then
    echo_red_bold "Usage: gw [--base=<branch_name>] <branch_name>|.|-D|list|-h|--help"
    return 1
  fi

  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)

  if [ -z "$repo_root" ] || [ -z "$common_dir" ]; then
    echo_red_bold "Not inside a git repository"
    return 1
  fi

  repo_root=${repo_root:A}
  common_dir=${common_dir:A}
  original_root=${common_dir:h}

  if [ "$1" = "." ]; then
    _git_run cd "$original_root" || return 1
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
    if [ "$repo_root" = "$original_root" ]; then
      echo_red_bold "Current directory is the original worktree"
      return 1
    fi

    _git_run cd "$original_root" || return 1
    _git_run git -C "$original_root" worktree remove "$repo_root"
    return $?
  fi

  branch_name=$1

  repo_name=$(basename "$original_root")
  repo_parent=$(dirname "$original_root")
  dir_branch_name=${branch_name//\//-}
  worktree_parent="$repo_parent/${repo_name}_worktrees"
  worktree_dir="$worktree_parent/${repo_name}-${dir_branch_name}"

  if [ -e "$worktree_dir" ] && [ ! -d "$worktree_dir" ]; then
    echo_red_bold "Path already exists and is not a directory: $worktree_dir"
    return 1
  fi

  if [ -d "$worktree_dir" ]; then
    _gw_link_shared_files "$original_root" "$worktree_dir" || return 1
    _git_run cd "$worktree_dir" || return 1
    return 0
  fi

  if [ -e "$worktree_parent" ] && [ ! -d "$worktree_parent" ]; then
    echo_red_bold "Path already exists and is not a directory: $worktree_parent"
    return 1
  fi

  _git_run mkdir -p "$worktree_parent" || return 1

  _gw_prepare_base_branch "$original_root" "$base_branch" || return 1

  if git -C "$original_root" show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
    base_ref="origin/$base_branch"
  else
    base_ref="$base_branch"
  fi

  if git -C "$original_root" show-ref --verify --quiet "refs/heads/$branch_name"; then
    _git_run git -C "$original_root" worktree add "$worktree_dir" "$branch_name" || return 1
  elif git -C "$original_root" show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    _git_run git -C "$original_root" worktree add --track -b "$branch_name" "$worktree_dir" "origin/$branch_name" || return 1
  else
    _git_run git -C "$original_root" worktree add -b "$branch_name" "$worktree_dir" "$base_ref" || return 1
  fi

  _gw_link_shared_files "$original_root" "$worktree_dir" || return 1
  _git_run cd "$worktree_dir" || return 1
}
