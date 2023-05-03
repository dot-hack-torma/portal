#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154,2155

# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
function menu_movement {
   local input_menu="${1}"

   menu_item_count=${#serverlistMenuItems[@]}; ((menu_item_count--))

   while true; do
      wait_for_input

      if [[ -n ${key_stroke} ]]; then 
         case ${key_stroke} in
            "up") 
               ((y_cursor_position--))
               if [[ "${y_cursor_position}" -lt 0 ]]; then 
                  y_cursor_position=${menu_item_count}
                  current_page=${number_of_pages}
               fi

               if [[ $((y_cursor_position%PAGE_SIZE)) -eq $((PAGE_SIZE-1)) ]]; then 
                  ((current_page--))
                  if [[ ${current_page} -lt 1 ]]; then
                     current_page=1
                  fi
               fi

               loop_once="true"
               ;;

            "down") 
               ((y_cursor_position++))
               if [[ "${y_cursor_position}" -gt "${menu_item_count}" ]]; then 
                  y_cursor_position="0"
                  current_page=1
               fi

               if [[ $((y_cursor_position%PAGE_SIZE)) -eq 0 ]] && [[ ${y_cursor_position} -ne 0 ]]; then 
                  ((current_page++))
                  if [[ ${current_page} -gt $((current_page+1)) ]]; then
                     current_page=1
                  fi
               fi
               loop_once="true"
               ;;

            "page_up")
               ((current_page--))
               if [[ ${current_page} -lt 1 ]]; then
                  current_page=1
               fi

               y_cursor_position=$((y_cursor_position-PAGE_SIZE))
               if [[ "${y_cursor_position}" -lt 0 ]]; then 
                  y_cursor_position=0
                  current_page=1
               fi
               loop_once="true"
               ;;

            "page_down")
               ((current_page++))
               if [[ ${current_page} -gt $((number_of_pages+1)) ]]; then
                  current_page=1
               fi

               y_cursor_position=$((PAGE_SIZE+y_cursor_position))
               if [[ "${y_cursor_position}" -gt "${menu_item_count}" ]]; then 
                  y_cursor_position=${menu_item_count}
                  current_page=${number_of_pages}
               fi
               loop_once="true"
               ;;

            "right") 
               #echo "You pressed right"
               ;;
            "left") 
               #echo "You pressed left"
               ;;
            "confirm") 
               menu_selection=${serverlistMenuItems[${y_cursor_position}]//*:/}
               action="confirm"
               break
               ;;
            "cancel") 
               menu_selection=""
               action="cancel"
               break
               ;;
            "command") 
               #echo "You pressed COMMAND"
               ;;
         esac

         key_stroke="";
         if ! ${skip_clear}; then clear; loop_once="false"; skip_clear="true"; fi
         draw_menu "main"
      fi
   done
}

function main_menu {
   number_of_pages=$((${#serverlistMenuItems[@]}/PAGE_SIZE)); ((number_of_pages++))
   if [[ $((${#serverlistMenuItems[@]}%PAGE_SIZE)) -eq 0 ]]; then ((number_of_pages--)); fi

   clear; draw_menu main
   
   while true; do
      menu_movement "main"

      if [[ "${action}" == "confirm" ]]; then

         echo -e "\e[2A"
         draw_mid_divider
         #draw_line_set_length "Selected: ${INVERT_COLOR} ${menu_selection} ${CLR}" 10
         
         # for key_value in "${serverlistKeyArraySorted[@]}"; do
         #    if [[ -n "${serverlistArray[${menu_selection},${key_value}]}" ]]; then
         #       draw_line_set_length "  ${GREEN}${key_value}${CLR}: ${serverlistArray[${menu_selection},${key_value}]}" "17"
         #    fi
         # done

         do_action "${serverlistArray[${menu_selection},protocol]}"
         sleep 2

         if ! ${endless_loop}; then 
            draw_line_colour_set_length_align_right "Portal closed -- goodbye!" "0"
            draw_bot_divider
            exit 0
         fi

         draw_bot_divider

         loop_once="false"
         skip_clear="true"

      elif [[ "${action}" == "cancel" ]]; then
         echo "cancel"; sleep 1 # just for debugging
         loop_once="false"
      fi

      key_stroke="" # Reset keystroke
      if ! ${skip_clear}; then clear; draw_menu main; fi
      skip_clear="false"
   done
}

function do_action {
   local method="${1}"
   ${gui_mode} && fake_loading_screen
   reenable_input

   case ${method} in
      http)
         eval "${BROWSER_NEW_TAB_METHOD}" "${serverlistArray[${menu_selection},hostname]}" 2>/dev/null
         ;;

      ssh)
         expect_ssh_connection
         #"${AUTOINSERT_PASSWORD_EXPECT_SCRIPT}" "${serverlistArray[${menu_selection},password]}" ssh "${serverlistArray[${menu_selection},username]}@${serverlistArray[${menu_selection},hostname]}" -p "${serverlistArray[${menu_selection},port]}"
         ;;

      sftp)
         nautilus sftp://"${serverlistArray[${menu_selection},username]}@${serverlistArray[${menu_selection},hostname]}"/ 2>/dev/null &
         #"${AUTOINSERT_PASSWORD_EXPECT_SCRIPT}" "${serverlistArray[${menu_selection},password]}" | nautilus sftp://"${serverlistArray[${menu_selection},username]}@${serverlistArray[${menu_selection},hostname]}"/ 2>/dev/null &
         #echo "${serverlistArray[${menu_selection},password]}" | nautilus sftp://"${serverlistArray[${menu_selection},username]}@${serverlistArray[${menu_selection},hostname]}"/ 2>/dev/null &
         ;;
   esac

   hide_input
}