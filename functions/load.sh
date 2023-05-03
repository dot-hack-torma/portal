#!/usr/bin/env bash
# shellcheck disable=1090,2034,2154,2155,2235

# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝
#
function load_config_file {
   # Check if a change in the configfile path is not already changed, if it is
   #     use that value, if it isn't, we 
   path_to_config_file=${PORTAL_CONFIG_FILEPATH:-"/home/$(whoami)/.portal/.config"}

   if ! [[ -f "${path_to_config_file}" ]]; then
      echo "Config file does not exist, proceeding with default values, some things may not work as intended"
      echo "If you wish to create a default config file to edit, please run the script with the \"--init\" flag"
      return 1
   fi

   source "${path_to_config_file}"

   if [[ -n "${data_files_location}" ]] && [[ -d ${data_files_location} ]]; then
      PATHS_FOR_DATAFILES="${data_files_location}"
   elif [[ -n "${PATHS_FOR_DATAFILES}" ]]; then
      :
   else
      echo "Cannot set \"${data_files_location}\" as data files dir, no directory found"
      exit 1
   fi

   if [[ -n "${browser}" ]]; then
      if command -v "${browser}" >/dev/null 2>&1; then
         case ${browser} in 
            vivaldi)
               declare -g BROWSER_NEW_TAB_METHOD="vivaldi --parent-window"
               ;;

            chrome)
               declare -g BROWSER_NEW_TAB_METHOD="google-chrome --new-window"
               ;;

            firefox)
               declare -g BROWSER_NEW_TAB_METHOD="firefox --new-window"
               ;;

            *)
               echo  "Unsupported browser, exiting"
               exit 1
               ;;
         esac
      fi
   else
      declare -g BROWSER_NEW_TAB_METHOD="echo"
      echo "Browser not set, will not be able to start any http connections."
   fi

   if [[ -n "${infinite_loop}" ]] && ( [[ "${infinite_loop}" == "true" ]] || [[ "${infinite_loop}" == "false" ]] ); then
      endless_loop="${infinite_loop}"
   fi

   # Check if variable exists and if variable is a number, and to quote from a 
   #     source: "Basically any numeric value evaluation operations using 
   #     non-numbers will result in an error which will be implicitly 
   #     considered as false in shell"
   if [[ -n "${page_size}" ]] && [[ "${page_size}" -eq "${page_size}" ]]; then
      PAGE_SIZE=${page_size}
   fi

}

# Get a list of all the .csv files we wish to read
function get_list_of_csv_files {
   for path in "${PATHS_FOR_DATAFILES[@]}"; do
      if ! [[ -d "${path}" ]]; then
         echo "Exiting, dir to .csv files not found: ${path}"
         echo "   Create the directory and populate with .csv files"
         echo "   or double check the configuration for the correct"
         echo "   .csv files location"
         exit 1
      fi

      while read -r file; do
         set_of_csv_files+=( "${file}" )
      done < <(find "${path}" -type f -iname "*.csv")
   done
}

# Load header of .csv file, so we know the key values by which we can sort and 
#     interact with. I've adjusted it like this so it's adaptable for future
#     additions of keywords.
function load_key_values {
   local KEY_VALUES="$(awk "NR==1{print}" "${set_of_csv_files[0]}")"

   iterator=0; old_IFS=${IFS}; IFS=" "
   for key_value in ${KEY_VALUES//,/ }; do
      ((iterator++))
      eval serverlistKeyArray[${iterator}]="${key_value}"
   done; IFS="${old_IFS}"
}

# Load all of the values from the supplied .csv files into memory (array)
function load_csv_file_values {
   iterator=0; old_IFS=${IFS}; IFS=","
   for file in "${set_of_csv_files[@]}"; do
      { 
         # Ignore first entry as that is the header of the .csv file.
         read -r
         while read -r item; do

            # We ignore any commented out values
            if [[ "${item}" == "#"* ]]; then continue; fi
            
            iterator=0
            for key_value in ${item}; do
               if [[ ${iterator} == 0 ]]; then entry_name="${key_value}"; fi

               ((iterator++))
               serverlistArray[${entry_name},${serverlistKeyArray[${iterator}]}]="${key_value}"
            done
         done 

         
      } < "${file}"
   done

   IFS="${old_IFS}"
}

# Load all menu items (each of the entries in the .csv file) into memory, so 
#     we can list them within the menu.
#
# Note: We can add different types of sorting from within this menu, currently, 
#     it's only sorted by name, but we could add by category (which I'm 
#     currently implementing slowly...)
function load_menu_items {
   readarray -t serverlistMenuItems < <(for each in "${!serverlistArray[@]}"; do echo -e "${each//,*/}"; done | sort -n | uniq)

   # for each in "${!serverlistArray[@]}"; do echo -e "${serverlistArray[${each//,*/},protocol]}:${each//,*/} ${serverlistArray[${each//,*/},protocol]}"; done

   #for each in "${!serverlistArray[@]}"; do echo -e "${each//,*/} ${serverlistArray[${each//,*/},protocol]}"; done | sort -t ' ' -k2h,1 -k1h,2 

   # readarray -t serverlistMenuItems < <(for each in "${!serverlistArray[@]}"; do echo -e "${serverlistArray[${each//,*/},protocol]}:${each//,*/} ${serverlistArray[${each//,*/},protocol]}"; done | sort -t ' ' -k2h,1 -k1h,2 | uniq | cut -d' ' -f1)
}