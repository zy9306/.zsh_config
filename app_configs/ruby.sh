if [ -d /usr/local/opt/ruby/bin ]; then
  prepend_path "/usr/local/opt/ruby/bin"
  export LDFLAGS="-L/usr/local/opt/ruby/lib"
  export CPPFLAGS="-I/usr/local/opt/ruby/include"
  export PKG_CONFIG_PATH="/usr/local/opt/ruby/lib/pkgconfig"
fi

