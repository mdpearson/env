#!/bin/sh
#
# Copyright (c) 2000-2014 Matthew Pearson.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# $Id$
# sh-compatible commands executed at login for sh, ksh, bash
#

# force legacy Digital systems to use a standards-compliant sh
BIN_SH=xpg4
export BIN_SH

# set up a simple path if this file has not been sourced before
[ "$PROFILED" = 'true' ] || PATH=/usr/xpg4/bin:/bin:/usr/bin:/usr/ucb

#
# First thing to do is make sure the terminal is set up correctly.
# The SHELL environment variable may be unset (or worse, set wrong) at
# this point. Later on it gets set for real, but for now it's set to a
# base value (sh) that should work for all interpreters that read this
# file (csh and friends never read a file called .profile).
#
# tset is used to get the terminal name and set it in TERM, but tput
# actually configures the terminal. Under Solaris, the two programs
# check two different databases, termcap and terminfo, which are skewed.
# (One is inherited from BSD, the other comes from System V.) Some
# obscure terminals occur in one and not the other. It's best to pick
# one that both support. Loop if necessary until the user selects a
# terminal that appears in both termcap (tset) and terminfo (tput).
#
# tput init is a expensive op and only should be done on as part of a
# login. If PROFILED is set then it is not run. Note that redo() unsets
# this value when it does a heavyweight terminal reinitialization. When
# bash shells are launched in X, the call to tput is skipped.
#
# For testing: ztx is in termcap only, xtermm is in terminfo only.
#

# override TERM setting on Darwin console shells
[ `uname -s` = 'Darwin' ] && [ `tty` = '/dev/console' ] && TERM=xnuppc

set noglob
while :
do
	eval `SHELL=sh tset -s -e ^H -IQ \
	  -m 'dtterm:dtterm' -m 'vt100:vt100' -m 'xterm:xterm' \
	  -m 'xterm-color:xterm-color' -m 'nxterm:xterm' \
	  -m 'xterm-256color:xterm-color' \
	  -m 'sun:?sun' -m 'xnuppc:?xnuppc' -m ':?xterm'`
	export TERM				# Darwin tset forgets to do this

	[ "$PROFILED" = 'true' ] && break	# terminal already set up

	tput init # heavyweight

	#
	# Error 3 means unrecognized term: loop and try again.
	# Other errors can't be fixed here. Let them fall through.
	#
	[ $? -ne 3 ] && break
done
unset noglob

#
# Make sure the SHELL environment variable is set properly. There are
# a few cases where it will not be. The most common is when bash
# is run from a csh environment where SHELL already exists. Another
# case is when su - is called from a Darwin console.
#

if [ `echo "$BASH" | grep -c 'bash$'` -eq 1 ]
then
	# if the BASH env var is set and valid, override SHELL
	if [ "$BASH" != "$SHELL" ]
	then
		#
		# If bash was instantiated as sh, it's no big deal.
		# Otherwise, print a message saying that SHELL is changing.
		#
		if [ `echo "$SHELL" | grep -c '/sh$'` -ne 1 ]
		then
			sh_oldn="$SHELL"

			printf ' %s %s%s\n' \
			  "\$SHELL environment variable clashes with \$BASH: changing" \
			  ${sh_oldn:+"from ${sh_oldn} "} "to $SHELL" >&2
			unset sh_oldn
		fi
		SHELL=$BASH
	fi
else
	#
	# Check if the currently running command is a shell name.
	# (In some cases it can be something like su or login.)
	#

	cur_cmd=`echo "$0" | sed 's/^-//'`
	if [ `echo "$cur_cmd" | grep -c 'sh$'` -eq 1 ]
	then
		sh_name=`basename "$cur_cmd"`
		sh_path=`(type "$cur_cmd" 2>&1) | awk '{ print $NF}'`
		[ -x "$sh_path" ] || unset sh_path
	fi

	#
	# If SHELL is not set or set badly, correct it. Either use
	# the shell path discovered above from $0, or /bin/sh as a
	# last resort.
	#
	if [ ! "$SHELL" ] || [ `echo "$SHELL" | grep -c 'sh$'` -eq 0 ] || \
	  [ "$sh_name" ] && [ `basename "$SHELL"` != "$sh_name" ]
	then
		sh_oldn="$SHELL"
		SHELL=${sh_path:-/bin/sh}
		printf ' %s %s%s\n' \
		  "inherited \$SHELL is incorrect: changing" \
		  ${sh_oldn:+"from ${sh_oldn} "} "to $SHELL" >&2
		unset sh_oldn
	fi
	unset sh_name sh_path
