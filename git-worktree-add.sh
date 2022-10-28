#!/bin/sh

_git_worktree_add() {



case $1 in --help)
	printf %s\\n "Usage: ${0##*/} <path> [<commit-ish>]"
	return
esac

case $# in
	0)         printf %s\\n >&2 "too fel args, see --help for usage" ; return 2;;
	[3-9]|??*) printf %s\\n >&2 "too many args, see --help for usage"; return 2;;
esac

case $1    in -*) printf %s\\n >&2 'no opts, see --help'; return 2; esac
case ${2-} in -*) printf %s\\n >&2 'no opts, see --help'; return 2; esac


# TODO: detect if PWD is git dir AND worktree


git worktree add -d "$1" || return
cd "$1" || return # yes, `cd` in main interactive shell
git switch --orphan "${2-${1##*/}}" || return



}

case ${0##*/} in git-worktree-add.sh)
	_git_worktree_add "$@"
esac
