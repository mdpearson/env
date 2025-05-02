#!/bin/bash
#
# Copyright (c) 2003-2025 Matthew Pearson <matthewpearson@gmail.com>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/by-nc-sa/4.0/ for more details.
#
# redirect bash to correct dotfiles when it runs as a login shell
#

. "$HOME/.profile"
. "$HOME/.bashrc"

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

#EOF __TAGGED__
