_git_print_command() {
  print -r -- "+ ${(@q)@}" >&2
}

_git_run() {
  _git_print_command "$@"
  "$@"
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
  local original_root base_branch current_branch

  original_root=$1
  base_branch=$2

  current_branch=$(git -C "$original_root" branch --show-current 2>/dev/null)

  if [ "$current_branch" != "$base_branch" ]; then
    if git -C "$original_root" show-ref --verify --quiet "refs/heads/$base_branch"; then
      _git_run git -C "$original_root" switch "$base_branch" || return 1
    elif git -C "$original_root" show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
      _git_run git -C "$original_root" switch --track -c "$base_branch" "origin/$base_branch" || return 1
    else
      echo_red_bold "Base branch not found: $base_branch"
      echo_red_bold "Use --base=<branch_name> to specify the base branch."
      return 1
    fi
  fi

  if git -C "$original_root" rev-parse --verify --quiet '@{upstream}' >/dev/null 2>&1; then
    _git_run git -C "$original_root" pull --ff-only || return 1
  elif git -C "$original_root" show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
    _git_run git -C "$original_root" pull --ff-only origin "$base_branch" || return 1
  fi
}

git-worktree() {
  emulate -L zsh

  local branch_name repo_root common_dir original_root repo_name repo_parent dir_branch_name worktree_parent worktree_dir legacy_worktree_dir confirm line
  local base_branch arg
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

  if git show-ref --verify --quiet "refs/heads/$branch_name" || git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
    _git_run git -C "$original_root" worktree add "$worktree_dir" "$branch_name" || return 1
  else
    _git_run git -C "$original_root" worktree add -b "$branch_name" "$worktree_dir" "$base_branch" || return 1
  fi

  _git_worktree_link_shared_files "$original_root" "$worktree_dir" || return 1
  _git_run cd "$worktree_dir" || return 1
}

git-menu() {
  emulate -L zsh

  local action base_branch branch_name command_status mode selected

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: git-menu [args...]

  Pick a git task with fzf and run it.
  When called with args, they are forwarded to the selected top-level helper.
  Press Esc in a submenu to go back one level.

Aliases:
  gm
EOF
    return 0
  fi

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
