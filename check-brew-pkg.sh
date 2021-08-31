#!/bin/sh

l_search_all=0
[ x"all" = x"$1" ] && shift && l_search_all=1

for i in $* ; do
  l_the_value="$i"
  [ $l_search_all -eq 1 ] && l_the_value=".*${1}.*"
  #set -x
  l_found_items=$(brew search 2>/dev/null | grep -i -e "^$l_the_value\$")
  for j in $l_found_items ; do
    echo "brew install --formula $j"
  done
  l_found_items=$(brew search --casks 2>/dev/null | grep -i -e "^$l_the_value\$")
  for j in $l_found_items ; do
    echo "brew install --cask $j"
  done
done

