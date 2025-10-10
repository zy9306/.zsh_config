go-add-env-and-path() {
  mkdir -p "$GOROOT/bin" "$GOPATH/bin"
  path_remove "$GOROOT/bin"
  path_remove "$GOPATH/bin"
  prepend_path "$GOROOT/bin"
  prepend_path "$GOPATH/bin"
  if [[ $(command_exists go) == true ]]; then
    go env -w GOPATH=$GOPATH GOROOT=$GOROOT
  fi
}

go-arm64() {
  mkdir -p $HOME/go-arm64/go
  export GOPATH=$HOME/go-arm64/go
  export GOROOT="/usr/local/go-arm64/go"
  go-add-env-and-path
}

go-amd64() {
  mkdir -p $HOME/go-amd64/go
  export GOPATH=$HOME/go-amd64/go
  export GOROOT="/usr/local/go-amd64/go"
  go-add-env-and-path
}

# Mac 默认用 go-arm64
if [[ $(uname -s) == "Darwin" ]]; then
  go-arm64
fi

# 如果是 Linux，那么就使用 go-amd64
if [[ $(uname -s) == "Linux" ]]; then
  if [[ $(uname -m) == "arm64" ]]; then
    go-arm64
  else
    go-amd64
  fi
fi