fi

export SHELL

#
# Set general environment variables.
#

HOST=`hostname | sed 's/\..*//'`	# drop domain name if present
[ "$USER" ] || USER=`whoami`
HOSTNAME=$HOST
export HOST HOSTNAME USER

if [ -f /Library/Preferences/SystemConfiguration/preferences.plist ]
then
	# set THOST to the AppleTalk (user-chosen) name on Macs
	THOST=`defaults read /Library/Preferences/SystemConfiguration/preferences.plist | \
	  grep 'ComputerName = ' | sed -e 's/^ *//' -e 's/;$//' -e 's/.* = //' -e 's/^"//' -e 's/"$//' | uniq`
	[ "$THOST" ] && export THOST
fi

COLUMNS=`tput cols`
ENV=${HOME}/.kshrc
export COLUMNS ENV

if [ -r ${HOME}/.Xdefaults ]
then
	XENVIRONMENT=${HOME}/.Xdefaults
	export XENVIRONMENT
fi

export ACK_COLOR_FILENAME="bold black"

export GIT_SSL_NO_VERIFY=1
unset SSH_ASKPASS

#
# Set/override prompt for true bourne shells.
# (bash and ksh use control chars bourne cannot parse.)
#

if [ `echo "$SHELL" | grep -c '\/sh$'` -eq 1 ] && [ ! "$BASH" ]
then
	if [ $USER = 'root' ]
	then
		pchar='#'
	else
		pchar='\$'
	fi

	PS1="${HOST} sh ${USER} (ws:None) ${pchar} "
	export PS1
	unset pchar
fi

#
# The rest of this file sets environment variables and prints out
# information useful to a user at login. It need not be run each time
# a terminal is opened but rather once per session. If the env var
# PROFILED is true, then this has already happened: skip to the end.
#

