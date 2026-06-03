fh() {
  print -z $(([ -n "$ZSH_NAME" ] && fc -l 1 || history 0) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
