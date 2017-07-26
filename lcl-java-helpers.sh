#!/bin/bash
# lcl-java-helpers.sh, ABr
# Setup apache commons and other cruft

########################################################################
# setup for groovy
function lcl-java-helpers-x-groovy-jars {
  # pass in the home directory
  local i_home_dir="${1:-$HOME}"

  # locals
  local l_rc=0
  local l_pwd=''
  local l_packages=''
  local l_tmp_dir=''
  local l_package_name=''
  local l_package_uri=''
  local l_jar_files=''
  
  echo "Using HOME of '$i_home_dir'..."
  echo ''

  # initialize
  l_packages=$(printf '%s' \
    'commons-net:http://mirrors.sonic.net/apache/commons/net/binaries/commons-net-3.6-bin.tar.gz' \
    ' commons-compress:http://mirrors.ibiblio.org/apache/commons/compress/binaries/commons-compress-1.14-bin.tar.gz'
  )
  l_tmp_dir="/tmp/lcl-java-helpers-x-groovy-jars.$$"

  # work folder
  echo -n "Create work folder..."
  l_pwd="$PWD"
  mkdir -p "$l_tmp_dir"
  l_rc=$?
  [ $l_rc -ne 0 ] && echo 'Failure' && return $l_rc
  echo 'OK'
  echo ''

  # process
  for i in $l_packages ; do
    l_package_name=$(echo "$i" | sed -e 's#^\([^:]\+\):\(.*\)$#\1#')
    l_package_uri=$(echo "$i" | sed -e 's#^\([^:]\+\):\(.*\)$#\2#')
    echo "Process $l_package_name ($l_package_uri)..."
    cd "$l_tmp_dir"
    l_jar_files=$(\
      curl -q -L -k "$l_package_uri" 2>/dev/null | tar xz -C . \
      && find . -name '*.jar' | grep -e "${l_package_name}-[0-9.]\+jar" \
    )
    l_rc=$?
    [ $l_rc -ne 0 ] && break
    mkdir -p "$i_home_dir"/.groovy/lib/
    for j in $l_jar_files ; do
      echo "  Found $j..."
      yes | cp "$l_tmp_dir"/$j "$i_home_dir"/.groovy/lib/
      l_rc=$?
      [ $l_rc -ne 0 ] && break
    done
    echo ''
    cd "$l_pwd"
    [ $l_rc -ne 0 ] && break
  done

  # complete
  echo "Cleanup..."
  cd "$l_pwd"
  rm -fR "$l_tmp_dir"
  [ $l_rc -ne 0 ] && echo 'Failure'
  return $l_rc
}

########################################################################
# optional call support
l_do_run=0
if [ "x$1" != "x" ]; then
  [ "x$1" != "xsource-only" ] && l_do_run=1
fi
if [ $l_do_run -eq 1 ]; then
  l_func="$1"; shift
  [ x"$l_func" != x ] && eval lcl-java-helpers-x-"$l_func" "$@"
fi

