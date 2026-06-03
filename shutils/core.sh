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
  (( $+commands[$1] ))
}
