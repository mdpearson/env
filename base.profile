#!/bin/sh
#
# Copyright (c) 2000-2025 Matthew Pearson <matthewpearson@gmail.com>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# sh-compatible commands executed at login for bash, ksh, sh, zsh
#
# shellcheck disable=SC2003		# although expr is old, it's portable
# shellcheck disable=SC2006		# $() doesn't work in old Bourne shells
# shellcheck disable=SC2078		# don't warn about __G_VARS__ interpolation
#

# force legacy Digital systems to use a standards-compliant sh
BIN_SH=xpg4
export BIN_SH

# make ls use standard POSIX sort semantics
LC_COLLATE=POSIX
export LC_COLLATE

# set up a simple path if this file has not yet been sourced by this user
[ "$_ENV_PROFILED" = "$TTY.$USER.$PPID" ] || PATH=/usr/xpg4/bin:/bin:/usr/bin:/usr/ucb

#
# First thing to do is make sure the terminal is set up correctly.
# The SHELL environment variable may be unset (or, worse, set wrong) at
# this point. Later on we set it for real, but for now we simply use a
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
# login. If _ENV_PROFILED is set to the current tty/user/ppid then we
# do not run it. Note that redo() unsets this value when it does a heavy-
# weight terminal reinitialization. When bash shells are launched in X,
# the call to tput is skipped.
#
# For testing: ztx is in termcap only, xtermm is in terminfo only.
#

# override TERM setting on Darwin console shells
[ "`uname -s`" = 'Darwin' ] && [ "`tty`" = '/dev/console' ] && TERM=xnuppc

set noglob
while [ -t 1 ]
do
	# shellcheck disable=SC2209
	eval "`SHELL=sh tset -s -e ^H -IQ \
	  -m 'dtterm:dtterm' \
	  -m 'linux:xterm-color' \
	  -m 'nxterm:xterm' \
	  -m 'sun:?sun' \
	  -m 'vt100:vt100' \
	  -m 'xnuppc:?xnuppc' \
	  -m 'xterm:xterm' \
	  -m 'xterm-256color:xterm-256color' \
	  -m 'xterm-color:xterm-color' \
	  -m ':?xterm'`"
	export TERM				# Darwin tset forgets to do this

	[ "$_ENV_PROFILED" = "$TTY.$USER.$PPID" ] && break	# terminal already set up

	tput init # heavyweight

	#
	# Error 3 means unrecognized term: loop and try again.
	# Other errors can't be fixed here. Let them fall through.
	#
	[ "$?" -ne 3 ] && break
done
unset noglob

[ -t 1 ] && stty -ixon		# disable START/STOP output control

#
# Make sure the SHELL environment variable is set properly. There are
# a few cases where it will not be. The most common is when bash
# is run from a csh environment where SHELL already exists. Another
# case is when su - is called from a Darwin console.
#

if [ "`echo \"$BASH\" | grep -c 'bash$'`" -eq 1 ]
then
	# if the BASH env var is set and valid, override SHELL
	if [ "$BASH" != "$SHELL" ]
	then
		#
		# If bash was instantiated as sh, it's no big deal.
		# Otherwise, print a message saying that SHELL is changing.
		#
		if [ "`echo "$SHELL" | grep -c '/sh$'`" -ne 1 ]
		then
			sh_oldn="$SHELL"

			printf ' %s %s%s\n' \
			  "\$SHELL environment variable clashes with \$BASH: changing" \
			  ${sh_oldn:+"from ${sh_oldn} "} "to $BASH" >&2
			unset sh_oldn
		fi
		SHELL="$BASH"
	fi
else
	#
	# Check if the currently running command is a shell name.
	# (In some cases it can be something like su or login.)
	#

	cur_cmd="`echo \"$0\" | sed 's/^-//'`"
	if [ "`echo \"$cur_cmd\" | grep -c 'sh$'`" -eq 1 ]
	then
		sh_name="`basename \"$cur_cmd\"`"
		sh_path="`(type \"$cur_cmd\" 2>&1) | awk '{print $NF}'`"
		[ -x "$sh_path" ] || unset sh_path
	fi

	#
	# If SHELL is not set or set badly, correct it. Either use
	# the shell path discovered above from $0, or /bin/sh as a
	# last resort.
	#
	if [ ! "$SHELL" ] || [ "`echo \"$SHELL\" | grep -c 'sh$'`" -eq 0 ] || \
	  [ "$sh_name" ] && [ "`basename \"$SHELL\"`" != "$sh_name" ]
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

