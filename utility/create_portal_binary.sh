#!/bin/bash
congregate_file="con_port_temp_file"

# Creation of the congregate script file
cd ..
echo '#!/bin/bash' > "${congregate_file}" || exit 1
grep 'declare -g script_path' portal.sh >> "${congregate_file}"
while read -r filename; do
   tail -n +1 "${filename}" | grep -v '#!/' >> "${congregate_file}"
done <<< "$(find functions -type f -name "*.sh")"
grep -v "[ ][ ]source_functions" portal.sh >> "${congregate_file}"

#mv "${congregate_file}" utility || exit 1
#cd utility || exit 1

# Create dynamically linked binary (doesn't usually work on other systems, since duh, dynamically linked)
# shc -r -f "${congregate_file}" || exit 1
# mv "${congregate_file}".x portal | exit 1
# rm -f "${congregate_file}"*

# Create statically linked binary
/home/dtorma/Materia/git/bashc/releases/bashc "${congregate_file}" portal || exit 1
rm -f "${congregate_file}"