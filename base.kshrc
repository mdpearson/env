#!/bin/ksh
#
# Copyright (c) 2001-5 Matthew Pearson <mdp@matmo.net>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/GPL/2.0/ for more details.
#
# $Id: base.kshrc,v 1.7 2011/05/23 22:00:27 mdp Exp $
# shell commands executed each time a ksh (not bash) shell is invoked
#

#
# bash, on linux, sometimes masquerades as /bin/sh. In that case it
# behaves like ksh (?) and sources ENV, ending up here. Redirect to
# .bashrc where it belongs.
#
if [ "$BASH" ]
then
	. $HOME/.bashrc
	return
fi

# stop if shell is not interactive, or isn't really ksh
[ -o interactive ] || return

[ -f $HOME/.common.ksh ] && . $HOME/.common.ksh

# override builtin cd and pwd commands to update terminal title
cda=$(type cd | awk '/alias/ { print $NF }')
pwda=$(type pwd | awk '/alias/ { print $NF }')
[ "$cda" ] && eval unset -f $cda
[ "$pwda" ] && eval unset -f $pwda
unalias cd pwd
unset cda pwda

stamp=$(echo ${RANDOM}_${SECONDS} | sed 's/\.//')
eval function __cd_${stamp} '{
	command cd $*
	update_title
}'
eval function __pwd_${stamp} '{
	command pwd $*
	update_title
}'

alias cd=__cd_${stamp}
alias pwd=__pwd_${stamp}

unset stamp

if [ $USER = 'root' ]
then
	pchar='#'
else
	pchar='\$'
fi

export PS1='${HOST}'" ksh|! ${USER} "${pchar}" "
export PS2='> '
export PS4='+ '
unset pchar

set +o bgnice
set -o emacs
set +o ignoreeof
set -o markdirs
set -o noclobber

alias __A=$(print )	# Up-arrow grabs previous command from history
alias __B=$(print )	# Down-arrow grabs next command from history
alias __C=$(print )	# Right-arrow moves right one character
alias __D=$(print )	# Left-arrow moves left one character

#EOF __TAGGED__
