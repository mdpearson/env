#!/bin/bash
#
# Copyright (c) 2000-2015 Matthew Pearson <matthewpearson@gmail.com>.
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

if [ -f "${HOME}/.git-prompt.sh" ]
then
	. "${HOME}/.git-prompt.sh"
	GIT_PS1_SHOWCOLORHINTS=1
#	GIT_PS1_SHOWDIRTYSTATE=1
#	GIT_PS1_SHOWSTASHSTATE=1
	GIT_PS1_SHOWUPSTREAM="auto verbose"
else
	echo " (you may want to install git-prompt)" >&2
fi

if [ -f "${HOME}/.git-completion.bash" ]
then
	. "$HOME/.git-completion.bash"
elif [ -f "${HOME}/.git-prompt.sh" ]
then
	echo " (you may want to install git-completion)" >&2
fi

if [ -f "${HOME}/opt/stderred/build/libstderred.dylib" ]
then
	if [ ! "$DYLD_INSERT_LIBRARIES" ]
	then
		export DYLD_INSERT_LIBRARIES="${HOME}/opt/stderred/build/libstderred.dylib${DYLD_INSERT_LIBRARIES:+:$DYLD_INSERT_LIBRARIES}"
	fi
fi

if [ -f "${HOME}/opt/stderred/build/libstderred.so" ]
then
	if [ ! "$LD_PRELOAD" ]
	then
		export LD_PRELOAD="${HOME}/opt/stderred/build/libstderred.so${LD_PRELOAD:+:$LD_PRELOAD}"
	fi
fi

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
	HISTFILE=$HOME/.bash_histories/"$THOST"
else
	HISTFILE=$HOME/.bash_histories/"$HOST"
fi

HISTCONTROL=ignoredups
HISTSIZE=$((64 * 1024 - 1))
HISTFILESIZE=$((64 * 1024 - 1))
[ -f "$HISTFILE" ] || touch "$HISTFILE"

TIMEFORMAT="		elapsed: %lR @ %P""%% (u:%lU|s:%lS)"

function init_bash_prompt
{
	if [ "$THOST" ] && [ "$THOST" != "$HOST" ]
	then
		nn="$THOST"
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
			uf='31'			# red user
			pf='31;01'		# bold, red prompt
			hf='31;01'		# bold, red hostname
			include_username=1
		elif [ "$(echo \"$wholine\" | cut -sd\( -f 2 | \
		  sed -e 's/[:0.)]//g' -e 's/unix//')" ]
		then			# remote host:
			uf='34'			# blue user
			pf='32;01'		# bold, green prompt
			hf='34;01'		# bold, blue hostname
			include_username=1
		else			# local:
			uf='33'			# yellow user
			pf='32;01'		# bold, green prompt
			hf='33;01'		# bold, yellow hostname
			include_username=
		fi

		if [ "$include_username" ]
		then
			userstr=" \[\e[${uf}m\]\u\[\e[0m\]"
		else
			userstr=""
		fi
		hoststr="\[\e[${hf}m\]$nn\[\e[0m\]${dn:+:$dn}"
		histstr="\[\e[02m\]\!\[\e[0m\]"
		hashstr="\[\e[${pf}m\]"${pchar}"\[\e[0m\]"
		contstr="\[\e[${pf}m\]"\>"\[\e[0m\]"

		PS1_FIRST="${hoststr} ${shellabbr}|${histstr}${userstr}"
		PS1_SECOND="${hashstr} "
		PS1="${PS1_FIRST} ${PS1_SECOND}"
		PS2="${contstr} "

		unset pf uf hf userstr hoststr infostr hashstr wholine
	else
		PS1="$nn${dn:+:$dn} "${shellabbr}"|\! \u $pchar "
	fi

	export PS1
	unset nn dn shellabbr pchar timestamp
}

# tasks that should run each time a command completes
trap '_PREV_COMMAND=$_thiscmd; _thiscmd=$BASH_COMMAND' DEBUG

