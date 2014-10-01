#!/not/executable
#
# Copyright (c) 2000-5 Matthew Pearson <mdp@matmo.net>.
#
# These scripts are free. There is no warranty; your mileage may vary.
# Visit http://creativecommons.org/licenses/GPL/2.0/ for more details.
#
# $Id$
# light brown color scheme with red accents
#

# CDE color setting
CDE_PALETTE=Olive.dp
CDE_DEPTH=MEDIUM_COLOR

# window colors
FOCUS_FG="Gray25"
FOCUS_BG="Wheat3"
UNFOC_FG="Wheat2"
UNFOC_BG="Wheat4"

# menu colors
MENU_FG=$FOCUS_BG
MENU_BG=$FOCUS_FG
MENU_SELECT_FG="Firebrick3"
MENU_SELECT_BG="Gray30"
MENU_GREY="Gray55"

# button bar colors
MOD_FG=$FOCUS_FG
MOD_BG=$FOCUS_BG
MOD_TERM="Firebrick4"

# window colors in pager
PAGER_DESKTOP_FG=$MOD_FG
PAGER_DESKTOP_BG=$MOD_BG
PAGER_HILIGHT="Wheat2"
PAGER_FOCUS_FG="Firebrick4"
PAGER_FOCUS_BG="Wheat2"
PAGER_UNFOC_FG=$MENU_GREY
PAGER_UNFOC_BG=$MENU_SELECT_BG

# balloon-help colors in pager
PAGER_BAL_FG=$FOCUS_FG
PAGER_BAL_BG=$UNFOC_FG

# colors for clock
CLOCK_BACKG=$MOD_BG
CLOCK_OUTLN=$MOD_FG
CLOCK_TICKS="Wheat4"
CLOCK_HANDS="Wheat1"

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
