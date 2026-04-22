sync-files() {
	emulate -L zsh

	local force=false skip_all=false overwrite_all=false
	local source_dir target_dir source_entry target_entry reply
	local -a entries

	if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
		cat <<'EOF'
Usage: sync-files [-f] <source> <target>

中文说明:
  将 <source> 目录下的所有文件和目录复制到 <target>。
  如果 <target> 中存在同名文件或目录，会提示选择：跳过、覆盖、跳过全部、覆盖全部。

  Copy all files and directories from <source> into <target>.
  If a same-name entry already exists in <target>, choose skip, overwrite,
  skip all, or overwrite all.

  -f    Overwrite same-name entries without prompting
  -h    Show this help

Examples:
  sync-files ~/.agents/skills ~/.config/opencode/skills
  sync-files -f ./source-dir ./target-dir
EOF
		return 0
	fi

	if [ "$1" = "-f" ]; then
		force=true
		shift
	fi

	if [ $# -ne 2 ]; then
		echo_red_bold "Usage: sync-files [-f] <source> <target>"
		return 1
	fi

	source_dir=${1%/}
	target_dir=${2%/}

	if [ -z "$source_dir" ]; then
		source_dir=$1
	fi

	if [ -z "$target_dir" ]; then
		target_dir=$2
	fi

	if [ ! -d "$source_dir" ]; then
		echo_red_bold "Source is not a directory: $1"
		return 1
	fi

	mkdir -p "$target_dir" || return 1

	entries=("$source_dir"/*(DN))

	if [ ${#entries[@]} -eq 0 ]; then
		echo_red_bold "No files found in: $source_dir"
		return 1
	fi

	for source_entry in "${entries[@]}"; do
		target_entry="$target_dir/$(basename "$source_entry")"

		if [ -e "$target_entry" ] || [ -L "$target_entry" ]; then
			if [ "$force" = true ] || [ "$overwrite_all" = true ]; then
				rm -rf "$target_entry" || return 1
			elif [ "$skip_all" = true ]; then
				echo_blue "Skipped: $target_entry"
				continue
			else
				printf '同名文件已存在 %s，选择: [s]跳过 [o]覆盖 [sa]跳过全部 [oa]覆盖全部 (默认: s) ' "$target_entry"
				read -r reply

				case "$reply" in
				o | O | overwrite | OVERWRITE)
					rm -rf "$target_entry" || return 1
					;;
				sa | SA)
					skip_all=true
					echo_blue "Skipped: $target_entry"
					continue
					;;
				oa | OA)
					overwrite_all=true
					rm -rf "$target_entry" || return 1
					;;
				*)
					echo_blue "Skipped: $target_entry"
					continue
					;;
				esac
			fi
		fi

		if cp -Rp "$source_entry" "$target_entry"; then
			echo_green "$source_entry -> $target_entry"
		else
			echo_red_bold "Failed: $source_entry"
			return 1
		fi
	done
}
