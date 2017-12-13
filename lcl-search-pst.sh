#!/bin/bash
# lcl-search-pst.sh, ABr
# search email archives
# examples:
#   ./lcl-search-pst.sh grepmail -q -i lm1771
#   ./lcl-search-pst.sh -x 20170713-my-backup.7z grepmail -q -h 'Empty Host Compliance' | grep -e 'From: \|Date: '
# Use '-x' to pass in specific filenames. Otherwise all .7z files are scanned
#
# To rebuild from original transfer (7za):
#   7z x [PST-FILE].001

do_search_1() {
  local i_file="$1"; shift

  local l_rc=0
  local l_pst=''
  local l_tmp="/tmp/$$.foo"
  local l_i=''
  local l_j=''
  local l_process=''

  # remove existing
  rm -f *.pst

  # construct tmp file for command
  l_process="/tmp/lcl-search-pst.$$"

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
      echo '#!/bin/bash' > "$l_process"
      for i in "$@" ; do
        if echo "$i" | grep --quiet -e ' ' ; then
          echo -n "'$i' " >> "$l_process"
        else
          echo -n "$i " >> "$l_process"
        fi
      done
      if grep --quiet -e '{}' "$l_process" ; then
        # replace with filename
        sed -i -e "s#{}#'$l_j'#g" "$l_process"
        echo '' >> "$l_process"
      else
        echo " '$l_j'" >> "$l_process"
      fi
      echo '' >> "$l_process"
      chmod +x "$l_process"
      #cat "$l_process"
      "$l_process"
      l_rc=$?
      rm -f "$l_process"
      [ $l_rc -ne 0 ] && break
    done
  done

  # done with tmp file
  rm -f "$l_tmp"
  return $l_rc
}

# handle empty
if [ x"$1" = x ] ; then
  echo "Usage: $(basename $0) [-x [PST-FILE] [-x [PST-FILE]] ...] [...CMD...]"
  echo '  CMD - usually grepmail; insert filename at {} (at end if not given)'
  echo 'Example (file appended to end):'
  echo "  $(basename $0) -x 20170101-backup.pst 'grepmail -H -i -e \"MyProject01\"'"
  echo 'Example (with file insertion):'
  echo "  $(basename $0) -x 20170101-backup.pst 'grepmail -H -i -e \"MyProject01\" {} && do-some-action'"
  exit 1
fi

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

