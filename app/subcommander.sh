#!/bin/sh
set -euf

# shellcheck disable=SC1091
. ./lib.sh

script_to_subcmd() {
	basename "$1" | sed 's/\.sh$//g'
}

script_to_description() {
	grep "^# Description" "$1" | cut -d":" -f2 | sed 's/^[[:space:]]*//' || true
}

script_to_usage_suffix() {
	grep "^# Usage" "$1" | cut -d":" -f2 | sed 's/^[[:space:]]*//' || true
}

script_to_cmd() {
	subcmd="$(echo "$1" | sed -e 's@^subcommands/@@' -e 's/\.sh$//' -e 's@/@ @g')"
	echo "dab $subcmd"
}

script_to_help() {
	echo 'Usage:'
	echo "	$(script_to_cmd "$1") $(script_to_usage_suffix "$1")"
	echo
	script_to_description "$1"
	exit 0
}

script_to_subcmd_row() {
	subcmd_row "$(script_to_subcmd "$1")" "$(script_to_description "$1")"
}

dir_to_usage() {
	subcmd_row "$(script_to_subcmd "$1")" 'Nested subcommand namespace'
}

subcommands_help() {
	set +f
	for subcmd in "$1"/*; do
		if [ -f "$subcmd" ]; then
			script_to_subcmd_row "$subcmd"
		elif [ -d "$subcmd" ]; then
			dir_to_usage "$subcmd"
		fi
	done
	set -f

	subcmd_row help -h,--help 'You are looking at it'
}

usage() {
	subcommands_help "$1" | draw_subcommand_table
}

is_help() {
	case "${1:-}" in
	'-h' | '--help' | 'help')
		return 0
		;;
	*)
		return 1
		;;
	esac
}

subcommand_recurse() {
	scope="$1"
	subcmd="${2:-}"
	shift

	newscope="$scope/$subcmd"
	if [ -n "$subcmd" ] && [ -d "$newscope" ]; then
		shift
		subcommand_recurse "$newscope" "$@"
	elif [ -n "$subcmd" ] && [ -f "$newscope.sh" ]; then
		shift
		is_help "${1:-}" && script_to_help "$newscope.sh"
		"$newscope.sh" "$@"
		exit $?
	fi

	if is_help "$subcmd"; then
		true
	elif [ -z "$subcmd" ]; then
		code=1
	else
		warn "Unknown subcommand: $(echo "$newscope" | sed -e 's@subcommands/@@' -e 's@/@ @g')"
		code=1
	fi
	usage "$scope/"
	exit "${code:-0}"
}

subcommand() {
	subcommand_recurse 'subcommands' "$@"
}

subcommand "$@"