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

git-switch-and-pull-main() {
  emulate -L zsh

  local branch current_branch git_common_dir target_dir worktree_path worktree_branch line

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: git-switch-and-pull-main [git-pull-args...]

  Switch to main/master and pull latest code.
  When called from a linked worktree, cd back to the worktree that has
  main/master checked out before pulling.

EOF
    return 0
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo_red_bold "Not inside a git work tree"
    return 1
  fi

  if git show-ref --verify --quiet refs/heads/main ||
    git show-ref --verify --quiet refs/remotes/origin/main; then
    branch=main
  elif git show-ref --verify --quiet refs/heads/master ||
    git show-ref --verify --quiet refs/remotes/origin/master; then
    branch=master
  else
    echo_red_bold "No main/master branch found"
    return 1
  fi

  while IFS= read -r line; do
    case "$line" in
      worktree\ *)
        worktree_path=${line#worktree }
        worktree_branch=
        ;;
      branch\ *)
        worktree_branch=${line#branch }
        if [ "$worktree_branch" = "refs/heads/$branch" ]; then
          target_dir=$worktree_path
          break
        fi
        ;;
    esac
  done < <(git worktree list --porcelain)

  if [ -z "$target_dir" ]; then
    git_common_dir=$(git rev-parse --git-common-dir) || return 1
    git_common_dir=${git_common_dir:A}

    if [ "${git_common_dir:t}" = ".git" ]; then
      target_dir=${git_common_dir:h}
    else
      target_dir=$(git rev-parse --show-toplevel) || return 1
    fi
  fi

  _git_run cd "$target_dir" || return 1

  current_branch=$(git branch --show-current 2>/dev/null)
  if [ "$current_branch" != "$branch" ]; then
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      _git_run git switch "$branch" || return 1
    else
      _git_run git switch --track "origin/$branch" || return 1
    fi
  fi

  _git_run git pull --ff-only "$@"
}

