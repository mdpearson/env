#!/bin/sh
#
# Copyright (c) 2000-5 Matthew Pearson <mdp@matmo.net>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/GPL/2.0/ for more details.
#
# $Id: filter.sh,v 1.5 2009/07/10 17:17:43 mdp Exp $
# replaces vars in dotfiles and scripts with their assigned values
#

PATH=.	# for sourcing from current directory

if [ $# -eq 2 ]
then
	[ -f $1 ] && [ -f $2 ] || exit 1
	conf1=$1
	conf2=""
	ffile=$2
	. $conf1
elif [ $# -eq 3 ]
then
	[ -f $1 ] && [ -f $2 ] && [ -f $3 ] || exit 1
	conf1=$1
	conf2=$2
	ffile=$3
	. $conf1
	. $conf2
else
	exit 1
fi

PATH=/usr/xpg4/bin:/bin:/usr/bin

# promote ksh scripts to bash if ksh is not available
[ -x /bin/ksh ] || sedexp="-e 's|^#!/bin/ksh|#!/bin/bash|g'"

for var in `sed -n '/^[A-Z_]*=/p' $conf1 $conf2 | sed 's/=.*//'`
do
	left=$var
	right=`eval echo '$'${var}`
	sedexp=${sedexp:+"$sedexp "}"-e 's|__${left}__|${right}|g'"
done

eval sed ${sedexp} ./$ffile

#EOF __TAGGED__
