#!/bin/sh

NEW_LINE=${NEW_LINE:-"
"}

IFS=$NEW_LINE


log_lvl1=''
unset log_lvl2 log_lvl3
unset log_lvl5
log_lvl5=''

case $1 in
--help)
	printf %s\\n "Usage: ${0##*/} [--log-level=0..3 (default is 1)] [PATH]..."
	;;
--log-level=*)
	log_lvl=${1#*=}
	case $log_lvl in
		0) ;;
		1) log_lvl1='';;
		2) log_lvl1=''; log_lvl2='';;
		3) log_lvl1=''; log_lvl2=''; log_lvl3='';;
		*) printf %s\\n "invalid log leve argument"; exit 2;;
	esac
	shift
esac

errs=0


uncommited=''
differs_from_remote=''

git_get_latest_commit_hash() {
	git log -n 1 --pretty=format:"%H" "$@"
}
git_get_current_branch() {
	git rev-parse --abbrev-ref HEAD
}

git_get_remote_branch_with_hash() {
	git branch  --format='%(objectname) %(refname)' -r
}
git_get_all_branch_with_hash() {
	git branch  --format='%(objectname) %(refname)' -a
}



case $# in 0)
	set -- [a-zA-Z_]*/raw/*
esac
set -f
set -eu
for dir_repo; do
	${log_lvl3+echo} ${log_lvl3+:}
	${log_lvl3+pwd}
	cd -- "$dir_repo" || {
		continue
		errs=$(( errs + 1 ))
	}
	if ! [ -e .git ]; then # note: *.git* might not be a dir, for example when using `git worktree`
		case ${log_lvl1+x} in x)
			printf %s\\n  >&2 "NOTE: not a git repo: $dir_repo"
		esac
		cd "$OLDPWD" || exit; continue
	fi
	case ${log_lvl1+x} in x)
		echo >&2 -- "$dir_repo" --
	esac

	run_git_status=1

	_uncommited=$(git status -s)
	case $_uncommited in ?*)
		uncommited=${uncommited}${uncommited:+$NEW_LINE}"${dir_repo}:${NEW_LINE}$(echo "${_uncommited}" | sed 's/^/  /' )${NEW_LINE}"
		run_git_status=0
	esac

	branch=$(git_get_current_branch)
	local_hash=$(git_get_latest_commit_hash) # same as: git_get_latest_commit_hash "$_branch"
	_differs_from_remote__same=0
	_differs_from_remote__differ=0
	_differs_from_remote__differ_str=''
	#for _remote_branch in $( git branch -r  | sed 's/^ *//; s/ *$//' | grep -v '/HEAD$' ); do
	for remote_hb in $( git_get_remote_branch_with_hash | grep -v '/HEAD$' ); do
		remote_branch=${remote_hb#*" "}
		remote_hash=${remote_hb%"$remote_branch"}

		case ${log_lvl3+x} in x)
			printf %s\\ >&2 \
				"remote_branch=$remote_branch" \
				"remote_hash=$remote_hash" \
			;
		esac

		case $remote_branch in */"$branch") ;; *)
			case ${log_lvl2+x} in x)
				printf %s\\n >&2 "note: not remote_branch='$remote_branch' is for this local branch local_branch='$branch' --> '$remote_branch' is not in */'$branch'"
			esac
			####case ${log_lvl5+x} in x)
			####	printf %s\\n >&2 " @1@  PWD='$PWD'  OLDPWD='$OLDPWD'"
			####esac
			####cd "$OLDPWD" || exit; pwd; 
			continue
		esac
		case $remote_hash in
			'') printf %s\\n >&2 "warning: can not git_get_latest_commit_hash for branch '$remote_branch' for: $dir_repo";;  # warning is not a log, do not add `${log_lvl?:+`
			"$local_hash") _differs_from_remote__same=$((   _differs_from_remote__same   + 1 ));;
			*)                                    _differs_from_remote__differ=$(( _differs_from_remote__differ + 1 )); run_git_status=0; _differs_from_remote__differ_str="$_differs_from_remote__differ_str  $remote_branch";;
		esac
	done

	case ${_differs_from_remote__differ}:${_differs_from_remote__same} in
	0:0)
		printf %s\\n >&2 "warning: can not detect any remote branches for: $dir_repo"  # warning is not a log, do not add `${log_lvl?:+`
		;;
	0:*)
		# all ok
		;;
	*)
		differs_from_remote=${differs_from_remote}${differs_from_remote:+$NEW_LINE}"${dir_repo}: ${_differs_from_remote__differ} repos differ:${NEW_LINE}$(git_get_all_branch_with_hash)${NEW_LINE}"
		run_git_status=0
	esac
	#

	case $run_git_status in 1)
		git status
		echo
		echo
	esac

	cd "$OLDPWD" || exit
done >&2


printf %s\\n "" --------

case ${uncommited:+x}:${differs_from_remote:+x} in
x:x)
	printf %s\\n "" "$uncommited" "" "$differs_from_remote"
	;;
*x*)
	printf %s\\n "" "${uncommited}${differs_from_remote}"
	;;
esac

case $errs in 0) ;; *)
	case "${uncommited:+$NEW_LINE}${differs_from_remote:+x}" in
		:x) printf \\n;;
		x:|x:x) printf \\n\\n;;
	esac
	printf %s\\n >&2 "errors count: ${errs}"
	exit 1
esac
