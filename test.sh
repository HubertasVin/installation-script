#!/bin/bash

# test_file="/home/hubertas/test"
# test_content="/home/hubertas/test2"
#
# temp_file=$(mktemp)
#
# awk -v insert="$(<"$test_content")" '
#   /return {/ {
#     print $0
#     print insert
#     print ""
#     next
#   }
#   { print }
# ' "$test_file" > "$temp_file"
#
# mv "$temp_file" "$test_file"

scriptLoc=$PWD

temp_file=$(mktemp)

awk -v insert="$(<"$scriptLoc/user_config/nvim/PLUGINS_INSERTION")" '
  /return {/ {
    print $0
    print insert
    print ""
    next
  }
  { print }
' "$HOME/test" > "$temp_file"
# "$HOME/.config/nvim/lua/plugins/init.lua"
mv "$temp_file" "$HOME/test"