HOST="`hostname | sed 's/\..*//'`"	# drop domain name if present
[ "$USER" ] || USER="`whoami`"
HOSTNAME="$HOST"
export HOST HOSTNAME USER

COLUMNS="`tput cols`"
[ "$COLUMNS" ] || COLUMNS=80
ENV="${HOME}/.kshrc"
export COLUMNS ENV

if [ -r "${HOME}/.Xdefaults" ]
then
	XENVIRONMENT="${HOME}/.Xdefaults"
	export XENVIRONMENT
fi

unset SSH_ASKPASS

if [ -f /etc/ssl/certs/ca-certificates.crt ]
then
	REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
	export REQUESTS_CA_BUNDLE
fi

#
# Set/override prompt for true bourne shells.
# (bash and ksh use control chars bourne cannot parse.)
#

if [ "`echo \"$SHELL\" | grep -c '\/sh$'`" -eq 1 ] && [ ! "$BASH" ]
then
	if [ "$USER" = "root" ]
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
# _ENV_PROFILED is set to the current tty/user/ppid, then this has
# already happened: skip to the end.
#

if [ "$_ENV_PROFILED" != "$TTY.$USER.$PPID" ]
then
	# define some handy path-manipulation functions

	if sleep 0s >/dev/null 2>&1
	then
		# GNU-like sleep
		_SLEEP_UNIT="s"
	else
		# BSD-like sleep
		_SLEEP_UNIT=
	fi

	#
	# Echoes 1 if the path exists, 0 if it does not.
	#
	# If the path is on a wedged filesystem that cannot be
	# stat'ed, this *should* return 0 after printing an error.
	#
	check_path() {
		if [ ! "$1" ]
		then
			echo 0
			return
		fi

		# shellcheck disable=SC2265
		test -d "$1" &
		check_pid="$!"

		# busy-wait with an incremental backoff
		cnt=0
		while [ "$cnt" -lt 10 ]
		do
			pidinfo="`jobs -l 2>&1 | grep \"$check_pid\" | grep -Ev 'Done|Exit'`"
			if [ "$pidinfo" ]
			then
				arg="0.0${cnt}${_SLEEP_UNIT}"
				sleep "$arg"
			else
				unset check_pid
				break
			fi
			cnt="`expr \"$cnt\" + 1`"
		done

		if [ "$check_pid" ]
		then
			#
			# It shouldn't take this long to stat a dir.
			# The filesystem mount may be hosed.
			#
			printf '\n > unable to stat %s\n > killing hung job %s\n ' "$1" "$check_pid" >&2
			kill "$check_pid" >/dev/null 2>&1
			res=0
		else
			res="`test -d \"$1\" && echo 1 || echo 0`"
		fi

		echo "$res"
		unset res
		return
	}

	# add a directory $2 to the end of a :-separated pathlist $1
	append_path() {
		[ "$2" ] || return
		[ "$2" = null_guard ] && return
		res="`check_path \"$2\"`"
		[ "$res" -eq 1 ] && eval "$1=\${$1:+\$$1:}\"$2\""
		[ "$res" -eq 1 ] && printf "." >&2
		unset res
	}

	# add a directory $2 to the start of a :-separated pathlist $1
	prepend_path() {
		[ "$2" ] || return
		[ "$2" = null_guard ] && return
		res="`check_path \"$2\"`"
		[ "$res" -eq 1 ] && eval "$1=\"$2\"\${$1:+:\$$1}"
		[ "$res" -eq 1 ] && printf "." >&2
		unset res
	}

	#
	# Slower than the above functions - use for paths whose fields
	# are unknown (to prevent adding the same directory twice).
	#
	ld_path() {
		unset arg prepend

		#
		# I can't remember how many times getopts's reliance on external
		# shell variables has bitten me. OPTIND must be set to 1 each
		# time getopts is called. "Any other attempt to invoke getopts
		# multiple times in a single shell execution environment ...
		# produces unspecified results."
		#
		# http://pubs.opengroup.org/onlinepubs/009696799/utilities/getopts.html
		#
		OPTIND=1
		getopts f arg && prepend=y
		shift "`expr \"$OPTIND\" - 1`"

		[ "$2" ] || return
		[ "$2" = null_guard ] && return

		eval "echo \$$1" | grep -sq "$2"

		if [ "$?" -ne 0 ]
		then
			if [ "$prepend" ]
			then
				res="`check_path \"$2\"`"
				[ "$res" -eq 1 ] && eval "$1=\"$2\"\${$1:+:\$$1}"
			else
				res="`check_path \"$2\"`"
				[ "$res" -eq 1 ] && eval "$1=\${$1:+\$$1:}\"$2\""
			fi
			[ "$res" -eq 1 ] && printf "." >&2
			unset res
		else
			#
			# print a colon (a "double period") to indicate that the
			# element was already present in the specified path.
			#
			printf ":" >&2
		fi
		unset arg prepend res
	}

	# this function trims output to a single line
	trimline() {
		if [ "`expr \"$COLUMNS\" \< 255`" -eq 1 ]
		then
			lim="`expr \"$COLUMNS\" - 1`"
			# next line requires xpg4 sed on SunOS
			[ "$*" ] && echo "$*" | sed -e 's/^ */ /' \
			  -e 's/\(.\{'"$lim"','"$lim"'\}\)...*/\1</' >&2
			unset lim
		else
			[ "$*" ] && echo "$*" >&2
		fi
	}

	arch="`uname -p`"
	# workaround for gnu uname
	[ "$arch" = 'unknown' ] && arch="`uname -m`"

	ost="`uname -s`"
	rel="`uname -r`"

	if [ "$ost" = 'Darwin' ] || [ "$ost" = 'OSF1' ]
	then
		plat="`machine`"
	else
		plat="`uname -i`"
	fi

	mesg n 2>/dev/null
	MAILCHECK=0
	TTY="`tty`"
	VISUAL=emacs
	export MAILCHECK TTY VISUAL

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
	#
	# Custom paths should be set in G_PATH and G_MANPATH
	# instead, see env.conf for details. Paths in this
	# section should be specific to a distribution, not to
	# an installation.
	#

	case "$ost" in
		SunOS)
		alist="/usr/local /usr/xpg4 /usr / /usr/dt \
			/usr/openwin /usr/platform/${plat} /usr/share"
		blist="/usr/ucb"
		;;
		Darwin)
		alist="/usr/local /usr / /usr/local/share \
			/usr/share /usr/X11R6"
		blist="/Developer/Tools"
		;;
		*)
		alist="/usr/local /usr / /usr/X11 /util /usr/util /usr/share"
		;;
	esac

	basep=
	basem=

	for ppath in $alist
	do
		append_path basep "`echo \"$ppath/bin\" | sed 's|//|/|'`"
		append_path basep "`echo \"$ppath/sbin\" | sed 's|//|/|'`"
		append_path basem "`echo \"$ppath/man\" | sed 's|//|/|'`"
	done

	for ppath in $blist
	do
		append_path basep "$ppath"
	done

	PATH="`echo \"${basep}\" | \
		sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`"
	MANPATH="`echo \"${basem}\" | \
		sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`"
	export PATH MANPATH

	unset alist blist basep basem ppath
	userm=
	userp=
	customm=
	customp=

	#
	# At this point PATH is defined to work on the given host. Add
	# paths for user-built tools and work-related binaries next.
	#

	ld_path LD_LIBRARY_PATH /usr/lib
	ld_path DYLD_FALLBACK_LIBRARY_PATH /usr/lib
	ld_path LD_LIBRARY_PATH /usr/lib64
	ld_path DYLD_FALLBACK_LIBRARY_PATH /usr/lib64
	ld_path LD_LIBRARY_PATH "${HOME}/lib/${ost}-${arch}"
	ld_path DYLD_FALLBACK_LIBRARY_PATH "${HOME}/lib/${ost}-${arch}"
	ld_path LD_LIBRARY_PATH "${HOME}/lib/${ost}"
	ld_path DYLD_FALLBACK_LIBRARY_PATH "${HOME}/lib/${ost}"
	ld_path LD_LIBRARY_PATH "${HOME}/lib"
	ld_path DYLD_FALLBACK_LIBRARY_PATH "${HOME}/lib"
	export LD_LIBRARY_PATH
	export DYLD_FALLBACK_LIBRARY_PATH

	ld_path PERL5LIB "${HOME}/perl5/lib/perl5"
	ld_path PERL_LOCAL_LIB_ROOT "${HOME}/perl5"
	PERL_MB_OPT="--install_base ${HOME}/perl5"
	PERL_MM_OPT="INSTALL_BASE=${PERL_LOCAL_LIB_ROOT}"
	export PERL5LIB PERL_LOCAL_LIB_ROOT PERL_MB_OPT PERL_MM_OPT

	append_path userm "${HOME}/man"
	append_path userm "${HOME}/share/man"
	append_path userp "${HOME}/scripts"
	append_path userp "${HOME}/bin/exec/${ost}"
	append_path userp "${HOME}/bin/exec"
	append_path userp "${HOME}/bin/${ost}-${arch}"
	append_path userp "${HOME}/bin/${ost}"
	append_path userp "${HOME}/bin"
	append_path userp "${HOME}/perl5/bin"

	#
	# Add additional bin paths from env.conf; null_guard
	# protects against parse errors if G_PATH is undefined.
	#
	if [ "__G_PATH__" ]
	then
		for ppath in __G_PATH__ null_guard
		do
			if [ "$ppath" != null_guard ]
			then
				ppath_repl="`echo \"$ppath\" | sed 's/___/\\ /g'`"
				append_path customp "$ppath_repl"
			fi
		done
	fi

	# adjust the PATH to support homebrew
	if [ -f /opt/homebrew/bin/brew ]
	then
		eval "`/opt/homebrew/bin/brew shellenv`"
	fi

	# adjsut the PATH to support nvm (node)
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

	# adjust the PATH to support sdkman
	if [ -r "$HOME/.sdkman" ]
	then
		SDKMAN_DIR="$HOME/.sdkman"
		export SDKMAN_DIR
		[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && . "$HOME/.sdkman/bin/sdkman-init.sh"
	fi

	BASE_PATH="$PATH"

	# this first definition of PATH is only tentative
	PATH="`echo \"${userp}:${customp}:${BASE_PATH}\" | \
	  sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`"

	. "$HOME/.isinstalled"

	# look for gems in the tentative path
	if [ "`isinstalled gem`" ]
	then
		for p in `gem environment | awk '/GEM PATHS/{flag=1;next}/GEM CONFIGURATION/{flag=0}flag{print $2}'`
		do
			append_path customp "$p/bin"
		done
	fi

	# now that we've found gem paths, we can construct a final PATH
	PATH="`echo \"${userp}:${customp}:${BASE_PATH}\" | \
	  sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`"

	if [ "$SGE_O_PATH" ]
	then
		printf " (Overriding PATH with SGE_O_PATH...)" >&2
		PATH=$SGE_O_PATH
	fi

	unset BASE_PATH
	export PATH

	#
	# Add additional man paths from env.conf; null_guard
	# protects against parse errors if G_MANPATH is undefined.
	#
	if [ "__G_MANPATH__" ]
	then
		for ppath in __G_MANPATH__ null_guard
		do
			ppath_repl="`echo \"$ppath\" | sed 's/___/\\ /g'`"
			append_path customm "$ppath_repl"
		done
	fi

	MANPATH="`echo \"${userm}:${customm}:${MANPATH}\" | \
	  sed -e 's/::/:/g' -e 's/:$//' -e 's/^://'`"
	export MANPATH

	#
	# Add additional dyld paths from env.conf; null_guard protects
	# against parse errors if G_DYLD_FALLBACK_LIBRARY_PATH is undefined.
	#
	if [ "__G_DYLD_FALLBACK_LIBRARY_PATH__" ]
	then
		for ppath in __G_DYLD_FALLBACK_LIBRARY_PATH__ null_guard
		do
			ppath_repl="`echo \"$ppath\" | sed 's/___/\\ /g'`"
			ld_path -f DYLD_FALLBACK_LIBRARY_PATH "$ppath_repl"
		done
		export DYLD_FALLBACK_LIBRARY_PATH
	fi

	#
	# Add additional package config paths from env.conf; null_guard
	# protects against parse errors if G_PKG_CONFIG_PATH is undefined.
	#
	if [ "__G_PKG_CONFIG_PATH__" ]
	then
		for ppath in __G_PKG_CONFIG_PATH__ null_guard
		do
			ppath_repl="`echo \"$ppath\" | sed 's/___/\\ /g'`"
			ld_path -f PKG_CONFIG_PATH "$ppath_repl"
		done
		export PKG_CONFIG_PATH
	fi

	unset userp customp
	unset userm customm
	unset ppath ppath_repl

	if [ "__G_ACLOCAL_FLAGS__" ]
	then
		ACLOCAL_FLAGS="__G_ACLOCAL_FLAGS__"
		export ACLOCAL_FLAGS
	fi

	if [ -f /hpc/settings.sh ]
	then
		. /hpc/settings.sh
	fi

	echo " <done>" >&2

	# support 1Password
	SSH_AUTH_SOCK="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
	export SSH_AUTH_SOCK

	#
	# Configure virtual environments for Python.
	#
	VIRTUALENVWRAPPER_PYTHON="`(type python3 2>&1) | awk '{print $NF}'`"
	export VIRTUALENVWRAPPER_PYTHON
	if [ ! "$VIRTUALENVWRAPPER_SCRIPT" ]
	then
		for vew_home in "$HOME/.local/bin" \
		  "$HOME/Library/Python/3.9/bin" \
		  "$HOME/Library/Python/3.8/bin" \
		  "$HOME/Library/Python/3.7/bin" \
		  "$HOME/Library/Python/3.6/bin" \
		  "$HOME/Library/Python/2.7/bin" \
		  /usr/local/bin
		do
			if [ "`check_path \"$vew_home\"`" -eq 1 ]
			then
				if [ ! "$VIRTUALENVWRAPPER_SCRIPT" ] && [ -f "$vew_home/virtualenvwrapper.sh" ]
				then
					VIRTUALENVWRAPPER_SCRIPT="$vew_home/virtualenvwrapper.sh"
					export VIRTUALENVWRAPPER_SCRIPT
				fi
				if [ ! "$VIRTUALENVWRAPPER_VIRTUALENV" ] && [ -f "$vew_home/virtualenv" ]
				then
					VIRTUALENVWRAPPER_VIRTUALENV="$vew_home/virtualenv"
					export VIRTUALENVWRAPPER_VIRTUALENV
				fi
			fi
		done
		unset vew_home
	fi

	if [ "$VIRTUALENVWRAPPER_SCRIPT" ] && [ ! "$SGE_O_PATH" ]
	then
		WORKON_HOME=venv
		export WORKON_HOME
		unalias cd 2>/dev/null
		. "$VIRTUALENVWRAPPER_SCRIPT"
		alias workoff="deactivate"
	fi

	[ "`isinstalled macname`" ] && THOST="`macname`"
	[ "$THOST" ] && export THOST

	if [ "`isinstalled sysctl`" ] && sysctl -n hw.ncpu >/dev/null 2>&1
	then
		MAKEFLAGS="-j`sysctl -n hw.ncpu`"
		export MAKEFLAGS
	fi

	unset isinstalled

	if [ "`date +%Z`" = "UTC" ]
	then
		TZ='America/Los_Angeles'
		export TZ
	fi

	# display a welcome message introducing the host and OS
	if [ ! "$DT" ]
	then
		if [ -x "$HOME/bin/exec/iline" ]
		then
			echo " Welcome to `"$HOME"/bin/exec/iline -anb -l 12`" >&2
			echo " running `"$HOME"/bin/exec/iline -sv -l 9`" >&2
		elif [ -r /etc/release ]
		then
			echo " Welcome to ${HOST}, a $arch-type machine" \
			  "running `line < /etc/release | sed 's/^ *//'`" >&2
		else
			echo " Welcome to ${HOST}, a $arch-type machine" \
			  "running $ost $rel" >&2
		fi

		# identify c compiler, make and java versions
		[ -x "$HOME/bin/exec/ccv" ] && trimline " with `ccv`"

		# print out battery information if applicable
		[ -x "$HOME/bin/exec/$ost/bat" ] && \
		  trimline "`"$HOME"/bin/exec/"$ost"/bat`"

		# pretty print env. var names if desired
		pre="" # `tput smul 2>/dev/null`
		post="" # `tput sgr0 2>/dev/null`

		# print tty info
		printf ' %s; ' "${pre}TTY${post}=`echo \"$TTY\" | \
		  sed 's/\/dev\///'`" >&2

		# print out terminal information
		printf '%s; ' "${pre}TERM${post}=$TERM" >&2
	fi

	# set DISPLAY if possible
	# shellcheck disable=SC2050
	if [ "__SET_DISPLAY__" = "yes" ] && [ -r "$XENVIRONMENT" ] && \
	  [ "$TTY" != '/dev/console' ] && [ "`echo \"$TTY\" | cut -c1-5`" = '/dev/' ]
	then
		# find out name of host on controlling side of terminal
		wholine="`who -m --lookup 2>/dev/null`"
		[ "$?" -eq 0 ] || wholine="`who -m`"

		lhost="`echo "$wholine" | awk '{ print $6 }' | \
		  sed 's/(\([^):]*\).*/\1/'`"

		if [ ! "$DISPLAY" ]
		then
			DISPLAY="${lhost}:0.0"
			export DISPLAY
		fi

		# if possible, do a quick test to see if DISPLAY is sane
		if [ -x "$HOME/bin/exec/xping" ]
		then
			if "$HOME/bin/exec/xping" >/dev/null 2>&1
			then
				# DISPLAY is good
				:
			else
				# DISPLAY is bad, unset it
				unset DISPLAY
			fi
		fi

		unset wholine lhost
	else
		unset DISPLAY
	fi

	unset arch ost plat rel

	if [ ! "$DT" ]
	then
		# print out display information
		printf '%s%s; ' "${pre}DISPLAY${post}=" "${DISPLAY:-unset}" >&2

		# print out time zone information
		if [ "$TZ" ]
		then
			tzmsg="`date '+%z %Z'` (localized from machine's native UTC)"
		else
			tzmsg="`date '+%z %Z'`"
		fi
		echo "${pre}timezone${post}=$tzmsg" >&2

		# print uptime
		trimline "`uptime | sed -e 's/	 */ /g' -e 's/^ */ /'`"

		# print a list of users
		if [ -x "$HOME/bin/exec/lwho" ]
		then
			users="`lwho -csq 2>/dev/null`"
			[ "$users" ] && \
			  trimline "`echo \"$users\" | sed -e 's/^\([0-9]*\)/\1 other /'`"
			unset users
		fi

		unset tzmsg
		unset pre post
	fi

	[ -f "$HOME/.sh_aliases" ] && . "$HOME/.sh_aliases"
	[ -f "$HOME/.profile-custom" ] && . "$HOME/.profile-custom"

	_ENV_PROFILED="$TTY.$USER.$PPID"
	export _ENV_PROFILED

	#
	# If not under DT Xsession control, switch to bash.
	# This command -must- run last in this block.
	#
	if [ ! "$DT" ] && [ ! "$BASH" ]
	then
		type bash >/dev/null 2>&1 && exec bash
	fi

	# NO CODE HERE

else	# if [ "$_ENV_PROFILED" = "$TTY.$USER.$PPID" ]

	# if we're here, this file has been sourced already

	:
fi

# NO CODE HERE

#EOF __TAGGED__
