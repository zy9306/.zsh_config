_bak_default_desc() {
  date '+%Y-%m-%d-%H-%M-%S'
}

_bak_is_legacy_backup_name() {
  case "$1" in
    *_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

_bak_is_backup_name() {
  case "$1" in
    *_bak_*)
      return 0
      ;;
  esac

  _bak_is_legacy_backup_name "$1"
}

_bak_original_name() {
  local name

  name=$1

  case "$name" in
    *_bak_*)
      printf '%s\n' "${name%_bak_*}"
      return 0
      ;;
  esac

  if _bak_is_legacy_backup_name "$name"; then
    printf '%s\n' "${name%_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]}"
    return 0
  fi

  printf '%s\n' "$name"
}

_bak_copy() {
  local src desc force normalized_src base_name dir_name backup_path

  src=$1
  desc=$2
  force=$3
  normalized_src=${src%/}

  if [ -z "$normalized_src" ]; then
    normalized_src=$src
  fi

  if [ ! -e "$normalized_src" ]; then
    echo_red_bold "Not found: $src"
    return 1
  fi

  if [ -n "$desc" ] && [[ "$desc" == */* ]]; then
    echo_red_bold "Backup description cannot contain '/': $desc"
    return 1
  fi

  if [ -z "$desc" ]; then
    desc=$(_bak_default_desc)
  fi

  base_name=$(basename "$normalized_src")
  dir_name=$(dirname "$normalized_src")
  backup_path="$dir_name/${base_name}_bak_$desc"

  if [ -e "$backup_path" ] || [ -L "$backup_path" ]; then
    if [ "$force" != true ]; then
      echo_red_bold "Backup already exists: $backup_path"
      return 1
    fi

    if ! rm -rf -- "$backup_path"; then
      echo_red_bold "Failed to remove existing backup: $backup_path"
      return 1
    fi
  fi

  if cp -Rp "$normalized_src" "$backup_path"; then
    echo_green "$normalized_src -> $backup_path"
    return 0
  fi

  echo_red_bold "Backup failed: $normalized_src"
  return 1
}

bak() {
  local desc='' src

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: bak [-d desc] <file_or_dir> [...]

  -d, --desc <desc>  Use <desc> in backup name: <path>_bak_<desc>
  -h, --help         Show this help
EOF
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -d|--desc)
        if [ $# -lt 2 ]; then
          echo_red_bold "Usage: bak [-d desc] <file_or_dir> [...]"
          return 1
        fi
        desc=$2
        shift 2
        ;;
      --)
        shift
        break
        ;;
      -h|--help)
        cat <<'EOF'
Usage: bak [-d desc] <file_or_dir> [...]

  -d, --desc <desc>  Use <desc> in backup name: <path>_bak_<desc>
  -h, --help         Show this help
EOF
        return 0
        ;;
      -* )
        echo_red_bold "Usage: bak [-d desc] <file_or_dir> [...]"
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -eq 0 ]; then
    echo_red_bold "Usage: bak [-d desc] <file_or_dir> [...]"
    return 1
  fi

  for src in "$@"; do
    _bak_copy "$src" "$desc"
  done
}

replace() {
  local force=false src target backup_desc normalized_src normalized_target

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: replace [-f] <src> <target> <target_bak_desc>

  Backup <target> to <target>_bak_<target_bak_desc>, then copy <src> to <target>
  -f, --force  Overwrite existing backup
EOF
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force)
        force=true
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage: replace [-f] <src> <target> <target_bak_desc>

  Backup <target> to <target>_bak_<target_bak_desc>, then copy <src> to <target>
  -f, --force  Overwrite existing backup
EOF
        return 0
        ;;
      --)
        shift
        break
        ;;
      -* )
        echo_red_bold "Usage: replace [-f] <src> <target> <target_bak_desc>"
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -ne 3 ]; then
    echo_red_bold "Usage: replace [-f] <src> <target> <target_bak_desc>"
    return 1
  fi

  src=$1
  target=$2
  backup_desc=$3
  normalized_src=${src%/}
  normalized_target=${target%/}

  if [ -z "$normalized_src" ]; then
    normalized_src=$src
  fi

  if [ -z "$normalized_target" ]; then
    normalized_target=$target
  fi

  if [ ! -e "$normalized_src" ]; then
    echo_red_bold "Source not found: $src"
    return 1
  fi

  if [ ! -e "$normalized_target" ] && [ ! -L "$normalized_target" ]; then
    echo_red_bold "Target not found: $target"
    return 1
  fi

  if [ -z "$backup_desc" ]; then
    echo_red_bold "Backup description cannot be empty"
    return 1
  fi

  if ! _bak_copy "$normalized_target" "$backup_desc" "$force"; then
    return 1
  fi

  if ! rm -rf -- "$normalized_target"; then
    echo_red_bold "Failed to remove target: $normalized_target"
    return 1
  fi

  if cp -Rp "$normalized_src" "$normalized_target"; then
    echo_green "$normalized_src -> $normalized_target"
    return 0
  fi

  echo_red_bold "Replace failed: $normalized_src -> $normalized_target"
  return 1
}

unbak() {
  emulate -L zsh
  setopt local_options nonomatch

  local force=false
  local arg normalized_arg arg_name original_name dir_name target_path backup_path
  local -a matches

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: unbak [-f] <backup_or_original> [...]

  -f, --force  Backup and replace existing target before restoring
  -h, --help   Show this help
EOF
    return 0
  fi

  while [ $# -gt 0 ]; do
    case "$1" in
      -f|--force)
        force=true
        shift
        ;;
      -h|--help)
        cat <<'EOF'
Usage: unbak [-f] <backup_or_original> [...]

  -f, --force  Backup and replace existing target before restoring
  -h, --help   Show this help
EOF
        return 0
        ;;
      --)
        shift
        break
        ;;
      -*)
        echo_red_bold "Usage: unbak [-f] <backup_or_original> [...]"
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  if [ $# -eq 0 ]; then
    echo_red_bold "Usage: unbak [-f] <backup_or_original> [...]"
    return 1
  fi

  for arg in "$@"; do
    normalized_arg=${arg%/}

    if [ -z "$normalized_arg" ]; then
      normalized_arg=$arg
    fi

    arg_name=$(basename "$normalized_arg")
    original_name=$(_bak_original_name "$arg_name")

    if _bak_is_backup_name "$arg_name"; then
      backup_path=$normalized_arg

      if [ ! -e "$backup_path" ] && [ ! -L "$backup_path" ]; then
        echo_red_bold "Backup not found: $arg"
        continue
      fi

      target_path="$(dirname "$backup_path")/$original_name"
    else
      target_path=$normalized_arg
      dir_name=$(dirname "$target_path")
      matches=(
        "$dir_name/${arg_name}_bak_"*(N)
        "$dir_name/${arg_name}"_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N)
      )

      if [ ${#matches[@]} -eq 0 ]; then
        echo_red_bold "No backup found for: $arg"
        continue
      fi

      backup_path="${matches[-1]}"
    fi

    if [ -e "$target_path" ]; then
      if [ "$force" != true ]; then
        echo_red_bold "Target already exists: $target_path"
        continue
      fi

      if ! _bak_copy "$target_path"; then
        echo_red_bold "Failed to backup existing target: $target_path"
        continue
      fi

      if ! rm -rf -- "$target_path"; then
        echo_red_bold "Failed to remove existing target: $target_path"
        continue
      fi
    fi

    if cp -Rp "$backup_path" "$target_path"; then
      echo_green "$backup_path -> $target_path"
    else
      echo_red_bold "Restore failed: $backup_path"
    fi
  done
}

lsbak() {
  emulate -L zsh
  setopt local_options nonomatch

  local arg normalized_arg arg_name original_name dir_name
  local -a matches

  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    cat <<'EOF'
Usage: lsbak [backup_or_original ...]

  Without arguments, list backups in the current directory.
  With arguments, list backups matching each original or backup path.
EOF
    return 0
  fi

  if [ $# -eq 0 ]; then
    matches=(
      ./*_bak_*(N)
      ./*_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N)
    )

    if [ ${#matches[@]} -eq 0 ]; then
      echo_red_bold "No backups found in current directory"
      return 1
    fi

    printf '%s\n' "${matches[@]}"
    return 0
  fi

  for arg in "$@"; do
    normalized_arg=${arg%/}

    if [ -z "$normalized_arg" ]; then
      normalized_arg=$arg
    fi

    arg_name=$(basename "$normalized_arg")
    original_name=$(_bak_original_name "$arg_name")
    dir_name=$(dirname "$normalized_arg")
    matches=(
      "$dir_name/${original_name}_bak_"*(N)
      "$dir_name/${original_name}"_[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9]-[0-9][0-9](N)
    )

    if [ ${#matches[@]} -eq 0 ]; then
      echo_red_bold "No backup found for: $arg"
      continue
    fi

    printf '%s\n' "${matches[@]}"
  done
}
