#!/bin/env bash

CONFIG_FILE=".luacheckrc"
LUA_VENDOR_FILES=".vscode/autocomplete"

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

curl -sL --fail \
  https://gistcdn.githack.com/Egor-Skriptunoff/e4ab3bfc777faf4482a1b3f3ae19181b/raw/a39198cf62a52be7956abbff145a7fbf3f9a128a/show_globals.lua \
> show_globals.lua

lua_globals=$(
  for f in $(
    find ${LUA_VENDOR_FILES} -type f -iname "*.lua"
  ); do 
    lua show_globals.lua W < $f | 
    awk -F"\t" '{printf "\"%s\",\n", $2}'
  done
  
  for v in ${CUSTOM_VARS[@]}; do
    echo "\"${v}\","
  done
)

rm -f show_globals.lua

lua_globals=$(
  tr ' ' '\n' <<<"${lua_globals}" | 
  sort -u  | 
  tr '\n' ' ' | 
  sed 's/, $//'
)

config="globals = { ${lua_globals} }"

sed -i '/^globals\s*=\s*.*$/d' ${CONFIG_FILE}
printf '%s\n' "${config}" >> ${CONFIG_FILE}
