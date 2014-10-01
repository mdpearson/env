#!/bin/bash
#
# Copyright (c) 2000-2014 Matthew Pearson <matthewpearson@gmail.com>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# $Id$
# shell commands executed each time a bash shell is invoked
#

# don't run if shell is not interactive
echo $- | fgrep -s i > /dev/null
[ $? -eq 0 ] || return

# run .bash_logout for all shells, not just login ones
trap "[ -f $HOME/.bash_logout ] && . $HOME/.bash_logout" EXIT

#
# This file may be sourced by the user running under a different uid;
# e.g., root or gk. In that case, we need to override HOME in order
# to source other files like .profile and .common.ksh properly. Once
# these files are loaded in, we can restore HOME to its previous value.
#
if [ ! "$HOME" ] || [ "$(basename $HOME)" != __G_USER__ ]
then
	old_home=$HOME				# cache old HOME
	# first, check NIS for the proper passwd entry
	passl=$(ypcat passwd 2>&- | grep "^__G_USER__:")
	# check local passwd file if nis lookup fails
	[ "$passl" ] || passl=$(grep "^__G_USER__:" /etc/passwd 2>&-)
	HOME=$(echo "$passl" | awk -F: '{print $6}' 2>&-)

	# unreliable: last resort
	if [ ! "$HOME" ]
	then
		if [ `uname -s` = 'Darwin' ]
		then
			HOME=/Users/__G_USER__
		else
			HOME=/home/__G_USER__
		fi
	fi

	export HOME
fi

# load up commands common to bash and ksh
[ -f $HOME/.common.ksh ] && . $HOME/.common.ksh
[ -f $HOME/.inputrc ] && export INPUTRC=$HOME/.inputrc

# create a unique history file for each host
[ -d $HOME/.bash_histories ] || mkdir $HOME/.bash_histories
if [ "$THOST" ]
then
	HISTFILE=$HOME/.bash_histories/$THOST
else
	HISTFILE=$HOME/.bash_histories/$HOST
fi

if [ -d $HOME/.autoenv ]
then
	. $HOME/.autoenv/activate.sh
else
	alias autoenv_init=
fi

HISTCONTROL=ignoredups
HISTSIZE=$((64 * 1024 - 1))
HISTFILESIZE=$((64 * 1024 - 1))
[ -f $HISTFILE ] || touch $HISTFILE

TIMEFORMAT="		elapsed: %lR @ %P""%% (u:%lU|s:%lS)"

function init_bash_prompt
{
	if [ "$THOST" ] && [ "$THOST" != "$HOST" ]
	then
		nn=$THOST
		dn=
	else
		nn=$HOST
		dn=
	fi

	shellabbr=`basename $SHELL`
	[ "$BASH" ] && shellabbr='bash'
	if [ $USER = 'root' ]
	then
		pchar='#'
	else
		pchar='\$'
	fi

	if [ "$BUTTONS" ]
	then
		PS1="\h console \$ "
	elif [ "$TERM" ] && [ -f $HOME/.dircolors ] && \
	  [ $(grep -c "[^-a-z]$TERM$" $HOME/.dircolors) -eq 1 ]
	then
		#
		# attribute codes:
		#  00=none 01=bold 02=dim 04=u-line 05=blink 07=rev 08=hidden
		# text color codes [add 10 for background color]:
		#  30=blk 31=red 32=grn 33=yel 34=blu 35=mag 36=cyn 37=wht
		# separate multiple codes with semicolons.
		#

		wholine=`who -m --lookup 2>&-`
		[ $? -eq 0 ] || wholine=`who -m`

		if [ $USER != __G_USER__ ]
		then			# running as different user:
			uf='31;01'		# bold, red user
			pf='31;01'		# bold, red prompt
			hf='31;04;01'	# bold, red, underlined hostname
		elif [ "$(echo \"$wholine\" | cut -sd\( -f 2 | \
		  sed -e 's/[:0.)]//g' -e 's/unix//')" ]
		then			# remote host:
			uf='30;01'		# bold, black user
			pf='30;01'		# bold, black prompt
			hf='30;04;01'	# bold, black, underlined hostname
		else			# local:
			uf='30;01'		# bold, black user
			pf='30;01'		# bold, black prompt
			hf='30;01'		# bold, black, hostname
		fi

		userstr="\[\e[${uf}m\]\u\[\e[0m\]"
		hoststr="\[\e[${hf}m\]$nn\[\e[0m\]${dn:+:$dn}"
		histstr="\[\e[02m\]\!\[\e[0m\]"
		hashstr="\[\e[${pf}m\]"${pchar}"\[\e[0m\]"
		PS1=${hoststr}" "${shellabbr}"|"${histstr}" "${userstr}" "${hashstr}" "

		unset pf uf hf userstr hoststr infostr hashstr wholine
	else
		PS1="$nn${dn:+:$dn} "${shellabbr}"|\! \u $pchar "
	fi

	export PS1
	unset nn dn shellabbr pchar timestamp
}

