#!/bin/bash
#
# Copyright (c) 2005-2015 Matthew Pearson <matthewpearson@gmail.com>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# $Id$
# sort and remove duplicates from history file on shell exit
#

[ -f "$HISTFILE" ] || return

. "$HOME/.isinstalled"

if [ `isinstalled python` ]
then
	uniq_history $HISTFILE $HISTFILE.tmp.$$
else
	cat $HISTFILE | sort -u >| $HISTFILE.tmp.$$
fi

mv -f $HISTFILE.tmp.$$ $HISTFILE

#EOF __TAGGED__
