#!/bin/bash
#
# Copyright (c) 2005-7 Matthew Pearson <mdp@matmo.net>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/GPL/2.0/ for more details.
#
# $Id: base.bash_logout,v 1.4 2007/08/01 15:55:33 mdp Exp $
# sort and remove duplicates from history file on shell exit
#

[ -f "$HISTFILE" ] || return

type python 2>&- >&-

if [ $? -eq 0 ]
then
	uniq_history $HISTFILE $HISTFILE.tmp.$$
else
	cat $HISTFILE | sort -u >| $HISTFILE.tmp.$$
fi

mv -f $HISTFILE.tmp.$$ $HISTFILE

#EOF __TAGGED__