if [ "$PROFILED" != 'true' ]
then
	# define some handy path-manipulation functions

	#
	# Echoes 1 if the path exists, 0 if it does not.
	#
	# If the path is on a wedged filesystem that cannot
	# be stat'ed, *should* return 0 after printing an error.
	#
	check_path() {
		if [ ! "$1" ]
		then
			echo 0
			return
		fi

		test -d "$1" &

		# busy-wait with an incremental backoff
		cnt=0
		while [ $cnt -lt 10 ]
		do
			if [ "`jobs`" ]
			then
				arg="0.0"${cnt}"s"
				sleep $arg
			else
				break
			fi
			cnt=`expr $cnt + 1`
		done

		pid=`jobs -lp`
		if [ "$pid" ]
		then
			#
			# It shouldn't take this long to stat a dir.
			# The filesystem mount may be hosed.
			#
			printf "\n > unable to stat $1\n > killing hung job $pid\n " >&2
			kill $pid >&- 2>&-
			res=0
		else
			res=`test -d "$1" && echo 1 || echo 0`
		fi

		echo "$res"
		return
	}

	# add a directory $2 to the end of a :-separated pathlist $1
	append_path() {
		[ "$2" ] || return
		[ "$2" == null_guard ] && return
		res=`check_path "$2"`
		[ "$res" -eq 1 ] && eval $1=\${$1:+\$$1:}'$2'
		[ "$res" -eq 1 ] && printf "." >&2
#		[ "$res" -ne 1 ] && printf " " >&2
	}

	# add a directory $2 to the start of a :-separated pathlist $1
	prepend_path() {
		[ "$2" ] || return
		[ "$2" == null_guard ] && return
		res=`check_path $2`
		[ "$res" -eq 1 ] && eval $1=$2\${$1:+:\$$1}
		[ "$res" -eq 1 ] && printf "." >&2
#		[ "$res" -ne 1 ] && printf " " >&2
	}

	#
	# Slower than the above functions - use for paths whose fields
	# are unknown (to prevent adding the same directory twice).
	#
	ld_path() {
		unset arg prepend

		#
		# I can't remember how many times getopts's reliance on external shell variables
		# has bitten me. OPTIND must be set to 1 each time getopts is called. "Any other
		# attempt to invoke getopts multiple times in a single shell execution environment
		# ... produces unspecified results."
		#
		# http://pubs.opengroup.org/onlinepubs/009696799/utilities/getopts.html
		#
		OPTIND=1
		getopts f arg && prepend=y
		shift `expr $OPTIND - 1`

		[ "$2" ] || return
		[ "$2" == null_guard ] && return

		eval echo \$$1 | grep -sq "$2"

		if [ $? -ne 0 ]
		then
			if [ "$prepend" ]
			then
				res=`check_path $2`
				[ "$res" -eq 1 ] && eval $1=$2\${$1:+:\$$1}
			else
				res=`check_path $2`
				[ "$res" -eq 1 ] && eval $1=\${$1:+\$$1:}$2
			fi
			[ "$res" -eq 1 ] && printf "." >&2
#			[ "$res" -ne 1 ] && printf " " >&2
		else
			#
			# print a colon (a "double period") to indicate that the
			#  element was already present in the specified path.
			#
			printf ":" >&2
		fi
		unset arg prepend
	}

	# this function trims output to a single line
	trimline() {
		if [ `expr $COLUMNS \< 255` -eq 1 ]
		then
			lim=`expr $COLUMNS - 1`
			# next line requires xpg4 sed on SunOS
			[ "$*" ] && echo "$*" | sed -e 's/^ */ /' \
			  -e 's/\(.\{'$lim','$lim'\}\)...*/\1</' >&2
			unset lim
		else
			[ "$*" ] && echo "$*" >&2
		fi
	}

	arch=`uname -p`
	# workaround for gnu uname
	[ $arch = 'unknown' ] && arch=`uname -m`

	ost=`uname -s`
	rel=`uname -r`

	if [ $ost = 'Darwin' -o $ost = 'OSF1' ]
	then
		plat=`machine`
	else
		plat=`uname -i`
	fi

	mesg n 2>&-
	MAILCHECK=0
	TTY=`tty`
	VISUAL=emacs
	export MAILCHECK TTY VISUAL

	# AUTOMOUNT_FIXNAMES=true
	# export AUTOMOUNT_FIXNAMES

	[ "__G_PRINTER__" ] && PRINTER=__G_PRINTER__
	UT_NO_USAGE_TRACKING=1
	export PRINTER UT_NO_USAGE_TRACKING

	#
	# Make files group-writable by default on systems with
	# site-wide configuration files.
	#
	umask 0002

	#
	# Set up paths for libraries, binaries & manpages. First, set
	# up a path appropriate for the O/S and release. Once PATH is
	# set up, modify it with user- or installation-specific paths.
	#

	printf " configuring \$PATH and friends " >&2

	#
	# Define basic and X paths, per o/s release --
	#	alist:	dirs with bin, sbin and/or man subdirs
	#	blist:	dirs with binaries not named [s]bin
	#	mlist:	dirs with manpages not named man
	#
	# Custom paths should be set in G_PATH and G_MANPATH
	# instead, see env.conf for details. Paths in this
	# section should be specific to a distribution, not to
	# an installation.
	#

	case $ost in
		SunOS)
		alist="/usr/local /usr/xpg4 /usr / /usr/dt \
			/usr/openwin /usr/platform/${plat} /usr/share"
		blist="/usr/ucb"
		;;
		Darwin)
		alist="/usr/local /usr / /usr/local/share \
			/usr/share /usr/X11R6 \
			/System/Library/Frameworks/JavaVM.framework/Home/"
		blist="/Developer/Tools"
		;;
		OSF1)
		# XXX - compare to util path, above
		alist="/usr/local /usr / /usr/X11 /util /usr/util"
		;;
		*)
		# XXX - compare to util path, above
		alist="/usr/local /usr / /usr/share"
		;;
	esac

	for ppath in $alist
	do
		append_path basep `echo $ppath/bin | sed 's|//|/|'`
		append_path basep `echo $ppath/sbin | sed 's|//|/|'`
		append_path basem `echo $ppath/man | sed 's|//|/|'`
	done

	for ppath in $blist
	do
		append_path basep $ppath
	done

	for ppath in $mlist
	do
		append_path basem $ppath
	done

	PATH=`echo ${basep} | \
		sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`
	MANPATH=`echo ${basem} | \
		sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`
	export PATH MANPATH

	unset alist blist mlist basep basem ppath

	if [ `type -t use` ]
	then
		printf " (invoking \`use\` " >&2
#		reuse -q envdiff
#		printf "." >&2
		reuse -q .subversion-1.7.2
		printf "." >&2
		reuse -q LSF
		printf "." >&2
		reuse -q Java-1.5
		printf "." >&2
#		reuse -q Python-2.6
#		printf "." >&2
#		reuse -q set-LDFLAGS++
#		printf "." >&2
#		reuse -q GCC-4.4
#		printf "." >&2
		reuse -q CTAGS
		printf "." >&2
