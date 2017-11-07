#!/bin/ksh
#
# Copyright (c) 2001-2016 Matthew Pearson <matthewpearson@gmail.com>.
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

is_remote_tty()
{
	wholine=`who -m --lookup 2>/dev/null`
	[ $? -eq 0 ] || wholine=`who -m`
	[ ! "$wholine" ] || \
	[ "$(echo \"$wholine\" | cut -sd\( -f 2 | \
	  sed -e 's/[:0.)]//g' -e 's/unix//')" ] && echo 1 || echo ""
}

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
	# printf ']2;%s'"		# SunOS only
	#
	set_terminal_title()
	{
		printf '\033]2;%s\007' "$*"	# works on most systems
	}

	set_tab_title()
	{
		printf '\033]1;%s\007' "$*"	# works on iterm2
	}

	update_titles()
	{
		_ppath=$(echo "$PWD" | sed -e 's|\([^/]\)$|\1/|' \
		  -e 's|.\{1,\}\(\(/[^/]*\)\{4,4\}\)$|...\1|')

		if [ "$THOST" ] && [ "$THOST" != "$HOST" ]
		then
			_host="$THOST"
		else
			_host="$HOST"
		fi

		if [ "$USER" != __G_USER__ ] || [ "$USER" = "admin" ]
		then
			_string="$USER@$_host"
		else
			_string="$_host"
		fi

		_string="$_string:$_ppath"

		[ "$WSNAME" ] && [ "$WSNAME" != "None" ] && _string="$_string — $WSNAME"

		# XXX update this to be more informative
		if [ `is_remote_tty` ]
		then
			set_tab_title $(printf "$_host") `basename $PWD`
		else
			set_tab_title "localhost" `basename $PWD`
		fi

		set_terminal_title $(printf '%s\n' "$_string")

		unset _host _ppath _string
	}
else
	set_terminal_title() { :; }
	set_tab_title() { :; }
	update_titles() { :; }
fi

update_titles

redo()
{
	deactivate 2>/dev/null
	hash -r
	PATH=$PATH
	_ENV_PROFILED="" . ${HOME}/.${_shell}rc
	autoenv_init

	# there are lots of reasons to not call xrdb
	if [ "$USER" != "root" ] && [ -r "$XENVIRONMENT" ] && [ "$DISPLAY" ]
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
