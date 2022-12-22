#!/bin/sh
set -eu

# this script is indended to be used as `git run MyScript`


GIT_SCRIPTS_DIR="$(git rev-parse --git-dir)/scripts" || exit


case $# in 0)
	printf %s\\n "see --help for usage" >&2
  exit 1
esac

unset GIT_SCRIPTS_OPT_EDIT
case $1 in
--help)
	printf %s\\n \
		"Usage: git run [--edit|-e] <SCRIPT NAME>" \
		"       git run <--list|-l>" \
	;
	exit
	;;
--list|--ls|-l)
	shift
	exec ls "$@" "$GIT_SCRIPTS_DIR"
	exit
	;;
--edit|-e)
	shift
	GIT_SCRIPTS_OPT_EDIT=''
	;;
esac


# Source the specified script from the .git/scripts directory

GIT_SCRIPT_NAME="$1"; shift
GIT_SCRIPT_PATH="$GIT_SCRIPTS_DIR/$GIT_SCRIPT_NAME"


case ${GIT_SCRIPTS_OPT_EDIT+x} in x)
	[ -d "${GIT_SCRIPT_PATH%/*}" ] || mkdir -pv -- "${GIT_SCRIPT_PATH%/*}"
	exec "${EDITOR:-vi}" "$GIT_SCRIPT_PATH"
	exit
esac


[ -f "$GIT_SCRIPT_PATH" ] || {
	printf %s\\n >&2 "Script '$GIT_SCRIPT_NAME' not found"
	exit 1
}


source "$GIT_SCRIPT_PATH"
