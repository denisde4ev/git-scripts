#!/bin/sh


# this scripts makes no sense since `git worktree remove .` works...! 
# I just made it by removing many lines from git-worktreeAndBranch-remove.sh 

_git_worktree_remove() {


case ${1-} in --help)
	printf %s\\n \
		"Usage: ${0##*/} [-f|--force] [worktree]" \
		"if no [worktree] specifyed, then will assume \$PWD." \
		"\"-f, --force   force removal even if worktree is dirty or locked\"" \
	;
	return
esac

# TODO: detect if PWD is git dir AND worktree


case $#:${1-} in 0:|1:-*)
	set -- "$PWD"
esac


git worktree remove "$@" || return



}

case ${0##*/} in git-worktree-remove.sh)
	_git_worktree_remove "$@"
esac
