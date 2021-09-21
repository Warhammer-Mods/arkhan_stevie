#!/bin/env bash

CONFIG_FILE=${LUACHECK_CONFIG:-'.luacheckrc'}
LUA_VENDOR_FILES=${VENDOR_PATH:-'.vscode/autocomplete'}

CUSTOM_VARS=()
if [[ "${CUSTOM_LUA_GLOBALS}" ]]; then
  for g in ${CUSTOM_LUA_GLOBALS}; do
    CUSTOM_VARS+=("${g}")
  done
fi

# get script arguments
PARAMS=""

while (( "$#" )); do
  [[ $1 == --*=* ]] && set -- "${1%%=*}" "${1#*=}" "${@:2}"
  case "$1" in
    -g|--global)
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
        CUSTOM_VARS+=("$2")
        shift 2
      else
        echo "Error: Argument for $1 is missing" >&2
        exit 1
      fi
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
      PARAMS="$PARAMS $1"
      shift
      ;;
  esac
done

# set positional arguments in their proper place
eval set -- "$PARAMS"

# build the list of lua globals exported
lua_globals=$(
  for f in $(
    find ${LUA_VENDOR_FILES} -type f -iname "*.lua"
  ); do 
    lua .vscode/show_globals.lua W < $f | 
    awk -F"\t" '{printf "\"%s\",\n", $2}'
  done
  
  for v in ${CUSTOM_VARS[@]}; do
    echo "\"${v}\","
  done
)

# reformat the list of lua globals
lua_globals=$(
  tr ' ' '\n' <<< "${lua_globals}" | 
  sort -u | 
  tr '\n' ' ' | 
  sed 's/,\s*$//'
)

# update luacheck config
config="globals = { ${lua_globals} }"
sed -i '/^globals\s*=\s*.*$/d' ${CONFIG_FILE}
printf '%s\n' "${config}" >> ${CONFIG_FILE}
