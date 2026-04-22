if command_exists kubectl; then
	kubectl_completion_dir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
	kubectl_completion_file="$kubectl_completion_dir/kubectl-completion.zsh"

	if [[ ! -s "$kubectl_completion_file" ]]; then
		mkdir -p "$kubectl_completion_dir"
		if ! kubectl completion zsh >|"$kubectl_completion_file" 2>/dev/null; then
			rm -f "$kubectl_completion_file"
		fi
	fi

	if [[ -r "$kubectl_completion_file" ]]; then
		source "$kubectl_completion_file"
	fi

	unset kubectl_completion_dir kubectl_completion_file
fi
