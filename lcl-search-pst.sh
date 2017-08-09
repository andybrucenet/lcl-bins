#!/bin/bash
# lcl-search-pst.sh, ABr
# search email archives
# examples:
#   ./lcl-search-pst.sh grepmail -q -i lm1771
#   ./lcl-search-pst.sh -x 20170713-my-backup.7z grepmail -q -h 'Empty Host Compliance' | grep -e 'From: \|Date: '
#
# Use '-x' to pass in specific filenames. Otherwise all .7z files are scanned

do_search_1() {
  local i_file="$1"; shift

  local l_rc=0
  local l_pst=''
  local l_tmp="/tmp/$$.foo"
  local l_i=''
  local l_j=''

  # remove existing
  rm -f *.pst

  # decompress to local folder
  7z e -y "$i_file" > "$l_tmp" 2>&1
  l_rc=$?
  [ $l_rc -ne 0 ] && echo "$i_file (7z): ERROR" && cat "$l_tmp" && rm -f "$l_tmp" && return $l_rc

  # find all PST files created
  for l_i in *.pst ; do
    # kill the PST output folder contents
    rm -fR ./pst-output/*

    # reload PST output folder
    readpst -o ./pst-output -w "$l_i" > "$l_tmp" 2>&1
    l_rc=$?
    [ $l_rc -ne 0 ] && echo "$l_i (readpst): ERROR" && cat "$l_tmp" && break

    # iterate over all PST output folder contents
    for l_j in ./pst-output/* ; do
      #set -x
      "$@" "$l_j"
      set +x
    done
  done

  # done with tmp file
  rm -f "$l_tmp"
  return $l_rc
}

# make PST output folder
mkdir -p ./pst-output

# iterate over files
l_the_files=''
while [ x"$1" = x'-x' ] ; do
  shift
  l_the_files="$l_the_files $1"
  shift
done
l_rc=0
if [ x"$l_the_files" = x ] ; then
  for i in *.7z ; do
    do_search_1 "$i" "$@"
    l_rc=$?
    [ $l_rc -ne 0 ] && break
  done
else
  for i in $l_the_files ; do
    do_search_1 "$i" "$@"
    set +x
    l_rc=$?
    [ $l_rc -ne 0 ] && break
  done
fi
rm -fR *.pst ./pst-output
exit $l_rc

