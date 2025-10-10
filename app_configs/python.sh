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
	if [ -d "/Library/Frameworks/Python.framework/Versions/${py_version}/bin" ]; then
		prepend_path "/Library/Frameworks/Python.framework/Versions/${py_version}/bin"
	fi
	if [ -d "/Users/zy/Library/Python/${py_version}/bin" ]; then
		prepend_path "/Users/zy/Library/Python/${py_version}/bin"
	fi
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

