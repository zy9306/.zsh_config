# -*- mode: sh -*-

if [ -f ~/.my_env ]; then
  source ~/.my_env
else
  touch ~/.my_env
fi

# config LD_LIBRARY_PATH
if [ -d /usr/local/lib ]; then
  APPEND_LD_LIBRARY_PATH="/usr/local/lib:/usr/local/lib64"
  if [[ $LD_LIBRARY_PATH != *"$APPEND_LD_LIBRARY_PATH"* ]]; then
    if [ ! $LD_LIBRARY_PATH ]; then
      export LD_LIBRARY_PATH=$APPEND_LD_LIBRARY_PATH
    else
      export LD_LIBRARY_PATH=$APPEND_LD_LIBRARY_PATH:$LD_LIBRARY_PATH
    fi
  fi
fi

# config PATH for Linux
if [[ $(uname -s) == "Linux" ]]; then
  SYS_PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/bin"
  if [[ $PATH != *"$SYS_PATH"* ]]; then
    export PATH="$SYS_PATH:${PATH}"
  fi
fi

# Extra PATHs
append_path "$HOME/.local/bin"

if [[ $(uname -s) == "Darwin" ]]; then
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib
fi

if [[ $(uname -s) == "Darwin" ]]; then
  prepend_path "/usr/local/opt/coreutils/libexec/gnubin"
fi
# Extra PATHs END

# Python START
# custom in ~/.my_env
if [ -z "$VIRTUALENVWRAPPER_PYTHON_VERSION" ]; then
  export VIRTUALENVWRAPPER_PYTHON_VERSION=3.10
fi

if [ -z "$MAIN_PYTHON_VERSION" ]; then
  export MAIN_PYTHON_VERSION=3.10
fi

# config python path for Mac
if [[ $(uname -s) == 'Darwin' ]]; then
  for py_version in {"3.6","3.8","3.10","3.12","3.13"}; do
    prepend_path "/Library/Frameworks/Python.framework/Versions/${py_version}/bin"
  done

  _gpython="/Library/Frameworks/Python.framework/Versions/${MAIN_PYTHON_VERSION}/bin/python"

  TMP=/Library/Frameworks/Python.framework/Versions/${VIRTUALENVWRAPPER_PYTHON_VERSION}/bin/python${VIRTUALENVWRAPPER_PYTHON_VERSION}
  if [ -f $TMP ]; then
    export VIRTUALENVWRAPPER_PYTHON=$TMP
  fi
  unset TMP
fi
# config python path for Mac END

# config python path for Linux
if [[ $(uname -s) == "Linux" ]]; then
  if [ -f /usr/local/bin/python${VIRTUALENVWRAPPER_PYTHON_VERSION} ]; then
    export VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python${VIRTUALENVWRAPPER_PYTHON_VERSION}
  fi

  if [ -f /usr/local/bin/python${MAIN_PYTHON_VERSION} ]; then
    _gpython="/usr/local/bin/python${MAIN_PYTHON_VERSION}"
  fi
fi
# config python path for Linux END

if [[ $(command_exists virtualenvwrapper.sh) == true ]]; then
  export WORKON_HOME=~/Envs
  source $(which virtualenvwrapper.sh)
fi

gpython() {
  $_gpython $@
}

gpip() {
  $_gpython -m pip $@
}

# Python END

# Go START
go-add-env-and-path() {
  mkdir -p "$GOROOT/bin" "$GOPATH/bin"
  path_remove "$GOROOT/bin"
  path_remove "$GOPATH/bin"
  prepend_path "$GOROOT/bin"
  prepend_path "$GOPATH/bin"
  go env -w GOPATH=$GOPATH GOROOT=$GOROOT
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
if [[ $(command_exists go) == true ]]; then
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
fi
# Go END

# Rust
prepend_path "$HOME/.cargo/bin"

# Node fnm START
# set npm: npm config set prefix '~/.npm_packages'
if [ ! -d $HOME/.fnm ]; then
  mkdir -p $HOME/.fnm
fi

prepend_path "$HOME/.fnm"

if [[ $(command_exists fnm) == true ]]; then
  eval "$(fnm env)"
fi

# npm config set prefix '~/.npm_packages'
if [[ $(command_exists npm) == true ]]; then
  prepend_path "$HOME/.npm_packages/bin"
fi
# Node fnm END

# bun START
if [ -d "$HOME/.bun" ]; then
  # bun completions
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
fi
# bun END

if [ -f /etc/profile.d/proxy.sh ]; then
  source /etc/profile.d/proxy.sh
fi

# Ruby START
if [ -d /usr/local/opt/ruby/bin ]; then
  prepend_path "/usr/local/opt/ruby/bin"
  export LDFLAGS="-L/usr/local/opt/ruby/lib"
  export CPPFLAGS="-I/usr/local/opt/ruby/include"
  export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
fi
# Ruby END

# flutter START
prepend_path "/opt/flutter/bin"
# flutter END
