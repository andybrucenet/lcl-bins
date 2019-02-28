#!/bin/bash

# locate sed (latest brew installs only to gsed)
the_sed=$(which gsed 2>/dev/null)
[ x"$the_sed" = x ] && the_sed=$(which sed)
echo "Using '$the_sed'"

# locate the chef-user
the_chef_user=$(ls -ld $(which brew) | awk '{print $3}')
echo "Found the_chef_user='$the_chef_user'"

# these are in here to allow this script to work directly in chef recipe
fool_ruby_parser='\'
fool_ruby_parser+='1'

# iterate over all installed casks
for i in $(sudo -u $the_chef_user brew cask list) ; do
  echo -n "Unquarantine $i: "
  the_app_path=''
  the_dir=$(find /usr/local/Caskroom -name $i -type d 2>/dev/null)
  l_rc=$? ; [ $l_rc -ne 0 ] && echo "find /usr/local/Caskroom fail with $l_rc" && continue
  [ x"$the_dir" = x ] && echo 'empty the_dir' && continue

  # are there artifacts available?
  if sudo -u $the_chef_user brew cask info $i 2>/dev/null | grep -ie '^==> Artifacts' >/dev/null 2>&1 ; then
    # *must* have an app
    the_app_name=$(sudo -u $the_chef_user brew cask info $i | grep -A10 -ie '^==> Artifacts' | grep -ie '(App)' | $the_sed -e "s/^\(.*\) \+(App)/$fool_ruby_parser/i")
    [ x"$the_app_name" != x ] && the_app_path="/Applications/$the_app_name"
  fi

  # if no app lookup from install file
  if [ x"$the_app_path" = x ] ; then
    # get the install file first
    the_installer_file=$(sudo -u $the_chef_user brew cask info $i | grep -ie '^from: ' | $the_sed -e "s/^from: \+\(.*\)/$fool_ruby_parser/i; s/^.*\/\([^\/]\+\)\$/$fool_ruby_parser/" | head -n 1)
    l_rc=$? ; [ $l_rc -ne 0 ] && echo "brew cask info fail with $l_rc" && continue
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
  sudo xattr -r -d com.apple.quarantine "$the_app_path"
  l_rc=$? ; [ $l_rc -ne 0 ] && echo "xattr fail $l_rc" && continue
  echo 'OK'
done

