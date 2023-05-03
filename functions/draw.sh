#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154,2155

# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
function draw_top_divider {
   draw_divider "╔" "═" "╗"
}

function draw_mid_divider {
   draw_divider "╠" "═" "╣"
}

function draw_bot_divider {
   draw_divider "╚" "═" "╝"
}

function draw_divider {
   divider_starter=${1}
   divider_symbol=${2}
   divider_end=${3}

   printf "%s" "${divider_starter}"
   eval "printf '${divider_symbol}%.0s' {1..${divider_inner_menu_width}}"
   printf "%s\n" "${divider_end}"
}

function draw_line {
   input_string=${1}

   printf "║ %-${inner_menu_width}s ║\n" "${input_string}"
}

function draw_line_set_length {
   input_string=${1}
   length=${2}
   true_inner_width=$((inner_menu_width+length))

   printf "║ %-${true_inner_width}s ║\n" "${input_string}"
}

function draw_line_colour_set_length_align_right {
   input_string=${1}
   length=${2}
   true_inner_width=$((inner_menu_width+length))

   printf "║ %${true_inner_width}s ║\n" "${input_string}"
}

function draw_line_mid_align {
   local input_string=${1}

   local raw_input_string="$(echo "${input_string}" | sed -u -e 's/\[[0-9;]*m//g' -e 's/\x1b//g')"
   local input_string_length=${#raw_input_string}
   local symetrical_split_for_mid_align_width=$((((((divider_inner_menu_width-input_string_length))/2))-1))

   mid_align_whitespace=$(eval printf '\ %.0s' "{1..${symetrical_split_for_mid_align_width}}")
   additional_space=""

   if [[ $((((((${#mid_align_whitespace}*2))+input_string_length))+4)) -ne ${terminal_width} ]]; then additional_space=" "; fi

   printf "║ %s%-${input_string_length}s%s%s ║\n" "${mid_align_whitespace}" "${input_string}" "${mid_align_whitespace}" "${additional_space}"
}

function print_help_menu {
   echo "Usage: ./$(basename "${0}") [http|ssh|sftp|--gui].."
   echo "Script is used to have a set of predetermined connections set up via .csv files, "
   echo "and then use the gui or supplied arguments to connect to the specificed connections."
   echo 
   echo "General script output arguments"
   echo "   -g, --gui                       enables gui menu for choosing a portal connection"
   echo "   http|ssh|sftp [ARG]             connects using one of the supplied protocols"
   echo "                    ^              ARG refers to the entry_id that is needed for a connection"
   echo
   echo "   -s, --search                    search (with grep) through the list of existing connections"
   echo "   -si, --search-case-insensitive                 search (with grep) through the list of existing connections"
   echo "   -l, --list                      print all portal connections in a table onto stdout"
   echo "   -b, --bash-completion           source the bash completion file, which updates the bash"
   echo "                                    completion for any additional new data in the .csv files"
   echo "   -i, --init                      create initial .config and bash completion file (by default"
   echo "                                    located in /home/\$(whoami)/.portal directory)"
   echo "   -f, --force                     used in conjunction with --init, it forces an overwrite of"
   echo "                                    the .config and bash completion files, in other words"
   echo "                                    reinitialize them"
   echo 
   echo "Command usage examples"
   echo "./$(basename "${0}") --gui"
   echo "./$(basename "${0}") --list"
   echo "./$(basename "${0}") --search kubernetes"
   echo "./$(basename "${0}") http cicd_cluster_1"
}

function draw_menu {
   local input_menu="${1}"

   update_width

   case ${input_menu} in
      main)
         if ! ${loop_once}; then
            draw_top_divider
            draw_line_mid_align "  .,--+ ${SCRIPT_NAME} -- ${VERSION} +--,.  "
            draw_mid_divider
         else
            echo -e "\e[3;0f"
         fi

         # Adjust settings in regards to pages.
         current_page_adjuted_for_calculating=$((current_page-1))
         page_offset=$((current_page_adjuted_for_calculating*PAGE_SIZE))
         readjusted_y_position_according_to_page_number=$(($((y_cursor_position%PAGE_SIZE))+page_offset))
         page_end_offset=$((page_offset+((PAGE_SIZE-1))))
         
         old_IFS=${IFS}; IFS=" ";
         iterate_array=$(IFS= ; eval echo "{${page_offset}..${page_end_offset}}")
         for iterator in ${iterate_array}; do
               local selection="${serverlistMenuItems[${readjusted_y_position_according_to_page_number}]}"

               if [[ ${readjusted_y_position_according_to_page_number} -eq ${iterator} ]]; then 
                  draw_line_set_length " > ${GREEN}${INVERT_COLOR} $(printf "%-4s" "${serverlistArray[${selection},protocol]}") ${CLR} ${INVERT_COLOR} ${selection} ${CLR} " "33"
               elif [[ ${serverlistMenuItems[${iterator}]} != "" ]]; then
                  draw_line_set_length "   $(printf "[%-4s] %s" "${serverlistArray[${serverlistMenuItems[${iterator}]},protocol]}" "${serverlistArray[${serverlistMenuItems[${iterator}]},entry_name]}") " ""
               else
                  draw_line ""
               fi    
         done
         ;;
   esac

   half_inner_menu_width=$((inner_menu_width/2))
   if [[ ${serverlistArray[${selection},protocol]} == "ssh" ]] || [[ ${serverlistArray[${selection},protocol]} == "sftp" ]]; then
      adjusted_info_hostname="${GREEN}${serverlistArray[${selection},hostname]}${INVERT_COLOR}${CLR}:${GREEN}${serverlistArray[${selection},port]}${CLR}"
      add_char_length="40"
   elif [[ ${#serverlistArray[${selection},hostname]} -gt "${half_inner_menu_width}" ]]; then
      adjusted_info_hostname="${GREEN}$(echo "$(echo "${serverlistArray[${selection},hostname]}" | cut -c1-${half_inner_menu_width})"\(...\))${CLR}"
      add_char_length="17"
   else
      adjusted_info_hostname="${GREEN}${serverlistArray[${selection},hostname]}${CLR}"
      add_char_length="17"
   fi


   draw_line ""
   draw_line_colour_set_length_align_right " Page: [ ${INVERT_COLOR} ${current_page} ${CLR} / ${number_of_pages} ] " "10"
      draw_mid_divider
   draw_line_colour_set_length_align_right "[${serverlistArray[${selection},entry_name]}] // ${adjusted_info_hostname}" "${add_char_length}"
   draw_line_colour_set_length_align_right "Category: ${GREEN}${serverlistArray[${selection},category]}${CLR} // Protocol: ${GREEN}${serverlistArray[${selection},protocol]}${CLR}" "34"

   if ! [[ "${serverlistArray[${selection},note]}" == "NONE" ]]; then
      draw_line_colour_set_length_align_right "Note: ${GREEN}${serverlistArray[${selection},note]}${CLR}" "17"
   else
      draw_line
   fi

   # DISPLAYS CURRENTLY SET CONTROLS, COMMENTED OUT FOR NOW, MAYBE READDING LATER
   # draw_mid_divider
   # draw_line_mid_align " Up: [${INVERT_COLOR} w / Arrow Up ${CLR}] | Down: [${INVERT_COLOR} s / Arrow Down ${CLR}]"
   # draw_line_mid_align " Confirm: [${INVERT_COLOR} j / Enter ${CLR}] "
   draw_bot_divider

   # DEBUGGING FOR TERMINAL DRAWING THINGIES
   # echo "page_end_offset: ${page_end_offset}; page_offset: ${page_offset}    "
   # echo "PAGE_SIZE: ${PAGE_SIZE}; current_page: ${current_page}   "
   # echo "current_page_adjuted_for_calculating: ${current_page_adjuted_for_calculating}  ; readjusted_y_position_according_to_page_number: ${readjusted_y_position_according_to_page_number}    "
   # echo "y_cursor_position: ${y_cursor_position}    "
   # echo "number_of_pages: ${number_of_pages}    "
   # echo "size of serverlistArray[@]: ${#serverlistArray[@]}     "
   # echo "size of: serverlistMenuItems: ${#serverlistMenuItems[@]}     "
   # echo "terminal_width: ${terminal_width}"
}

function determine_longest_string_in_array_by_keyword {
   local keyword="${1}"
   local longest_string="${#keyword}"
   local iterator="0"
   
   for each in "${serverlistMenuItems[@]}"; do 
      if [[ "${#serverlistArray[${serverlistMenuItems[${iterator}]},${keyword}]}" -gt "${longest_string}" ]]; then 
         longest_string="${#serverlistArray[${serverlistMenuItems[${iterator}]},${keyword}]}"; 
      fi
      ((iterator++))
   done

   echo "${longest_string}"
}

function draw_connection_list {
   
   # longest_string="0"
   # local iterator="0"; for each in "${serverlistMenuItems[@]}"; do 
   #    if [[ "${#serverlistArray[${serverlistMenuItems[${iterator}]},entry_name]}" -gt "${longest_string}" ]]; then 
   #       longest_string="${#serverlistArray[${serverlistMenuItems[${iterator}]},entry_name]}"; 
   #    fi
   #    ((iterator++))
   # done

   if "${search_mode}"; then
      if [[ -z "${search_keyword}" ]]; then 
         echo "Error: empty search string, exiting"; exit 1
      fi

      grep_extra_arguments="--color"
      search_command="${search_keyword}"

      if "${ignore_case}"; then
         grep_extra_arguments="${grep_extra_arguments} -i"
      fi
   else
      grep_extra_arguments="--color=never"
      search_command="."
   fi

   list_keywords=( "short_key_id" "entry_name" "category" "ip_address" "protocol" "username" "password" "note" )
   for each in "${list_keywords[@]}"; do
      eval longest_"${each}"_string="$(determine_longest_string_in_array_by_keyword "${each}")"
   done

   short_key_id_print="$(eval "printf '─%.0s' {-1..$((longest_short_key_id_string))}")"
   entry_name_print="$(eval "printf '─%.0s' {-1..$((longest_entry_name_string))}")"
   category_print="$(eval "printf '─%.0s' {-1..$((longest_category_string))}")"
   ip_address_print="$(eval "printf '─%.0s' {-1..$((longest_ip_address_string))}")"
   protocol_print="$(eval "printf '─%.0s' {-1..$((longest_protocol_string))}")"
   username_print="$(eval "printf '─%.0s' {-1..$((longest_username_string))}")"
   password_print="$(eval "printf '─%.0s' {-1..$((longest_password_string))}")"
   note_print="$(eval "printf '─%.0s' {-1..$((longest_note_string))}")"
   iterator="0"


   printf "┌%s┬%s┬%s┬%s┬%s┬%s┬%s┬%s┐\n" "${short_key_id_print}" "${entry_name_print}" "${category_print}" "${ip_address_print}" "${protocol_print}" "${username_print}" "${password_print}" "${note_print}"

   printf "│ %-${longest_short_key_id_string}s │ %-${longest_entry_name_string}s │ %-${longest_category_string}s │ %-${longest_ip_address_string}s │ %-${longest_protocol_string}s │ %-${longest_username_string}s │ %-${longest_password_string}s │ %-${longest_note_string}s │\n" \
         "short_key_id" \
         "entry_name" \
         "category" \
         "ip_address" \
         "protocol" \
         "username" \
         "password" \
         "note"

   printf "├%s┼%s┼%s┼%s┼%s┼%s┼%s┼%s┤\n" "${short_key_id_print}" "${entry_name_print}" "${category_print}" "${ip_address_print}" "${protocol_print}" "${username_print}" "${password_print}" "${note_print}"
 
   for each in "${serverlistMenuItems[@]}"; do
      printf "│ %-${longest_short_key_id_string}s │ %-${longest_entry_name_string}s │ %-${longest_category_string}s │ %-${longest_ip_address_string}s │ %-${longest_protocol_string}s │ %-${longest_username_string}s │ %-${longest_password_string}s │ %-${longest_note_string}s │\n" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},short_key_id]}" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},entry_name]}" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},category]}" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},ip_address]}" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},protocol]}" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},username]}" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},password]}" \
         "${serverlistArray[${serverlistMenuItems[${iterator}]},note]}"

      ((iterator++))
   done | sort -t '|' -k2,2 -k3,3r | grep ${grep_extra_arguments} "${search_command}"

   printf "└%s┴%s┴%s┴%s┴%s┴%s┴%s┴%s┘\n" "${short_key_id_print}" "${entry_name_print}" "${category_print}" "${ip_address_print}" "${protocol_print}" "${username_print}" "${password_print}" "${note_print}"
}

function fake_loading_screen {
   for iterator in {1..5}; do
      printf "\t Loading... "
      eval "printf '■%.0s' {1..$((iterator))}"
      if [[ ${iterator} -lt 5 ]]; then eval "printf '□%.0s' {1..$((5-iterator))}"; fi
      echo -e "\e[1A"
      eval "sleep 0.$(($((RANDOM%8))+1))"
      #sleep 0.4
   done
}