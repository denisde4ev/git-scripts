#!/bin/sh

NEW_LINE=${NEW_LINE:-"
"}

IFS=$NEW_LINE


logLvl1=''
unset logLvl2 logLvl3
#unset logLvl5
#logLvl5=''

case $1 in
--help)
	printf %s\\n "Usage: ${0##*/} [--log-level=0..3 (default is 1)] [PATH]"
	;;
--log-level=*)
	logLvl=${1#*=}
	case $logLvl in
		0) unset logLvl1 logLvl2 logLvl3;;
		1) logLvl1=''; unset logLvl2 logLvl3;;
		2) logLvl1=''; logLvl2=''; unset logLvl3;;
		3) logLvl1=''; logLvl2=''; logLvl3='';;
		*) printf %s\\n "invalid log leve argument"; exit 2;;
	esac
	shift
esac


git_getCurrentBranch() { git rev-parse --verify --abbrev-ref HEAD; }
git_isMerging() {        git rev-parse --verify -q           MERGE_HEAD; }  # todo use this fn
git_isCherriPicking() {  git rev-parse --verify -q           CHERRY_PICK_HEAD; }  # todo use this fn
git_getLatestCommitHash() { git log -n 1 --pretty=format:"%H" "$@"; }
git_getAllRemoteBranchWithHash() { git branch  --format='%(objectname) %(refname)' -r; }
git_getAllBranchWithHash() {       git branch  --format='%(objectname) %(refname)' -a; }

die() {
	printf %s\\n "${0##*/}: $1" >&2
	exit ${2-2}
}

case $# in
0)
	;;
1)
	cd "$1" || exit
	;;
*)
	die "too many arguments, see --help"
esac
set -f
set -eu


errs=0

uncommited=''
reposDiffersFromRemote_str=''


set +f;for repoDir in ./[a-zA-Z_]*/raw/*; do # note use PWD as root path to enshure no lose relative paths in `loop { cd ./foo; }` (test if neeeded?)
	set -f
	${logLvl3+echo} ${logLvl3+": begin loop for '$repoDir' :"} >&2
	${logLvl3+pwd} >&2
	cd -- "$repoDir" || {
		continue
		errs=$(( errs + 1 ))
	}
	if ! [ -e .git ]; then # note: *.git* might not be a dir, for example when using `git worktree`
		case ${logLvl1+x} in x)
			printf %s\\n  >&2 "NOTE: not a git repo: $repoDir" ""
		esac
		cd "$OLDPWD" || exit; continue
	fi
	case ${logLvl1+x} in x)
		echo >&2 -- "$repoDir" --
	esac

	run_git_status=1

	_uncommited=$(git status -s)
	case $_uncommited in ?*)
		uncommited=${uncommited}${uncommited:+$NEW_LINE}"${repoDir}:${NEW_LINE}$(echo "${_uncommited}" | sed 's/^/  /' )${NEW_LINE}"
		run_git_status=0
	esac

	branch=$(git_getCurrentBranch)
	localHash=$(git_getLatestCommitHash) # same as: git_getLatestCommitHash "$_branch"
	localFiles_noChange=0
	localFiles_differ=0
	localFiles_differ_str=''
	#for _remoteBranch in $( git branch -r  | sed 's/^ *//; s/ *$//' | grep -v '/HEAD$' ); do
	for remote_hb in $( git_getAllRemoteBranchWithHash | grep -v '/HEAD$' ); do
		remoteBranch=${remote_hb#*" "}
		remoteHash=${remote_hb%"$remoteBranch"}

		case ${logLvl3+x} in x)
			printf %s\\ >&2 \
				"remoteBranch=$remoteBranch" \
				"remoteHash=$remoteHash" \
			;
		esac

		case $remoteBranch in */"$branch") ;; *)
			case ${logLvl2+x} in x)
				printf %s\\n >&2 "note: not remoteBranch='$remoteBranch' is for this local branch localFiles_branch='$branch' --> '$remoteBranch' is not in */'$branch'"
			esac
			####case ${logLvl5+x} in x)
			####	printf %s\\n >&2 " @1@  PWD='$PWD'  OLDPWD='$OLDPWD'"
			####esac
			####cd "$OLDPWD" || exit; pwd;
			continue
		esac
		case $remoteHash in
			'') printf %s\\n >&2 "warning: can not git_getLatestCommitHash for branch '$remoteBranch' for: '$repoDir'";;  # warning is not a log, do not add `${logLvl?:+`
			"$localHash") localFiles_noChange=$(( localFiles_noChange + 1 ));;
			*)              localFiles_differ=$(( localFiles_differ   + 1 )); run_git_status=0; localFiles_differ_str="'$localFiles_differ_str'  '$remoteBranch'";;
		esac
	done

	case ${localFiles_differ}:${localFiles_noChange} in
	0:0)
		printf %s\\n >&2 "warning: can not detect any remote branches for: '$repoDir'" ""  # warning is not a log, do not add `${logLvl?:+`
		;;
	0:*)
		# all ok
		;;
	*)
		reposDiffersFromRemote_str=${reposDiffersFromRemote_str}${reposDiffersFromRemote_str:+$NEW_LINE}"'${repoDir}': ${localFiles_differ_str} repos differ:${NEW_LINE}$(git_getAllBranchWithHash)${NEW_LINE}"
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

case ${uncommited:+x}:${reposDiffersFromRemote_str:+x} in
x:x)
	printf %s\\n "" "$uncommited" "" "$reposDiffersFromRemote_str"
	;;
*x*)
	printf %s\\n "" "${uncommited}${reposDiffersFromRemote_str}"
	;;
esac

case $errs in 0) ;; *)
	case "${uncommited:+$NEW_LINE}${reposDiffersFromRemote_str:+x}" in
		:x) printf \\n;;
		x:|x:x) printf \\n\\n;;
	esac
	printf %s\\n >&2 "errors count: ${errs}"
	exit 1
esac
