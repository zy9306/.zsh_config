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
	echo "Setting alacritty title to '$title'"
    echo -e "\e]2;$title"
  else
    echo -e "\e]2;$1"
  fi
}
