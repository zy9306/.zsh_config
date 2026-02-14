OS_NAME="$(uname -s)"
PY_VERSION="${PY_VERSION:-3.13}"

if [[ ${OS_NAME} == 'Darwin' ]]; then
  PY_BIN_PATH="/Library/Frameworks/Python.framework/Versions/${PY_VERSION}/bin"
  prepend_path PY_BIN_PATH
  export VIRTUALENVWRAPPER_PYTHON="${PY_BIN_PATH}/python${PY_VERSION}"
  export PIPX_DEFAULT_PYTHON="${PY_BIN_PATH}/python${PY_VERSION}"

  for bin in python python3 pip pip3; do
    mv "/usr/local/bin/${bin}" "/usr/local/bin/${bin}.bak" 2>/dev/null || true
  done
  ln -s "${PY_BIN_PATH}/python${PY_VERSION}" /usr/local/bin/python
  ln -s "${PY_BIN_PATH}/python${PY_VERSION}" /usr/local/bin/python3
  ln -s "${PY_BIN_PATH}/pip3" /usr/local/bin/pip
  ln -s "${PY_BIN_PATH}/pip3" /usr/local/bin/pip3
  unset PY_BIN_PATH

elif [[ ${OS_NAME} == "Linux" ]]; then
  PY_BIN="$(command -v python${PY_VERSION} 2>/dev/null)"
  if [ -z "$PY_BIN" ]; then
    echo "python${PY_VERSION} not found. Please install Python ${PY_VERSION}." >&2
  else
    if [ -L "$PY_BIN" ]; then
      PY_BIN_REAL="$(readlink -f "$PY_BIN" 2>/dev/null)"
      if [ -n "$PY_BIN_REAL" ]; then
        PY_BIN="$PY_BIN_REAL"
      fi
      unset PY_BIN_REAL
    fi

    export VIRTUALENVWRAPPER_PYTHON="$PY_BIN"
    export PIPX_DEFAULT_PYTHON="$PY_BIN"

    PY_BIN_PATH="$(dirname "$PY_BIN")"
    if [ -n "$PY_BIN_PATH" ] && [ -d "$PY_BIN_PATH" ]; then
      if [ ! -e "${PY_BIN_PATH}/python" ]; then
        ln -s "${PY_BIN_PATH}/python${PY_VERSION}" "${PY_BIN_PATH}/python"
      fi
      if [ ! -e "${PY_BIN_PATH}/python3" ]; then
        ln -s "${PY_BIN_PATH}/python${PY_VERSION}" "${PY_BIN_PATH}/python3"
      fi
    fi
  fi
  unset PY_BIN PY_BIN_PATH
fi

unset OS_NAME PY_VERSION

# pip install virtualenv virtualenvwrapper
if [[ $(command_exists virtualenvwrapper.sh) == true ]]; then
  export WORKON_HOME=~/Envs
  source $(which virtualenvwrapper.sh)
fi
