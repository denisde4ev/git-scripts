#!/bin/sh

_git_worktreeAndBranch_remove() {



case ${1-} in --help)
	printf %s\\n \
		"Usage: ${0##*/} <--force> <--ask|--no-ask> [worktree]" \
		"note: deletes branch and worktree, both using --force." \
		"if no [worktree] specifyed, then will assume \$PWD." \
		"ask is on by default." \
	;
	return
esac


case ${1-} in --force) shift;; *)
	printf %s\\n >&2 '--force option is required!'; return 2
esac

local _git_worktreeAndBranch_remove__ask_opt
      _git_worktreeAndBranch_remove__ask_opt='' # on by default
case ${1-} in
	--ask) _git_worktreeAndBranch_remove__ask_opt=''; shift;;
	--no-ask) unset _git_worktreeAndBranch_remove__ask_opt; shift;;
esac


# case $# in 0) set -- "../${PWD##*/}"; esac

case ${1-} in -*)
	printf %s\\n >&2 'no opts, see --help'; return 2
esac

# TODO: detect if PWD is git dir AND worktree


local _git_worktreeAndBranch_remove__branch _git_worktreeAndBranch_remove__basename
unset _git_worktreeAndBranch_remove__branch _git_worktreeAndBranch_remove__basename

case $# in
	0) _git_worktreeAndBranch_remove__basename=${PWD##*/};;
	*) _git_worktreeAndBranch_remove__basename=${1##*/};;
esac
if _git_worktreeAndBranch_remove__branch=$(git rev-parse --verify --abbrev-ref HEAD); then
	case $_git_worktreeAndBranch_remove__branch in "$_git_worktreeAndBranch_remove__basename") ;; *)
		printf %s\\n >&2 \
			"branch name and basename of \$1 missmatch:" \
			"branch='$_git_worktreeAndBranch_remove__branch'" \
			"\$1(basename)='$_git_worktreeAndBranch_remove__basename'" \
		;
		${_git_worktreeAndBranch_remove__ask_opt-return 1}
		YN_confirm n 'Do you still want to continue, basename will be used for \`git branch --remove\`?' || return 1
	esac
	# TODO: trach if branch will be lost (git detection when no --force provided does not work fine)
else
	case ${_git_worktreeAndBranch_remove__branch:+x} in x)
		printf %s\\n "ERROR 1: branch='$_git_worktreeAndBranch_remove__branch', \$?=$?"
		return 4
	esac

	printf %s\\n >&2 "seems like HEAD is detached!"
	case ${_git_worktreeAndBranch_remove__ask_opt+x} in x)
		YN_confirm y \
			'Do you still want to continue,' \
			'by removing the worktree' \
			'and leaving the branch as is?' \
		|| {
			return 1
		}
	esac
	unset _git_worktreeAndBranch_remove__branch
fi



case ${_git_worktreeAndBranch_remove__branch+x} in x)
	#YN_confirm y "no branch, do you want to remove branch basename '${1##*/}'" || {
	#	break # break branch-remove
	#}
	git switch --detach || return
	git branch --delete --force -- "$_git_worktreeAndBranch_remove__basename"
esac


git worktree remove --force -- "${1-.}" || return

}

case ${0##*/} in git-worktreeAndBranch-remove.sh)
	case $1 in -x) set -x; shift; esac
	_git_worktreeAndBranch_remove "$@"
esac
