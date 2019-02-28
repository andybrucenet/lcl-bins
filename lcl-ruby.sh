#!/bin/bash
# lcl-ruby.sh, ABr
# Run as a container :)

# overrides
g_LCL_RUBY_DOCKER_IMAGE="${LCL_RUBY_DOCKER_IMAGE:-sab/ruby}"
g_LCL_RUBY_DOCKER_ARGS="${LCL_RUBY_DOCKER_ARGS}"
g_LCL_RUBY_DOCKER_ENVS="${LCL_RUBY_DOCKER_ENVS}"
g_LCL_RUBY_DOCKER_OPTIONS="${LCL_RUBY_DOCKER_OPTIONS:---rm -it}"
g_LCL_RUBY_DOCKER_DEFAULT_VOLUMES="-v ${LCL_RUBY_DOCKER_DEFAULT_VOLUMES:-/tmp:/tmp:rw -v $PWD:/src:rw}"

# temp file to generate the call
l_docker_run="/tmp/lcl-ruby.$$"

# boilerplate to start
echo "docker run $g_LCL_RUBY_DOCKER_OPTIONS $g_LCL_RUBY_DOCKER_DEFAULT_VOLUMES \\" > "$l_docker_run"

# user-specified docker args - add after the hard-coded ones above to permit override
[ x"$g_LCL_RUBY_DOCKER_ARGS" != x ] && echo "  $g_LCL_RUBY_DOCKER_ARGS \\" >> "$l_docker_run"

# export specified environment variables to container
for i in $g_LCL_RUBY_DOCKER_ENVS ; do
  l_value="${!i}"
  echo "  -e $i=\"$l_value\" \\" >> "$l_docker_run"
done

# image to run
echo "  $g_LCL_RUBY_DOCKER_IMAGE \\" >> "$l_docker_run"

# arguments from caller
l_first_arg=1
for i in "$@" ; do
  if [ $l_first_arg -eq 1 ] ; then
    l_first_arg=0
    echo -n '  ' >> "$l_docker_run"
  else
    echo -n ' ' >> "$l_docker_run"
  fi
  normalized_i="$i"
  if echo "$normalized_i" | grep --quiet -e '\\' ; then
    normalized_i=$(echo "$normalized_i" | sed -e 's/\\/\\\\/g')
  fi
  if echo "$normalized_i" | grep --quiet -e ' \|!' ; then
    echo -n "'$normalized_i'" >> "$l_docker_run"
  else
    echo -n "$normalized_i" >> "$l_docker_run"
  fi
done
echo '' >> "$l_docker_run"

# run the container
#cat "$l_docker_run"
source "$l_docker_run"
l_rc=$?
rm -f "$l_docker_run"
exit $l_rc

