#!/bin/bash
# lcl-start-vpn.sh

# vpn name
the_vpn_name='vpn-lmil'

# ping location
PING='/sbin/ping'

##############################################################
# *internal functions*
#
# connect to the VPN
function lcl-start-vpn-i-connect {
  /usr/bin/env osascript <<-EOF
tell application "System Events"
  tell current location of network preferences
    set VPN to service "$the_vpn_name"
    if exists VPN then
      connect VPN
      repeat while (current configuration of VPN is not connected)
        delay 1
      end repeat
    end if
  end tell
end tell
EOF
}
#
# disconnect
function lcl-start-vpn-i-disconnect {
  /usr/bin/env osascript <<-EOF
tell application "System Events"
  tell current location of network preferences
    set VPN to service "$the_vpn_name"
    if exists VPN then disconnect VPN
  end tell
end tell
return
EOF
}

##############################################################
# external functions
#
# is vpn connected?
function lcl-start-vpn-x-is-running {
  # only run if we are online
  if ! $PING -c 1 google.com >/dev/null 2>&1 ; then
    echo 'Not online...ignoring'
    return 1
  fi

  # do we already have VPN address?
  if ip a show ppp0 >/dev/null 2>&1 ; then
    return 0
  fi

  return 2
}
# connect to vpn
function lcl-start-vpn-x-connect {
  # only run if we are online
  if ! $PING -c 1 google.com >/dev/null 2>&1 ; then
    echo 'Not online...ignoring'
    return 1
  fi

  # do we already have VPN address?
  if ip a show ppp0 >/dev/null 2>&1 ; then
    echo 'VPN already up'
    return 2
  fi

  # start it up
  echo 'Starting VPN...'
  lcl-start-vpn-i-connect
}
#
# disconnect from vpn
function lcl-start-vpn-x-disconnect {
  # do we already have VPN address?
  if ! ip a show ppp0 >/dev/null 2>&1 ; then
    echo 'VPN already down'
    return 2
  fi

  # shut it down
  echo 'Stopping VPN...'
  lcl-start-vpn-i-disconnect
}

########################################################################
# optional call support
l_do_run=0
if [ "x$1" != "x" ]; then
  [ "x$1" != "xsource-only" ] && l_do_run=1
fi
if [ $l_do_run -eq 1 ]; then
  l_func="$1"; shift
  [ x"$l_func" != x ] && eval lcl-start-vpn-x-"$l_func" "$@"
fi

