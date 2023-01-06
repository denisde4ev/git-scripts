#!/bin/sh



# TODO: REPLACE/MV/MERGE THIS SCRIPT FILE WITH ../denisde4ev-packages/.update-symlinks




cd "${0%/*}" || exit


pat='.../*/raw/master' # not verry configurable, ln still have hardcoded/dup plus `$i`



unset interactive
case $1 in --help)
	case $0 in ./*) o=$0;; *) o=${0##*/}; esac

	printf %s\\n \
		"Usage: $o [-i]" \
		"  link folders from pat='$pat' to '\$PWD'='$PWD'/" \
	;
	exit
	;;
-i)
	shift
	interactive=''
esac


die() {
	printf %s\\n >&2 "$1"
	exit ${2-2}
}


case $# in 0) ;; *)
	die "too many args, see --help" 2
esac


IFS=''

testTwoArgs() { test "$1" "$2"; } # use test by only 2 args, reason: do test patten expension that can result in many args

testTwoArgs -d $pat || die "not a dir: '$pat'" 3

for i in $pat; do
	i=${i%/raw/master}
	i=${i##*/}
	[ ! -L "$i" ] || continue
	ln -snT -v${interactive+i} -- ".../$i/raw/master" ./"$i"
done
