export XDG_CONFIG_HOME="$HOME/.config"

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

if [[ $(uname -s) == "Linux" ]]; then
  SYS_PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/bin"
  if [[ $PATH != *"$SYS_PATH"* ]]; then
    export PATH="$SYS_PATH:${PATH}"
  fi
fi

append_path "$HOME/.local/bin"

append_path "/usr/sbin"

if [[ $(uname -s) == "Darwin" ]]; then
  export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib
fi

if [[ $(uname -s) == "Darwin" ]]; then
  prepend_path "/usr/local/opt/coreutils/libexec/gnubin"
fi

