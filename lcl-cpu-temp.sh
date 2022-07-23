#!/bin/bash
# lcl-cpu-temp.sh, ABr
# Temperature on supported platforms

the_os="`uname -s | dos2unix`"
if [ x"$the_os" = xDarwin ] ; then
  sudo powermetrics --samplers smc -n 1 |grep -i "temperature"
else
  echo "unsupported platform: $the_os"
fi