# tasks that should run each time a command completes
function prompt_update
{
	_val=$?
	update_title
	if [ "$_val" ] && [ $_val -ne 0 ]
	then
		[ "$_pre" ] || _pre=`tput smul 2>&-`
		[ "$_post" ] || _post=`tput sgr0 2>&-`

		_cno=$(($HISTCMD-1))
		_cmd=$(history | sed -ne '/^ *'$_cno'/,/.*/p' | \
			awk 'NR == 1 {
				sub(" *"$1" *","")
				line=$0
			} END {
				if (NR > 1) {
					printf("%s ...", line)
				} else {
					print line
				}
			}' )
		printf '  %s: %s  %s: %s  %s: %s\n' \
		  "${_pre}errno${_post}" "${_val}" \
		  "${_pre}cmdno${_post}" "${_cno}" \
		  "${_pre}cmd${_post}" "${_cmd}"
		unset _cno _cmd
	fi
	return $_val	# return original $? (error code)
}

# automatically call ls after cd if the listing is six lines or less
function cd_wrapper
{
	thispwd=$PWD
	
	if [ $(echo $* | grep -c '^[0-9]\{6,9\}$') -eq 1 ]
	then
		# it's a Broad Institute job directory
		last3=$(echo $* | sed 's/.*\([0-9]\{3,3\}\)$/\1/')
		first=$(echo $* | sed "s/$last3\$//")
		dest="/seq/annotation/prod/jobs/$first/$*"
		eval builtin cd $dest >&-
	else
		eval builtin cd "${1+\"$*\"}" >&-
	fi

	if [ "$thispwd" != "$PWD" ]
	then
		echo "cd: working directory now $PWD"
		[ $(truels -C | wc -l) -le 6 ] && ls
		unset fcnt
		autoenv_init
	fi
	unset dest first last3 thispwd
}
alias cd='cd_wrapper'

function list_cdable_dirs
{
	local cur=${COMP_WORDS[COMP_CWORD]}
	local k=${#COMPREPLY[@]}

	for cdd in ${CDPATH//:/$'\t'}
	do
		if [ "$(echo $cur | cut -c 1)" = "/" ]
		then
			wd=$cur
		else
			wd=$cdd/$cur
		fi

		comps=$(compgen -o nospace -d "$wd")
		scrambled_comps=${comps// /:}

		for scrambled_comp in $scrambled_comps
		do
			unscrambled_comp=${scrambled_comp//:/\\ }
			trimmed_comp=${unscrambled_comp#${cdd}/}
			if [ "$trimmed_comp" ]
			then
				COMPREPLY[k++]=${trimmed_comp}/
			fi
		done
	done
}

init_bash_prompt
PROMPT_COMMAND=prompt_update

set -b					# immediately notify of terminated processes
set -C					# i.e., noclobber
set -o posix			# do the right thing
set -P					# cd ../ follows physical not logical structure

shopt -s cdspell		# look for minor typos in cd cmds
shopt -s cmdhist		# save multiline cmds in one hist entry
shopt -s checkwinsize	# update LINES and COLUMNS more often
shopt -s histappend		# save history across sessions
shopt -s histreedit		# edit failed history changes
shopt -s histverify		# print changed cmd before running
shopt -u huponexit		# don't send SIGHUP to children on exit
shopt -s lithist		# save multiline commands with newlines
shopt -u sourcepath		# don't use PATH for `.' commands

# the following shopts work only for 2.05 or greater
shopt -s no_empty_cmd_completion 2>&-	# don't freeze on an accidental tab
shopt -s xpg_echo 2>&-					# use xpg4 semantics for echo
[ $? -eq 0 ] || alias echo="/bin/echo"	# use /bin/echo if above fails

# command-line completion
complete -F list_cdable_dirs -o nospace cd pushd
complete -f -X '*$py.class' bbedit bbdiff diff edit open twedit

if [ "$old_home" ]
then
	HOME=$old_home
	unset old_home
fi

#EOF __TAGGED__
