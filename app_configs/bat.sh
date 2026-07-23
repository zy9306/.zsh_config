if command_exists bat; then
	# export BAT_THEME="1337" # use GitHub for white theme, zenburn for black theme.
	export BAT_THEME="GitHub"
	alias cat="bat -p --wrap character"
fi
