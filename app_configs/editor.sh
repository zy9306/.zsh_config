if command_exists emacs; then
	export EDITOR=emacs
elif command_exists nvim; then
	export EDITOR=nvim
elif command_exists vim; then
	export EDITOR=vim
fi

if command_exists nvim; then
	alias vim="nvim"
	alias vi="nvim"
fi
