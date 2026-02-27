if [[ $(command_exists bat) == true ]]; then
  export BAT_THEME="1337" # use GitHub for white theme, zenburn for black theme.
  alias cat="bat -p --wrap character"
fi