git-push-current() {
  emulate -L zsh

  local branch force

  force=0

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: git-push-current [-f]

  Push the current git branch to origin.
  -f        Force push the current branch.
  -h        Show help.
  --help    Show help.
EOF
    return 0
  fi

  if [ "$1" = "-f" ] || [ "$1" = "--force" ]; then
    force=1
    shift
  fi

  if [ $# -ne 0 ]; then
    echo_red_bold "Usage: git-push-current [-f]"
    return 1
  fi

  branch=$(git symbolic-ref --quiet --short HEAD) || {
    echo_red_bold "git-push-current: not on a branch"
    return 1
  }

  if [ "$force" -eq 1 ]; then
    _git_run git push -f origin "$branch"
  else
    _git_run git push origin "$branch"
  fi
}

git-switch-branch() {
  emulate -L zsh

  local remote selected_branch local_branch

  remote=0

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: git-switch-branch [-r]

  使用 fzf 选择 git 分支并切换过去。
  -r        先 fetch 更新远端分支，再从 remote 分支中选择。
  -h        显示帮助。
  --help    显示帮助。
EOF
    return 0
  fi

  if [ "$1" = "-r" ]; then
    remote=1
    shift
  fi

  if [ $# -ne 0 ]; then
    echo_red_bold "Usage: git-switch-branch [-r]"
    return 1
  fi

  if ! command_exists fzf; then
    echo_red_bold "fzf is not installed"
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo_red_bold "Not inside a git repository"
    return 1
  fi

  if [ "$remote" -eq 1 ]; then
    _git_run git fetch --prune || return 1

    selected_branch=$(
      git for-each-ref --format='%(refname:short)' refs/remotes |
        grep -v '/HEAD$' |
        fzf --prompt='git-switch-branch remote> ' --height=40%
    )
  else
    selected_branch=$(
      git for-each-ref --format='%(refname:short)' refs/heads |
        fzf --prompt='git-switch-branch> ' --height=40%
    )
  fi

  if [ -z "$selected_branch" ]; then
    return 130
  fi

  if [ "$remote" -eq 1 ]; then
    local_branch=${selected_branch#*/}

    if git show-ref --verify --quiet "refs/heads/$local_branch"; then
      _git_run git switch "$local_branch"
    else
      _git_run git switch --track "$selected_branch"
    fi
  else
    _git_run git switch "$selected_branch"
  fi
}

_git_worktree_link_shared_path() {
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

_git_worktree_link_shared_files() {
  local source_root target_root

  source_root=$1
  target_root=$2

  _git_worktree_link_shared_path "$source_root/ai_docs" "$target_root/ai_docs" || return 1
  _git_worktree_link_shared_path "$source_root/draft" "$target_root/draft" || return 1
  _git_worktree_link_shared_path "$source_root/.venv" "$target_root/.venv" || return 1
  _git_worktree_link_shared_path "$source_root/mise.toml" "$target_root/mise.toml" || return 1
  _git_worktree_link_shared_path "$source_root/AGENTS.md" "$target_root/AGENTS.md" || return 1
}

_git_worktree_prepare_base_branch() {
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

git-worktree() {
  emulate -L zsh

  local branch_name repo_root common_dir original_root repo_name repo_parent dir_branch_name worktree_parent worktree_dir legacy_worktree_dir confirm line
  local base_branch arg
  local base_ref
  local -a args

  base_branch=master
  args=()

  for arg in "$@"; do
    case "$arg" in
      --base=*)
        base_branch=${arg#--base=}
        if [ -z "$base_branch" ]; then
          echo_red_bold "Usage: git-worktree [--base=<branch_name>] [branch_name]|.|-D|list|-h|--help"
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
    cat <<'EOF'
Usage: git-worktree [--base=<branch_name>] [branch_name]|.|-D|list|-h|--help

  git-worktree                         Pick an existing worktree branch with fzf
  git-worktree <branch_name>           Create or enter ../<repo>_worktrees/<repo>-<branch_name>
  git-worktree --base=dev <branch>     Create a new worktree branch from dev instead of master
  git-worktree .                       Jump back to the original worktree
  git-worktree -D                      Remove the current linked worktree after confirmation
  git-worktree list                    List branch names for all worktrees
  git-worktree -h                      Show this help
  git-worktree --help                  Show this help
EOF
    return 0
  fi

  if [ $# -eq 0 ]; then
    if ! command_exists fzf; then
      echo_red_bold "fzf is not installed"
      return 1
    fi

    branch_name=$(git-worktree list | fzf --prompt='git-worktree> ' --height=40%)
    if [ -z "$branch_name" ]; then
      return 130
    fi

    set -- "$branch_name"
  fi

  if [ $# -ne 1 ]; then
    echo_red_bold "Usage: git-worktree [--base=<branch_name>] [branch_name]|.|-D|list|-h|--help"
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
    if [ "${repo_root:A}" = "${original_root:A}" ]; then
      echo_red_bold "Current directory is the original worktree"
      return 0
    fi

    printf 'Remove worktree %s? [y/N] ' "$repo_root"
    read confirm

    case "$confirm" in
      y|Y|yes|YES)
        _git_run cd "$original_root" || return 1
        _git_run git worktree remove "$repo_root" || return 1
        return 0
        ;;
      *)
        echo_red_bold "Cancelled"
        return 1
        ;;
    esac
  fi

  branch_name=$1

  repo_name=$(basename "$original_root")
  repo_parent=$(dirname "$original_root")
  dir_branch_name=${branch_name//\//-}
  worktree_parent="$repo_parent/${repo_name}_worktrees"
  worktree_dir="$worktree_parent/${repo_name}-${dir_branch_name}"
  legacy_worktree_dir="$repo_parent/${repo_name}-${dir_branch_name}"

  if [ -e "$worktree_dir" ] && [ ! -d "$worktree_dir" ]; then
    echo_red_bold "Path already exists and is not a directory: $worktree_dir"
    return 1
  fi

  if [ -d "$worktree_dir" ]; then
    _git_worktree_link_shared_files "$original_root" "$worktree_dir" || return 1
    _git_run cd "$worktree_dir" || return 1
    return 0
  fi

  if [ -d "$legacy_worktree_dir" ]; then
    _git_worktree_link_shared_files "$original_root" "$legacy_worktree_dir" || return 1
    _git_run cd "$legacy_worktree_dir" || return 1
    return 0
  fi

  if [ -e "$worktree_parent" ] && [ ! -d "$worktree_parent" ]; then
    echo_red_bold "Path already exists and is not a directory: $worktree_parent"
    return 1
  fi

  _git_run mkdir -p "$worktree_parent" || return 1

  _git_worktree_prepare_base_branch "$original_root" "$base_branch" || return 1

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

  _git_worktree_link_shared_files "$original_root" "$worktree_dir" || return 1
  _git_run cd "$worktree_dir" || return 1
}

git-menu() {
  emulate -L zsh

  local action base_branch branch_name command_status mode selected

  case "$1" in
    -h|--help|h|help)
      cat <<'EOF'
用法: git-menu [快捷命令] [参数...]

  不带快捷命令时打开 fzf 菜单选择 git 操作。
  在子菜单中按 Esc 返回上一级。

快捷命令:
  gm h                           显示快捷命令帮助
  gm m [git-pull-args...]        切到 main/master 并拉取最新代码
  gm p [-f|--force]              推送当前分支到 origin
  gm b [-r]                      切换本地分支；加 -r 时先 fetch 再切远端分支
  gm w [git-worktree-args...]    打开、创建、列出或删除 worktree

长命令名:
  main, pull, push, branch, switch, worktree, wt
  switch-and-pull-main, push-current, switch-branch

别名:
  gm
EOF
      return 0
      ;;
    m|main|pull|switch-and-pull-main)
      shift
      git-switch-and-pull-main "$@"
      return $?
      ;;
    p|push|push-current)
      shift
      git-push-current "$@"
      return $?
      ;;
    b|branch|switch|switch-branch)
      shift
      git-switch-branch "$@"
      return $?
      ;;
    w|wt|worktree)
      shift
      git-worktree "$@"
      return $?
      ;;
  esac

  if ! command_exists fzf; then
    echo_red_bold "fzf is not installed"
    return 1
  fi

  while true; do
    if ! selected=$(
      cat <<'EOF' | fzf --prompt='git> ' --height=40% --delimiter=$'\t' --with-nth=2,3 --tabstop=24
switch-and-pull-main	switch-and-pull-main	Switch to main/master and pull latest code
push-current	push-current	Push the current branch to origin
switch-branch	switch-branch	Switch local or remote branch
worktree	worktree	Open, create, list, or remove worktrees
EOF
    ); then
      return 130
    fi

    if [ -z "$selected" ]; then
      return 130
    fi

    action=${selected%%$'\t'*}

    case "$action" in
      switch-and-pull-main)
        git-switch-and-pull-main "$@"
        return $?
        ;;
      push-current)
        if [ $# -gt 0 ]; then
          git-push-current "$@"
          return $?
        fi

        if ! selected=$(
          cat <<'EOF' | fzf --prompt='git push> ' --height=40% --delimiter=$'\t' --with-nth=2,3 --tabstop=10
normal	normal	Push current branch
force	force	Force push current branch
EOF
        ); then
          continue
        fi
        if [ -z "$selected" ]; then
          continue
        fi

        mode=${selected%%$'\t'*}
        case "$mode" in
          normal)
            git-push-current
            return $?
            ;;
          force)
            git-push-current --force
            return $?
            ;;
        esac
        ;;
      switch-branch)
        if [ $# -gt 0 ]; then
          git-switch-branch "$@"
          return $?
        fi

        while true; do
          if ! selected=$(
            cat <<'EOF' | fzf --prompt='git branch> ' --height=40% --delimiter=$'\t' --with-nth=2,3 --tabstop=10
local	local	Switch local branch
remote	remote	Fetch and switch remote branch
EOF
          ); then
            break
          fi
          if [ -z "$selected" ]; then
            break
          fi

          mode=${selected%%$'\t'*}
          case "$mode" in
            local)
              git-switch-branch
              command_status=$?
              if [ "$command_status" -eq 130 ]; then
                continue
              fi
              return "$command_status"
              ;;
            remote)
              git-switch-branch -r
              command_status=$?
              if [ "$command_status" -eq 130 ]; then
                continue
              fi
              return "$command_status"
              ;;
          esac
        done
        ;;
      worktree)
        if [ $# -gt 0 ]; then
          git-worktree "$@"
          return $?
        fi

        while true; do
          if ! selected=$(
            cat <<'EOF' | fzf --prompt='git worktree> ' --height=40% --delimiter=$'\t' --with-nth=2,3 --tabstop=12
pick	pick	Pick an existing worktree branch
create	create	Create or open branch worktree
list	list	List worktree branches
original	original	Jump to original worktree
delete	delete	Remove current linked worktree
EOF
          ); then
            break
          fi
          if [ -z "$selected" ]; then
            break
          fi

          mode=${selected%%$'\t'*}
          case "$mode" in
            pick)
              git-worktree
              command_status=$?
              if [ "$command_status" -eq 130 ]; then
                continue
              fi
              return "$command_status"
              ;;
            create)
              printf 'branch (empty to go back)> '
              IFS= read -r branch_name
              if [ -z "$branch_name" ]; then
                continue
              fi

              printf 'base branch (empty for default master)> '
              IFS= read -r base_branch
              if [ -n "$base_branch" ]; then
                git-worktree "--base=$base_branch" "$branch_name"
              else
                git-worktree "$branch_name"
              fi
              return $?
              ;;
            list)
              git-worktree list
              return $?
              ;;
            original)
              git-worktree .
              return $?
              ;;
            delete)
              git-worktree -D
              return $?
              ;;
          esac
        done
        ;;
    esac
  done
}

alias gm='git-menu'
