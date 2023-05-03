#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154,2155

# ██╗   ██╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██╗     ███████╗███████╗
# ██║   ██║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
# ██║   ██║███████║██████╔╝██║███████║██████╔╝██║     █████╗  ███████╗
# ╚██╗ ██╔╝██╔══██║██╔══██╗██║██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
#  ╚████╔╝ ██║  ██║██║  ██║██║██║  ██║██████╔╝███████╗███████╗███████║
#   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝
# NECESSARY FILES
#declare -g AUTOINSERT_PASSWORD_EXPECT_SCRIPT="${script_path}/functions/supply_pass.exp"
declare -g PATHS_FOR_DATAFILES=( "/home/$(whoami)/.portal/data" )
declare -g set_of_csv_files=()

# PREFERRED BROWSER
declare -g BROWSER_NEW_TAB_METHOD="vivaldi --parent-window"

# DATA ARRAYS
declare -Ag serverlistKeyArray
declare -Ag serverlistArray

# POSITIONAL VARIABLES
declare -g FIRST_WIDTH_SETUP="true"
declare -g PAGE_SIZE="20"
declare -g y_cursor_position="0"
declare -g current_page="1"
declare -g loop_once="false"
declare -g skip_clear="true"
declare -g endless_loop="false"
declare -g gui_mode="false"
declare -g list_mode="false"
declare -g search_mode="false"
declare -g ignore_case="false"
declare -g search_keyword=""
declare -g is_initial_setup="false"
declare -g force_overwrite="false"

# COLOURS
declare -g CLR=$'\033[0m'
declare -g INVERT_COLOR=$'\033[1;7m'
declare -g GREEN=$'\033[1;38;5;118m'
declare -g RED=$'\033[1;38;5;198m'

# SORTED VALUES FOR NICE DRAWING OF CONNECTION DETAILS
declare -g serverlistKeyArraySorted=( "entry_name" "hostname" "ip_address" "port" "username" "protocol" "note" )