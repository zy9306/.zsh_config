if command_exists emacs; then
	export EDITOR=emacs
elif command_exists nvim; then
	export EDITOR=nvim
	alias vim="nvim"
	alias vi="nvim"
elif command_exists vim; then
	export EDITOR=vim
fi
