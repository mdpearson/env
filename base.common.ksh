#!/bin/ksh
#
# Copyright (c) 2001-2014 Matthew Pearson <matthewpearson@gmail.com>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# $Id$
# shell commands executed each time a bash or ksh shell starts
#

[ -f $HOME/.profile ] && . $HOME/.profile

CDPATH=.:${HOME}
unset MAILCHECK

if [ -d $HOME/.autoenv ]
then
	. $HOME/.autoenv/activate.sh
else
	alias autoenv_init=
fi

# internal variable used by update_title and redo
if [ "$BASH" ]
then
	_shell=bash	# some bashes id themselves as /bin/sh
else
	_shell=$(basename $SHELL)
fi

if [[ $TTY != *console ]] &&
  [ "$TERM" ] && [ -f $HOME/.dircolors ] && \
  [ $(grep -c "[^-a-z]$TERM$" $HOME/.dircolors) -eq 1 ]
then
	#
	# other ways of setting the terminal title:
	# ^[ is an ansi escape (^Q-esc); ^G is a bell (^Q-^G)
	#
	# printf '\e]2;%s\a'		# bash only
	# printf '\033]2;%s\033'	# darwin only
	# printf ']2;%s'"			# SunOS only
	#
	label()
	{
		printf '\033]2;%s\007' "$*"	# works on most systems
	}

	update_title()
	{
		_ppath=$(echo "$PWD" | sed -e 's|\([^/]\)$|\1/|' \
		  -e 's|.\{1,\}\(\(/[^/]*\)\{4,4\}\)$|...\1|')

		if [ "$THOST" ] && [ "$THOST" != "$HOST" ]
		then
			_host="$THOST"
		else
			_host="$HOST"
		fi

		if [ "$USER" != "__G_USER__" ]
		then
			_string="$USER@$_host"
		else
			_string="$_host"
		fi

		_string="$_string:$_ppath"

		[ "$WSNAME" ] && [ "$WSNAME" != "None" ] && _string="$_string — $WSNAME"

		label $(printf '%s\n' "$_string")
		unset _host _ppath _string
	}
else
	label() { :; }
	update_title() { :; }
fi

update_title

redo()
{
	hash -r
	PATH=$PATH
	PROFILED=false . ${HOME}/.${_shell}rc
	autoenv_init

	# there are lots of reasons to not call xrdb
	if [ $USER != 'root' ] && [ -r "$XENVIRONMENT" ] && [ "$DISPLAY" ]
	then
		xrdb -remove
		xrdb -load $XENVIRONMENT
	fi
}

# append the current working directory to the end of the path
adddot()
{
	export PATH=$(echo $PATH | sed -e 's/:\.//g'):.
}

#EOF __TAGGED__