#		reuse -q GCC-trunk
#		printf "." >&2
#		reuse -q BLAST
#		printf "." >&2
		reuse -q Maven-2.2
		printf "." >&2

		if [ "__G_DOTKITS__" ]
		then
			for dkit in __G_DOTKITS__ null_guard
			do
				if [ $dkit != null_guard ]
				then
					reuse -q $dkit
					printf "." >&2
				fi
			done
		fi

		printf ") " >&2
	fi

	#
	# At this point PATH is defined to work on the given host. Add
	# paths for user-built tools and work-related binaries next.
	#

	ld_path LD_LIBRARY_PATH /usr/lib
	ld_path DYLD_FALLBACK_LIBRARY_PATH /usr/lib
	ld_path LD_LIBRARY_PATH /usr/lib64
	ld_path DYLD_FALLBACK_LIBRARY_PATH /usr/lib64
	ld_path LD_LIBRARY_PATH ${HOME}/lib/${ost}-${arch}
	ld_path DYLD_FALLBACK_LIBRARY_PATH ${HOME}/lib/${ost}-${arch}
	ld_path LD_LIBRARY_PATH ${HOME}/lib/${ost}
	ld_path DYLD_FALLBACK_LIBRARY_PATH ${HOME}/lib/${ost}
	ld_path LD_LIBRARY_PATH ${HOME}/lib
	ld_path DYLD_FALLBACK_LIBRARY_PATH ${HOME}/lib
	export LD_LIBRARY_PATH
	export DYLD_FALLBACK_LIBRARY_PATH

	append_path userm ${HOME}/man
	append_path userm ${HOME}/share/man
#	append_path userp ${HOME}/scripts/${ost}
	append_path userp ${HOME}/scripts
	append_path userp ${HOME}/bin/exec/${ost}
	append_path userp ${HOME}/bin/exec
	append_path userp ${HOME}/bin/${ost}-${arch}
	append_path userp ${HOME}/bin/${ost}
