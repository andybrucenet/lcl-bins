#!/bin/bash
# lcl-start-vpn.sh

# vpn name
the_vpn_name='vpn-lmil'

# connect to the VPN
function vpn-connect {
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

function vpn-disconnect {
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



# only run if we are online
if ping -c 1 google.com >/dev/null 2>&1 ; then
  # do we already have VPN address?
  if ip a show ppp0 >/dev/null 2>&1 ; then
    echo VPN is up
    exit 0
  fi

  # start it up
  vpn-connect
fi

