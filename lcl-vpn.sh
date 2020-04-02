#!/bin/bash
# lcl-vpn.sh

# ping location
PING='/sbin/ping'

##############################################################
# *internal functions*
#
# connect to the VPN
function lcl-vpn-i-connect {
  local i_vpn_name="$1" ; shift

  /usr/bin/env osascript <<-EOF
tell application "System Events"
  tell current location of network preferences
    set VPN to service "$i_vpn_name"
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
function lcl-vpn-i-disconnect {
  local i_vpn_name="$1" ; shift

  /usr/bin/env osascript <<-EOF
tell application "System Events"
  tell current location of network preferences
    set VPN to service "$i_vpn_name"
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
function lcl-vpn-x-is-running {
  local i_vpn_name="$1" ; shift

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
function lcl-vpn-x-connect {
  local i_vpn_name="$1" ; shift

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
  lcl-vpn-i-connect "$i_vpn_name"
}
#
# disconnect from vpn
function lcl-vpn-x-disconnect {
  local i_vpn_name="$1" ; shift

  # do we already have VPN address?
  if ! ip a show ppp0 >/dev/null 2>&1 ; then
    echo 'VPN already down'
    return 2
  fi

  # shut it down
  echo 'Stopping VPN...'
  lcl-vpn-i-disconnect "$i_vpn_name"
}

########################################################################
# optional call support
l_do_run=0
if [ "x$1" != "x" ]; then
  [ "x$1" != "xsource-only" ] && l_do_run=1
fi
if [ $l_do_run -eq 1 ]; then
  l_func="$1"; shift
  [ x"$l_func" != x ] && eval lcl-vpn-x-"$l_func" "$@"
fi

