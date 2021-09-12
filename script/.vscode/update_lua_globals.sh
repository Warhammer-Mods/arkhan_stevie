#!/bin/env bash
CUSTOM_VARS=(
  "ardm"
)

CONFIG_FILE="script/.luacheckrc"
LUA_VENDOR_FILES="script/.vscode/autocomplete"

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
    echo "\"${v}\""
  done
)

rm -f show_globals.lua

lua_globals=$(tr ' ' '\n' <<<"${lua_globals}" | 
sort -u  | tr '\n' ' ' | sed 's/, $//')

config="globals={${lua_globals}}"

sed -i '/^globals=.*$/d' ${CONFIG_FILE}
printf '%s\n' "${config}" >> ${CONFIG_FILE}