if [ "`declare -f __git_ps1`" ]
then
	#
	# __git_ps1 depends on a few global variables which can be overridden here.
	#
	# $b -- branch name or equivalent (but not accessible here)
	# $c -- set before anything prints
	# $i -- ??
	# $p -- set to [=<>] or "u-21" to indicate differences with upstream branch
	# $r -- contains "REBASE" or other terms when you are doing something complicated
	# $s -- set to "$" when the stash contains something; immediately follows workspace name
	# $u -- set to "%" when something is unstaged
	# $w -- ??
	#
	__git_ps1_colorize_gitstring ()
	{
		__GIT_PS1_AHEAD_FMT='\[\e[33m\]'		# local ahead of remote
		__GIT_PS1_BEHIND_FMT='\[\e[34m\]'		# remote ahead of local
		__GIT_PS1_BRANCH_FMT='\[\e[02m\]'		# branch name in normal circumstances
		__GIT_PS1_DETACHED_FMT='\[\e[31;01m\]'	# detached/special branch status
		__GIT_PS1_REBASE_FMT='\[\e[35m\]'		# rebase status flag
		__GIT_PS1_RESET_FMT='\[\e[0m\]'			# reset these crazy colors
		__GIT_PS1_STASH_FMT='\[\e[35m\]'		# stash status flag
		__GIT_PS1_UNTRACKED_FMT='\[\e[36m\]'	# untracked status flag

		if [ "$detached" = "yes" ]
		then
			c=$__GIT_PS1_DETACHED_FMT"$c"
		else
			c=$__GIT_PS1_BRANCH_FMT"$c"
		fi
		if [ -n "$p" ]
		then
			# adjust display of upstream/downstream state
			p=`echo "$p" | sed \
			  -e 's/^/$__GIT_PS1_RESET_FMT/' \
			  -e 's/u//' \
			  -e 's/=//' \
			  -e 's/\(\+[0-9]*\)/$__GIT_PS1_AHEAD_FMT\1$__GIT_PS1_RESET_FMT/' \
			  -e 's/\(-[0-9]*\)/$__GIT_PS1_BEHIND_FMT\1$__GIT_PS1_RESET_FMT/'`
			p=`eval echo "$p"`
		fi
		if [ -n "$r" ]
		then
			# adjust how rebase status is displayed
			r=`echo "$r" | sed \
			  -e 's/\|//' \
			  -e 's/\([A-Za-z-]*\)/${__GIT_PS1_REBASE_FMT}\1${__GIT_PS1_RESET_FMT}/'`
			r=$__GIT_PS1_RESET_FMT'|'`eval echo "$r"`
		else
			r=$__GIT_PS1_RESET_FMT"$r"
		fi
		if [ -n "$s" ]
		then
			# adjust how stashed files are flagged
			s=$__GIT_PS1_RESET_FMT$__GIT_PS1_STASH_FMT"@"
		fi
		if [ -n "$u" ]
		then
			# adjust how untracked files are flagged
			u=$__GIT_PS1_RESET_FMT$__GIT_PS1_UNTRACKED_FMT"#"
		fi
	}
fi

function prompt_update
{
	_errno=$1
	update_title
	if [ "$_errno" ] && [ $_errno -ne 0 ]
	then
		[ "$_pre_val" ] || _pre_val=`tput bold 2>&-`
		[ "$_post_val" ] || _post_val=`tput sgr0 2>&-`

		if [ "$_PREV_COMMAND" != 'prompt_update $?' ]
		then
			echo "\`${_PREV_COMMAND}\` returned error code ${_pre_val}${_errno}${_post_val}."
		fi
	fi

	[ "`declare -f __git_ps1`" ] && __git_ps1 "${PS1_FIRST} " "${PS1_SECOND}" "git|%s "
	return $_errno	# return original $? (error code)
}

# automatically call ls after cd if the listing is six lines or less
function cd_wrapper
{
	thispwd=$PWD

	eval builtin cd "${1+\"$*\"}" >&-

	if [ "$thispwd" != "$PWD" ]
	then
		# undo prompt customizations of autoenv scripts when cd'ing away
		unset OLDPS1
		WSNAME="None"
		autoenv_init

		echo "cd: working directory now $PWD"
		[ $(truels -C | wc -l) -le 6 ] && ls
	fi
	unset thispwd
}
alias cd='cd_wrapper'

init_bash_prompt
PROMPT_COMMAND='prompt_update $?'

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

. $HOME/.isinstalled
if [ `isinstalled brew` ]
then
	if [ -f $(brew --prefix)/etc/bash_completion ]; then
		. $(brew --prefix)/etc/bash_completion
	fi
fi
unset isinstalled

if [ "$old_home" ]
then
	HOME=$old_home
	unset old_home
fi

#EOF __TAGGED__
