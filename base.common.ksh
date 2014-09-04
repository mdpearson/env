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

if [ "__G_REMOTE_WS__" ]
then
	CDPATH=.:${HOME}:__G_REMOTE_WS__:__G_WORKSPACE__
else
	CDPATH=.:${HOME}:__G_WORKSPACE__
fi
unset MAILCHECK

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
			_string=$(printf '%s@%s %s\n' "$USER" \
			  "${THOST}" "$_ppath")
		else
			_string=$(printf '%s@%s %s\n' "$USER" \
			  "${HOST}" "$_ppath")
		fi
		label "$_string"
		unset _ppath _string
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
