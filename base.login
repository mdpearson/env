#!/bin/csh
#
# Copyright (c) 2000-5 Matthew Pearson <mdp@matmo.net>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/GPL/2.0/ for more details.
#
# $Id: base.login,v 1.5 2005/06/19 05:22:13 matmone Exp $
# instruct csh-based login shells to exec a bourne-compatible shell
#

# this is a stub path. should be enough to find sh
setenv PATH /usr/xpg4/bin:/usr/bin:/bin:/usr/sbin:/sbin:/util/bin
setenv ENV ${HOME}/.kshrc

# force legacy Digital systems to use a standards-compliant sh
setenv BIN_SH xpg4

exec sh

#EOF __TAGGED__
