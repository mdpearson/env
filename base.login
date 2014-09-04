#!/bin/csh
#
# Copyright (c) 2000-2014 Matthew Pearson <matthewpearson@gmail.com>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# $Id$
# instruct csh-based login shells to exec a bourne-compatible shell
#

# this is a stub path. should be enough to find sh
setenv PATH /usr/xpg4/bin:/usr/bin:/bin:/usr/sbin:/sbin:/util/bin
setenv ENV ${HOME}/.kshrc

# force legacy Digital systems to use a standards-compliant sh
setenv BIN_SH xpg4

exec sh

#EOF __TAGGED__
