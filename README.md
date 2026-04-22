# Install

```sh
git clone --recurse-submodules --depth 1 git@github.com:zy9306/.zsh_config.git ~/.zsh_config
cd ~/.zsh_config
ln -s "$PWD/.zshenv" "$HOME/.zshenv"
ln -s "$PWD/.zprofile" "$HOME/.zprofile"
ln -s "$PWD/.zshrc" "$HOME/.zshrc"
```

# Layout

- `.zshenv`: bootstrap `ZDOTDIR=$HOME/.zsh_config`
- `.zprofile`: login-shell environment setup such as Homebrew and OrbStack
- `.zshrc`: interactive shell config, plugins, prompt, aliases, and completions