#	append_path userp ${HOME}/bin/gnu
	append_path userp ${HOME}/bin

	#
	# additional bin paths from env.conf; null_guard protects
	# against parse errors if G_PATH is undefined
	#
	if [ "__G_PATH__" ]
	then
		for ppath in __G_PATH__ null_guard
		do
			if [ $ppath != null_guard ]
			then
				ppath_repl=`echo $ppath | sed 's/___/\\ /g'`
				append_path customp "$ppath_repl"
			fi
		done
	fi

	PATH=`echo ${userp}:${customp}:${PATH} | \
	  sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`
	export PATH

	#
	# additional man paths from env.conf; null_guard protects
	# against parse errors if G_MANPATH is undefined
	#
	if [ "__G_MANPATH__" ]
	then
		for ppath in __G_MANPATH__ null_guard
		do
			ppath_repl=`echo $ppath | sed 's/___/\\ /g'`
			append_path customm "$ppath_repl"
		done
	fi

	MANPATH=`echo ${userm}:${customm}:${MANPATH} | \
	  sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`
	export MANPATH

	#
	# additional dyld paths from env.conf; null_guard protects
	# against parse errors if G_DYLD_FALLBACK_LIBRARY_PATH is undefined
	#
	if [ "__G_DYLD_FALLBACK_LIBRARY_PATH__" ]
	then
		for ppath in __G_DYLD_FALLBACK_LIBRARY_PATH__ null_guard
		do
			ppath_repl=`echo $ppath | sed 's/___/\\ /g'`
			ld_path -f DYLD_FALLBACK_LIBRARY_PATH "$ppath_repl"
		done
		export DYLD_FALLBACK_LIBRARY_PATH
	fi

	#
	# additional package config paths from env.conf; null_guard protects
	# against parse errors if G_PKG_CONFIG_PATH is undefined
	#
	if [ "__G_PKG_CONFIG_PATH__" ]
	then
		for ppath in __G_PKG_CONFIG_PATH__ null_guard
		do
			ppath_repl=`echo $ppath | sed 's/___/\\ /g'`
			ld_path -f PKG_CONFIG_PATH "$ppath_repl"
		done
		export PKG_CONFIG_PATH
	fi

	unset userp customp
	unset userm customm
	unset customk
	unset ppath ppath_repl

	if [ "__G_ACLOCAL_FLAGS__" ]
	then
		ACLOCAL_FLAGS="__G_ACLOCAL_FLAGS__"
		export ACLOCAL_FLAGS
	fi

	echo " <done>" >&2

	#
	# configure virtual environments for Python
	#
	for vew_home in /usr/local/bin/ /seq/a2e0/tools/util/python/bin/2.7.3/bin \
	  /Library/Frameworks/Python.framework/Versions/2.7/bin
	do
		if [ `check_path $vew_home` -eq 1 ]
		then
			if [ -f $vew_home/virtualenvwrapper.sh ]
			then
				unalias cd 2>&-
				. $vew_home/virtualenvwrapper.sh
				alias workoff="deactivate"
				break
			fi
		fi
	done

	VIRTUALENVWRAPPER_PYTHON=`type python | cut -d" " -f3`
	export VIRTUALENVWRAPPER_PYTHON

	# display a welcome message introducing the host and OS
	if [ ! "$DT" ]
	then
		if [ -x $HOME/bin/exec/iline ]
		then
			echo " Welcome to `$HOME/bin/exec/iline -anb -l 12`" >&2
			echo " running `$HOME/bin/exec/iline -sv -l 9`" >&2
		elif [ -r /etc/release ]
		then
			echo " Welcome to ${HOST}, a $arch-type machine" \
			  "running" `cat /etc/release | line | sed 's/^ *//'` >&2
		else
			echo " Welcome to ${HOST}, a $arch-type machine" \
			  "running $ost $rel" >&2
		fi

		# identify c compiler and make
		[ -x $HOME/bin/exec/ccv ] && trimline " with `ccv`"

		# print out battery information if applicable
		[ -x $HOME/bin/exec/$ost/bat ] && \
		  trimline `$HOME/bin/exec/$ost/bat`

		# pretty print env. var names if desired
		pre="" # `tput smul 2>&-`
		post="" # `tput sgr0 2>&-`

		# print tty info
		printf ' %s; ' "${pre}TTY${post}=`echo $TTY | \
		  sed 's/\/dev\///'`" >&2

		# print out terminal information
		printf '%s; ' "${pre}TERM${post}=$TERM" >&2
	fi

	# set DISPLAY if possible
	if [ "__SET_DISPLAY__" = "yes" ] && [ -r "$XENVIRONMENT" ] && \
	  [ $TTY != '/dev/console' ] && [ `echo $TTY | cut -c1-5` = '/dev/' ]
	then
		# find out name of host on controlling side of terminal
		wholine=`who -m --lookup 2>&-`
		[ $? -eq 0 ] || wholine=`who -m`

		lhost=`echo "$wholine" | awk '{ print $6 }' | \
		  sed 's/(\([^):]*\).*/\1/'`

		if [ ! "$DISPLAY" ]
		then
			DISPLAY=${lhost}:0.0
			export DISPLAY
		fi

		# if possible, do a quick test to see if DISPLAY is sane
		if [ -x $HOME/bin/exec/xping ]
		then
			$HOME/bin/exec/xping 2>&- >&-
			[ $? -ne 0 ] && unset DISPLAY
		fi

		unset wholine lhost
	else
		unset DISPLAY
	fi

	unset arch ost plat rel

	if [ ! "$DT" ]
	then
		printf '%s%s\n' "${pre}DISPLAY${post}=" ${DISPLAY:-"unset"} >&2

		# print uptime
		trimline `uptime | sed -e 's/  */ /g' -e 's/^ */ /'`

		# print a list of users
		if [ -x $HOME/bin/exec/lwho ]
		then
			users=`lwho -csq 2>&-`
			[ "$users" ] && \
			  trimline `echo "$users" | sed -e 's/^\([0-9]*\)/\1 other /'`
			unset users
		fi

		unset pre post
	fi

	[ -f $HOME/.sh_aliases ] && . $HOME/.sh_aliases
	[ -f $HOME/.profile-custom ] && . $HOME/.profile-custom

	PROFILED=true
	export PROFILED

	#
	# if not under DT Xsession control, switch to bash.
	# this command -must- run last in this block.
	#
	if [ ! "$DT" ] && [ ! "$BASH" ]
	then
		type bash 2>&- >&-
		[ $? -eq 0 ] && exec bash
	fi

	# NO CODE HERE

else	# if [ "$PROFILED" = 'true' ]

	# if we're here, this file has been sourced already.
	[ -f $HOME/.sh_aliases ] && . $HOME/.sh_aliases
	[ -f $HOME/.profile-custom ] && . $HOME/.profile-custom
fi

# NO CODE HERE

#EOF __TAGGED__
