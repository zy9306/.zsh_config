export XDG_CONFIG_HOME="$HOME/.config"

append_path "$HOME/.local/bin"

append_path "/usr/sbin"

append_path "/opt/flutter/bin"

if [[ $OSTYPE == darwin* ]]; then
	export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib
	prepend_path "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/coreutils/libexec/gnubin"
fi
