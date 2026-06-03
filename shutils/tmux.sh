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
  local title

  if [ $# -eq 0 ]; then
    title=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
  else
    title=$1
  fi
  title=${title//./_}

  if tmux has-session -t "$title" 2>/dev/null; then
    echo "Attaching tmux session '$title'"
  else
    echo "Creating tmux session '$title'"
    tmux new-session -d -s "$title" -c "$PWD"
    tmux split-window -h -t "$title:" -c "$PWD"
    tmux select-pane -t "$title:" -L
  fi

  if [ -n "$TMUX" ]; then
    tmux switch-client -t "$title"
  else
    tmux attach-session -t "$title"
  fi
}

tsd() {
  local confirm current_session
  local selected_session
  local -a sessions

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: tsd [--all]

  Without arguments, delete the current tmux session.
  If fzf is installed, pick the session to delete with the current session listed first.
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

  if command_exists fzf; then
    sessions=(
      "$current_session"
      ${(@f)$(tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -vx -- "$current_session")}
    )

    selected_session=$(printf '%s\n' "${sessions[@]}" | fzf --prompt='tsd> ' --height=40%)
    if [ -z "$selected_session" ]; then
      return 130
    fi

    current_session=$selected_session
  fi

  tmux kill-session -t "$current_session"
}
