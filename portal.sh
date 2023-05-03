#!/bin/bash
# shellcheck disable=1090,2034,2154,2155

# ██╗   ██╗ █████╗ ██████╗ ██╗ █████╗ ██████╗ ██╗     ███████╗███████╗
# ██║   ██║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██║     ██╔════╝██╔════╝
# ██║   ██║███████║██████╔╝██║███████║██████╔╝██║     █████╗  ███████╗
# ╚██╗ ██╔╝██╔══██║██╔══██╗██║██╔══██║██╔══██╗██║     ██╔══╝  ╚════██║
#  ╚████╔╝ ██║  ██║██║  ██║██║██║  ██║██████╔╝███████╗███████╗███████║
#   ╚═══╝  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚══════╝
declare -g SCRIPT_NAME="Portal"
declare -g VERSION="beta_v0.6"
declare -g script_path="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"


# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

function parse_script_input_variables {
   if [[ "$#" -eq 0 ]]; then
      gui_mode="true"
      #exit 0
   fi

   while [[ "$#" -gt 0 ]]; do
      argument="${1}"
      case "${argument}" in
         --gui | -g)
            gui_mode="true"
            ;;

         -h | --help)
            print_help_menu
            exit 0
            ;;
         
         http | ssh | sftp)
            break
            ;;

         -i | --init)
            is_initial_setup="true"
            ;;

         -f | --force)
            force_overwrite="true"
            ;;

         -b | --bash-completion)
            bash_completion
            exit 0
            ;;

         -l | --list)
            list_mode="true"
            ;;

         -s | --search)
            search_mode="true"
            break
            ;;

         -si | --search-ignore-case)
            search_mode="true"
            ignore_case="true"
            break
            ;;

         *)
            echo "Error: Input not an option"
            print_help_menu
            exit 1
            ;;
      esac
      shift
   done
}

function source_functions {
   declare FILES_TO_SOURCE=( "menu_logic.sh" "var.sh" "draw.sh" "load.sh" "utility.sh" "wait_for_input.sh" )

   for file in "${FILES_TO_SOURCE[@]}"; do
      source "${script_path}/functions/${file}"
   done
}

function main {
   source_functions
   parse_script_input_variables "$@"

   if ${is_initial_setup}; then
      initial_setup
      exit 0
   fi

   load_config_file
   get_list_of_csv_files
   load_key_values
   load_csv_file_values
   load_menu_items

   if ${gui_mode}; then
      hide_input
      main_menu
   elif ${list_mode}; then
      draw_connection_list
   elif ${search_mode}; then
      search_keyword="${*:2}"
      draw_connection_list
   else
      menu_selection="${*:2}"
      check_for_connection
      do_action "${1}"
   fi
}


# ███╗   ███╗ █████╗ ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║████╗  ██║
# ██╔████╔██║███████║██║██╔██╗ ██║
# ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
# ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
# ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝

main "$@"
