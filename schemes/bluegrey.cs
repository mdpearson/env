#!/not/executable
#
# Copyright (c) 2000-5 Matthew Pearson <mdp@matmo.net>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/GPL/2.0/ for more details.
#
# $Id$
# blue and grey color scheme
#

# CDE color setting
CDE_PALETTE=Delphinium.dp
CDE_DEPTH=MEDIUM_COLOR # high color = ugly

# window colors
FOCUS_FG="SlateGray1"
FOCUS_BG="SlateGray"
UNFOC_FG="Gray"
UNFOC_BG="DimGray"

# menu colors
MENU_FG="LightGray"
MENU_BG="DimGray"
MENU_SELECT_FG=$FOCUS_FG
MENU_SELECT_BG=$FOCUS_BG
MENU_GREY="Gray"

# button bar colors
MOD_FG="DimGray"
MOD_BG="Gray"
MOD_TERM=$MOD_FG

# window colors in pager
PAGER_DESKTOP_FG="SlateGray"
PAGER_DESKTOP_BG=$MOD_BG
PAGER_HILIGHT="LightGray"
PAGER_FOCUS_FG=$FOCUS_FG
PAGER_FOCUS_BG=$FOCUS_BG
PAGER_UNFOC_FG=$UNFOC_FG
PAGER_UNFOC_BG=$UNFOC_BG

# balloon-help colors in pager
PAGER_BAL_FG=$FOCUS_BG
PAGER_BAL_BG=$FOCUS_FG

# colors for clock
CLOCK_BACKG=$MOD_BG
CLOCK_OUTLN=$FOCUS_BG
CLOCK_TICKS=$MOD_FG
CLOCK_HANDS=$FOCUS_FG

# window, menu, and aux fonts for fvwm
TITLE_FONT="*-application-bold-r-normal-sans-10-*"
MENU_FONT="*-application-bold-i-normal-sans-10-*"
SMALL_FONT="*-helvetica-medium-o-*-10-*"

# fonts for CDE applications
CDE_HEADER_FONT="*-application-medium-r-normal-sans-10-*"
CDE_HEADER_B_FONT="*-application-bold-r-normal-sans-10-*"
CDE_HEADER_I_FONT="*-application-medium-i-normal-sans-10-*"
CDE_HEADER_BI_FONT="*-application-bold-i-normal-sans-10-*"
CDE_TEXT_FONT="*-lucidatypewriter-medium-r-*-sans-10-*"
CDE_COMP_FONT="*-serif-*-10-*"

# fonts for terminals
TERM_FONT="6x13"
TERM_BD_FONT="6x13bold"

# colors for terminals
SHELL_LOCAL="\#B0FFE0"
SHELL_REMOTE="Cornsilk"
SHELL_ROOT="PaleTurquoise1"
SHELL_SPECIAL="SlateGray1"
SHELL_POINTER="Cyan"
SHELL_CURSOR="Red"
SHELL_BACKGROUND="Black"

# more CDE application fonts
CDE_WM_MENU_FONT=$CDE_HEADER_BI_FONT
CDE_APP_MENU_FONT=$CDE_HEADER_B_FONT
CDE_APP_MENU_IT_FONT=$CDE_HEADER_BI_FONT
CDE_APP_SUBMENU_FONT=$CDE_HEADER_FONT
CDE_APP_SUBMENU_IT_FONT=$CDE_HEADER_I_FONT
CDE_WM_ICON_FONT=$CDE_HEADER_FONT
CDE_BUTTON_FONT=$CDE_HEADER_B_FONT
CDE_DIALOG_TEXT=$CDE_TEXT_FONT

# picture to display in login/screensaver screen
CDE_LOGIN_IMG="/etc/dt/appconfig/icons/C/Flower.pm"

#EOF __TAGGED__
