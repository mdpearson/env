#!/not/executable
#
# Copyright (c) 2000-2010 Matthew Pearson.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/GPL/2.0/ for more details.
#
# $Id: Makefile,v 1.22 2011/01/27 21:25:26 mdp Exp $
# filter and install env dotfiles in their appropriate locations
#

# location of configuration file
CONF = env.conf

# where to place dotfiles that have been replaced
GRAVEYARD = $(HOME)/replaced_dotfiles

SHELL = /bin/bash

include $(CONF)

DOTFILES = .ackrc .common.ksh .cvsrc .dbxrc .dircolors .emacs .gitconfig .inputrc \
  .kshrc .profile .profile_custom .sh_aliases .tcshrc .MacOSX/environment.plist

OVERRIDDEN_DOTFILES = .bash_login .bash_logout .bashrc .login

XDOTFILES = .Xdefaults .dtprofile .fvwm/.fvwm2rc .dt/sessionetc .dt/sessions/dtperf

SCRIPTS = ccv cleanup iline lwho stub tap xping uniq_history Darwin/bat

XSCRIPTS = clust_fvwmenu fvbutton heir_fvwmenu hpcv ot_fvwmenu sdtp

MOSTFILES = $(shell find * \( -name CVS -o -name "\.*" \) -prune -o -type f -print | sort)

ifeq ($(G_DOTFILES_BEGIN_WITH_MY),yes)
ALLDOTFILES = $(addprefix .my,$(OVERRIDDEN_DOTFILES)) $(DOTFILES)
else
ALLDOTFILES = $(OVERRIDDEN_DOTFILES) $(DOTFILES)
endif

ifeq ($(G_USE_FVWM),yes)
TARGETS = $(addprefix bin/exec/,$(SCRIPTS) $(XSCRIPTS)) $(ALLDOTFILES) $(XDOTFILES)
else
TARGETS = $(addprefix bin/exec/,$(SCRIPTS)) $(ALLDOTFILES)
endif

default: $(addprefix $(HOME)/,$(TARGETS))
	@ echo "<done>"

PREPARE = "mkdir -p $(@D); \
	[ ! -f $@ ] && exit 0; \
	chmod u+w $@; \
	if [ \`grep -c 'EOF __TAGGED__' $@\` -ne 1 ]; \
	then \
		mkdir -p $(GRAVEYARD) && mv -f $@ $(GRAVEYARD)/backup,$(@F); \
	fi"

# simple rule for .profile_custom is only run if basefile exists
ifeq (base,$(findstring base,$(shell ls base.profile_custom 2>&-)))
$(HOME)/.profile_custom: \
$(HOME)/.%: base.%
	cp $< $@
	chmod 444 $@
else
$(HOME)/.profile_custom:
endif

# messy rule for x dotfiles that need substantial pattern substitution
$(HOME)/.Xdefaults: TSRC=base.Xdefaults
$(HOME)/.Xdefaults: TMODE=444
$(HOME)/.Xdefaults: base.Xdefaults
$(HOME)/.fvwm/.fvwm2rc: TSRC=base.fvwm2rc
$(HOME)/.fvwm/.fvwm2rc: TMODE=444
$(HOME)/.fvwm/.fvwm2rc: base.fvwm2rc
$(HOME)/bin/exec/fvbutton: TSRC=scripts/fvbutton
$(HOME)/bin/exec/fvbutton: TMODE=544
$(HOME)/bin/exec/fvbutton: scripts/fvbutton
$(HOME)/.MacOSX/environment.plist: TSRC=environment.plist
$(HOME)/.MacOSX/environment.plist: TMODE=444
$(HOME)/.MacOSX/environment.plist: environment.plist
$(HOME)/.Xdefaults $(HOME)/.fvwm/.fvwm2rc $(HOME)/bin/exec/fvbutton \
$(HOME)/.MacOSX/environment.plist: \
%: filter.sh $(CONF) schemes/$(G_SCHEME).cs $(TSRC) Makefile
	-$(SHELL) -c $(PREPARE)
	$(SHELL) $< $(CONF) schemes/$(G_SCHEME).cs $(TSRC) > $@
	chmod $(TMODE) $@

# rule for files in unusual locations
$(HOME)/.dt/sessionetc: base.sessionetc
$(HOME)/.dt/sessions/dtperf: base.dtperf
$(HOME)/.dt/%: filter.sh $(CONF)
	-$(SHELL) -c $(PREPARE)
	$(SHELL) $< $(CONF) base.$(@F) > $@
	chmod 544 $@

# general dotfiles: prefixed with ".my"
$(HOME)/.my.%: filter.sh $(CONF) base.%
	-$(SHELL) -c $(PREPARE)
	$(SHELL) $< $(CONF) $(patsubst .my%,base%,$(@F)) > $@
	chmod 444 $@

# general dotfiles: common case
$(HOME)/.%: filter.sh $(CONF) base.%
	-$(SHELL) -c $(PREPARE)
	$(SHELL) $< $(CONF) base$(@F) > $@
	chmod 444 $@

# generate a simple script to run this makefile
$(HOME)/bin/exec/stub: Makefile $(CONF)
	@[ -d $(@D) ] || mkdir -p $(@D)
	-rm -f $@
	echo "#!/bin/sh" > $@
	echo "cd $(G_BASE)" >> $@
	echo "type gmake 2>&- >&-" >> $@
	echo '[ $$? -eq 0 ] && prefix=g' >> $@
	echo '$${prefix}make' >> $@
	chmod 544 $@

# install needed utility scripts in ~/bin/exec
$(HOME)/bin/exec/%: filter.sh $(CONF) scripts/%
	-$(SHELL) -c $(PREPARE)
	$(SHELL) $< $(CONF) scripts/$* > $@
	chmod 555 $@

tarball: env.tar
env.tar:
	tar cf env.tar $(MOSTFILES)

ident:
	@ident $(MOSTFILES) | fgrep 'Id'

status:
	@cvs status 2>&- | grep Status | fgrep -v "Up-to"

wc: linecount
linecount:
	@wc $(MOSTFILES)

clean:
	-rm -f env.tar

envclean:
	for file in $(TARGETS); do \
		rm -f $(HOME)/$$file; done
clobber: clean envclean

#EOF __TAGGED__
