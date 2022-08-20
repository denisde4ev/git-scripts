#!/bin/sh


YN_confirm y "Are you sure you want to run 'git fetch' for all repos in \$PWD='$PWD'/*" || exit

case $# in 0) set -- */; esac
for i; do
	i=${i%/}
	[ -d "$i/.git" ] || continue
	(
	echo -- $i --
	cd "$i" || exit
	(
		set -x 
		git fetch --append  || echo "'git fetch'  EXIT CODE: $?"
		# --append option: Append ref names and object names of fetched refs to the existing contents of .git/FETCH_HEAD.
		#                  Without this option old data in .git/FETCH_HEAD will be overwritten.

		# consider adding `git push` here ard asking if should run it when have something to commit
	)
	echo
	)
done
