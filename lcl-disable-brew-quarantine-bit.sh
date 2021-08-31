#!/bin/bash

# save my path
THE_PATH="$0"
THE_CUR_USER="$(whoami)"

# locate sed (latest brew installs only to gsed)
the_sed=$(which gsed 2>/dev/null)
[ x"$the_sed" = x ] && the_sed=$(which sed)
echo "Using '$the_sed'"

# locate the brew-user
the_brew_user=$(ls -ld $(which brew) | awk '{print $3}')

# these are in here to allow this script to work directly in chef recipe
fool_ruby_parser='\'
fool_ruby_parser+='1'

# are we the current brew user?
if [ x"$the_brew_user" != x"$THE_CUR_USER" ] ; then
  # run command as different user
  echo "We are user '$THE_CUR_USER'."
  echo "We must become brew user '$the_brew_user'."
  echo "**Enter password for '$the_brew_user' when prompted:"
  the_rc=1
  while [ $the_rc -ne 0 ] ; do
    su $the_brew_user -c "$THE_PATH"
    the_rc=$?
    [ $the_rc -ne 0 ] && echo 'Try again...'
  done
  exit $the_rc
fi

# now we are the current brew user - issue a sudo cmd
echo ''
echo "We are now the brew user '$the_brew_user'."
echo "We are executing a privileged command."
echo "**Enter '$the_brew_user' password if prompted:"
sudo echo 'Privileged command executed OK.'
the_rc=$?
[ $the_rc -ne 0 ] && echo 'Failed privileged command. Exiting.' && exit $the_rc

# iterate over all installed casks
echo ''
echo '**Unquarantine brew applications...'
for i in $(sudo -u $the_brew_user brew list --casks) ; do
  echo -n "Unquarantine $i: "
  the_app_paths=''
  the_app_path=''
  the_dir=$(find /usr/local/Caskroom -name $i -type d 2>/dev/null)
  l_rc=$? ; [ $l_rc -ne 0 ] && echo "find /usr/local/Caskroom fail with $l_rc" && continue
  [ x"$the_dir" = x ] && echo 'empty the_dir' && continue

  # are there artifacts available?
  if sudo -u $the_brew_user brew info --cask $i 2>/dev/null | grep -ie '^==> Artifacts' >/dev/null 2>&1 ; then
    # *must* have an app
    the_app_name=$(sudo -u $the_brew_user brew info --cask $i | grep -A10 -ie '^==> Artifacts' | grep -ie '(App)' | head -n 1 | $the_sed -e "s/^\(.*\)  *(App)/$fool_ruby_parser/i")
    if echo "$the_app_name" | grep -e ' -> ' >/dev/null 2>&1 ; then
      # link specified - extract
      the_app_name=$(echo "$the_app_name" | awk -F' -> ' '{print $2}')
      if echo "$the_app_name" | grep -e ')$' ; then
        # some kind of parenthetical indicator
        the_app_name=$(echo "$the_app_name" | sed -e 's/^\(.*\) ([A-Za-z][A-Za-z]*)$/\1/')
      fi
    fi
    [ x"$the_app_name" != x ] && echo "$the_app_path" | grep -v '/' >/dev/null 2>&1 && the_app_path="/Applications/$the_app_name"
  fi

  # if no app lookup from install file
  if [ x"$the_app_path" = x ] ; then
    # get the install file first
    the_installer_file=$(sudo -u $the_brew_user brew info --cask $i | grep -ie '^from: ' | $the_sed -e "s/^from:  *\(.*\)/$fool_ruby_parser/i; s/^.*\/\([^\/][^\/]*\)\$/$fool_ruby_parser/" | head -n 1)
    l_rc=$? ; [ $l_rc -ne 0 ] && echo "brew info --cask fail with $l_rc" && continue
    [ x"$the_installer_file" = x ] && echo 'empty the_installer_file' && continue

    # where is it in brew?
    the_installer_path=$(find "$the_dir" -type f -name "$the_installer_file" 2>/dev/null | head -n 1)
    l_rc=$? ; [ $l_rc -ne 0 ] && echo "find $the_dir fail with $l_rc" && continue
    [ x"$the_installer_path" = x ] && echo "empty the_installer_path" && continue

    # extract the app name
    the_app_path=$(cat "$the_installer_path" | grep -e '/Applications/' | $the_sed -e "s/^.*\(\/Applications\/.*\.app\).*/$fool_ruby_parser/")
    l_rc=$? ; [ $l_rc -ne 0 ] && echo "grep /Applications/ fail with $l_rc" && continue
  fi
  [ x"$the_app_path" = x ] && echo 'empty the_app_path' && continue

  # app must be a valid name
  [ ! -d "$the_app_path" ] && echo "missing app '$the_app_path'" && continue

  # disable the quarantine bit on the discovered application
  sudo xattr -s -r -d com.apple.quarantine "$the_app_path"
  l_rc=$? ; [ $l_rc -ne 0 ] && echo "xattr fail $l_rc" && continue
  echo 'OK'
done
set +x

