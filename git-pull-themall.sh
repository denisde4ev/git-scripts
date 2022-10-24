#!/bin/sh


YN_confirm y "Are you sure you want to run 'git pull' for all repos in \$PWD='$PWD'/*" || exit

for i in *; do
	[ -d "$i/.git" ] || continue
	(
	echo -- $i --
	cd "$i" || exit
	(
		set -x 
		git pull || echo "'git status' EXIT CODE: $?"
		git status  || echo "'git status' EXIT CODE: $?"
		# consider adding `git push` here ard asking if should run it when have something to commit
	)
	echo
	)
done
