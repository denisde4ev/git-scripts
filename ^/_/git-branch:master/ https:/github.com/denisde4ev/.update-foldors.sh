#!/bin/sh

cd "${0%/*}"

pat='/^/ https://github.com/denisde4ev/*/raw/master'


echo >&2 "$0: not tested but sh. should work.. I hope"
echo >&2

	unset interactive
case $1 in --help)
	case $0 in ./*) o=$0;; *) o=${0##*/}; esac

	printf %s\\n \
		"Usage: $o [-i] [... repo name or path]" \
		"  link folders from pat='$pat' to '\$PWD'='$PWD'/" \
	;
	exit
	;;
-i)
	shift
	interactive=''
esac


case $PWD in 
'/^/_/git-branch:master/ https:/github.com/denisde4ev') ;;
'/^/_/git-branch:master/ https://github.com/denisde4ev') ;;
*)
	case ${interactive+i} in
		i) YN_confirm y "Do you realy want to create symlinks in \$PWD='$PWD'" || exit;;
		*) printf %s "warning: \$PWD='$PWD' not as expected" >&2;;
	esac
esac

ln_it() {
	j=${1%/raw/master}
	j=${j##*/}
	[ ! -e "$j" ] || {
		printf %s\\n "link $j already exists." >&2
		return
	}
	ln -snT -v${interactive+i} -- ".../$j/raw/master" ./"$j"
}


exists() { [ -e "$1" ]; }


case $# in 0)
	IFS=''

	exists $pat || {
		printf %s\\n "no files in pat='$pat'"
		exit
	}
	
	for i in $pat; do
		ln_it "$i"
	done
	exit
esac
# else: provided arguments:



# Ahh.. this case with provided arguments
# will raely be used.
# Have I overdone it?
# Nahh..
#
# ah yes I did't even tought thsi scritp is going to be used in scripts
# now.. I have added a -i option for that ..


YN() {
	case ${interactive+i} in
		i) YN_confirm --printf y %s\\n "$1." "Do you want to link it?";;
 		*) printf %s\\n "$1" >&2; return 6;; # just a note: exit code 5 is when YN_confirm can't read input
	esac
}


x=1 # when nothing is created will exit with 1
for i; do

	case $i in 
		$pat) ;;
		*/*)
			case ${interactive-0} in 0)
				YN "arg: '$i' is not in expected pattern: '$pat'" \
				|| continue
			esac
		;;
		*) i="/^/ https://github.com/denisde4ev/$i/raw/master";;
	esac

	[ -d "$i/.git" ] || {
		if [ -d "$i" ]; then
			YN "Dir i='$i' does not exist"
		else
			YN "Dir i='$i' is not a git repository (./.git folder does not exist)"
		fi || continue
	}

	ln_it "$i"
	x=$?

done
exit "$x"
