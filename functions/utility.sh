#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154,2155

# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
function update_width {
   if ${FIRST_WIDTH_SETUP}; then
      old_width="${terminal_width}"
      FIRST_WIDTH_SETUP="false"
   fi

   terminal_width="$(($(tput cols)/3))"

   # Make sure that the terminal is not too narrow and that the mid alignment 
   if [[ ${terminal_width} -lt 60 ]]; then terminal_width="60"; fi
   if [[ $((terminal_width%2)) -ne 0 ]]; then ((terminal_width--)); fi

   divider_inner_menu_width="$((terminal_width-2))"
   inner_menu_width="$((terminal_width-4))"

   if [[ ${old_width} -ne ${terminal_width} ]]; then
      loop_once="false"
      clear
      #echo djwioadjaw; sleep 2
   fi
   
   old_width="${terminal_width}"
}

function hide_input {
   stty -echo
   tput civis
}

function reenable_input {
   stty echo
   tput cnorm
}

function expect_ssh_connection {
   expect -c "
   set timeout 20
   spawn ssh ${serverlistArray[${menu_selection},username]}@${serverlistArray[${menu_selection},hostname]} -p ${serverlistArray[${menu_selection},port]}
   expect \"*?assword\" { send \"${serverlistArray[${menu_selection},password]}\r\" }
   interact
   "
}

# Create initial default configuration file for this script to work, and add 
#     the bash completion to it. Afterwards source it to have the completion in place
function initial_setup {
   path_to_config_file=${PORTAL_CONFIG_FILEPATH:-"/home/$(whoami)/.portal/.config"}

   if ! [[ -d "/home/$(whoami)/.portal/" ]]; then
      mkdir -pv "/home/$(whoami)/.portal/" || 
         echo "Unable to portal data location directory" 
   fi

   if [[ -f ${path_to_config_file} ]] && ! "${force_overwrite}"; then
      echo
      echo "Cannot perform initial setup, config file already found on path: ${path_to_config_file}"
      exit 1
   else
      :>"${path_to_config_file}"
      cat <<\EOF >> "${path_to_config_file}"
# Configuration file for the portal script, readjusting this file should
#     pre-set some values when starting portal without any additional 
#     explicit flags. Flags added to the script have precedent over this
#     configuration file.
#
# Define location of the .csv files from where the script will load the 
# data from. 
# Default: "/home/\$(whoami)/.portal/data" defined within the script
#data_files_location=""
#
# Define the default browser you are using in case the http protocol is
# used. Currently usable values are: chrome, firefox, vivaldi.
browser="vivaldi"
#
# Define whether the gui will loop within the menu infinitely or will 
# exit after the first connection is established. Values: true, false.
# Setting it to true will allow the script to loop infinitely until you
# explicitly CTRL+C out of the loop.
infinite_loop="flase"
#
# Define the number of entries allowed on each of the pages within the 
# gui mode. This is something that might be modular in the future, but
# at this point, it's statically set up, which is by default 20.
#page_size="20"
EOF
      echo
      echo "Created initial .config file at ${path_to_config_file}"
      echo "Please adjust the file in accordance to your needs and"
      echo "feel free to use the portal script now :)"
   fi



   path_to_bashcomplete_file=${PORTAL_BASH_COMPLETE_FILEPATH:-"/home/$(whoami)/.portal/portal-completion.bash"}
   if [[ -f ${path_to_bashcomplete_file} ]]  && ! "${force_overwrite}"; then
      echo
      echo "Bash completion file found and sourcing it at: ${path_to_bashcomplete_file}"
      bash_completion

   else

   :>"${path_to_bashcomplete_file}"
   cat <<\EOF >> "${path_to_bashcomplete_file}"
#!/usr/bin/env bash

PATHS_FOR_DATAFILES=( "/home/$(whoami)/.portal/data" )

function portal_completions {
   local IFS=$'\n'
   local suggestions=($(compgen -W "$(cat ${PATHS_FOR_DATAFILES}/* | grep -v '^\#' | awk -v get='^protocol' 'BEGIN{FS=OFS=","}FNR==1{for(i=1;i<=NF;i++)if($i~get)cols[++c]=i}{for(i=1; i<=c; i++)printf "%s%s", $(cols[i]), (i<c ? OFS : ORS)}' | sort | uniq | grep -v protocol | grep .)" -- "${COMP_WORDS[1]}" ))

   if [[ "${#COMP_WORDS[@]}" -gt "3" ]]; then
      return
   elif [[ "${#COMP_WORDS[@]}" -gt "2" ]] && [[ "${COMP_WORDS[1]}" != "--gui" ]]; then
      local suggestions=($(compgen -W "$(cat ${PATHS_FOR_DATAFILES}/* | grep -v '^\#' | grep -E ",${COMP_WORDS[1]},|entry_name" | awk -v get='^entry_name' 'BEGIN{FS=OFS=","}FNR==1{for(i=1;i<=NF;i++)if($i~get)cols[++c]=i}{for(i=1; i<=c; i++)printf "%s%s", $(cols[i]), (i<c ? OFS : ORS)}' | sort | uniq | grep -v entry_name | grep .)" -- "${COMP_WORDS[2]}" ))
   elif [[ "${#COMP_WORDS[@]}" -gt "2" ]]; then
      return
   fi

   COMPREPLY=("${suggestions[@]}")
}

complete -F portal_completions portal
EOF

      echo
      echo "Created portal-completion.bash file and sourced it: ${path_to_bashcomplete_file}"
      echo "Bash completion should work now"
      bash_completion
   fi
}

function check_for_connection {
   if [[ -n "${serverlistArray[${menu_selection},entry_name]}" ]]; then
      return 0
   fi

   local old_selection=${menu_selection}
   local selection_found="false"
   local iterator=0
   for each in "${serverlistMenuItems[@]}"; do 
      if [[ "${serverlistArray[${serverlistMenuItems[${iterator}]},short_key_id]}" == "${menu_selection}" ]]; then 
         menu_selection="${serverlistArray[${serverlistMenuItems[${iterator}]},entry_name]}"
         selection_found="true"
         break
      fi
      ((iterator++))
   done

   if ${selection_found}; then
      echo "Found connection with unique keyword ${GREEN}${old_selection}${CLR}: ${GREEN}${menu_selection}${CLR}"
      echo "Proceeding with connection..."
   else
      echo "Error: no connection like that (${RED}${menu_selection}${CLR}) found, exiting."; exit 1
   fi
}

function bash_completion {
   path_to_bashcomplete_file=${PORTAL_BASH_COMPLETE_FILEPATH:-"/home/$(whoami)/.portal/portal-completion.bash"}

   if [[ -f "${path_to_bashcomplete_file}" ]]; then
      echo "File to source found, please source file or add the source command to your .bashrc file. Examples:"
      echo
      echo "source ${path_to_bashcomplete_file}"
      echo "echo \"source ${path_to_bashcomplete_file}\" >> /home/$(whoami)/.bashrc"
   else
      echo "Cannot find bash completion file, exiting "
   fi
}

# ████████╗██████╗  █████╗ ██████╗ 
# ╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗
#    ██║   ██████╔╝███████║██████╔╝
#    ██║   ██╔══██╗██╔══██║██╔═══╝ 
#    ██║   ██║  ██║██║  ██║██║     
#    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     

# Reset terminal to current state when we exit.
trap reenable_input EXIT

