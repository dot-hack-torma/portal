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