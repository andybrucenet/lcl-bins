#!/bin/bash
# lcl-k8s.sh, ABr
# Up/Down

# How to use:
# 1. Set variables for K8s version and location
# 2. To start:
#      lcl-k8s.sh start
# 3. To stop:
#      lcl-k8s.sh stop
#
# "Start" brings up everything, including all post-Kubernetes
# deployments (such as DNS and Dashboard).
#
# "Stop" brings down everything - do *not* count on any K8s
# state being preserved.

# get vars we need (permit overrides)
g_DOCKER_KUBE_FOR_MAC_K8S_VERSION=${DOCKER_KUBE_FOR_MAC_K8S_VERSION:-1.7.3}
g_DOCKER_KUBE_FOR_MAC_LOCATION=${DOCKER_KUBE_FOR_MAC_LOCATION:-$(realpath .)}
g_DOCKER_KUBE_FOR_MAC_CONTEXT=${DOCKER_KUBE_FOR_MAC_CONTEXT:-kube-for-mac}
#g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_NAME=${DOCKER_KUBE_FOR_MAC_GLOBAL_PV_NAME:-global-pv}
#g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_LOCATION=${DOCKER_KUBE_FOR_MAC_GLOBAL_PV_LOCATION:-${HOME}/proj/work/local-k8s-global-pv}
#g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_SIZE=${DOCKER_KUBE_FOR_MAC_GLOBAL_PV_SIZE:-100Gi}

########################################################################
# single deployment
function lcl-k8s-i-deploy {
  # args
  local i_deploy_name="$1" ; shift
  local i_custom_name="$1" ; shift

  # locals
  local l_deploy_line=''
  local l_deploy_ready=0
  local l_rc=0
  local l_deploy_ready_lvalue=''
  local l_deploy_ready_rvalue=''

  echo -n "Deploy $*: "
  l_deploy_line=$(kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT get deploy --namespace=kube-system $i_deploy_name 2>/dev/null | grep -e "$i_deploy_name")
  if [ x"$l_deploy_line" = x ] ; then
    echo ''
    echo ''
    "$g_DOCKER_KUBE_FOR_MAC_LOCATION"/hacks/v${g_DOCKER_KUBE_FOR_MAC_K8S_VERSION}/run docker-kube-for-mac.sh custom source /etc/hacks-in/hacks.sh DEPLOY-$i_custom_name
  fi
  l_deploy_ready=0
  l_rc=0
  while [ $l_deploy_ready -eq 0 ] ; do
    l_deploy_line=$(kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT get deploy --namespace=kube-system $i_deploy_name 2>/dev/null | grep -e "$i_deploy_name")
    l_rc=$?
    if [ $l_rc -eq 0 ] ; then
      if [ x"$l_deploy_line" != x ] ; then
        l_deploy_ready_lvalue=$(echo "$l_deploy_line" | awk '{print $2}')
        l_deploy_ready_rvalue=$(echo "$l_deploy_line" | awk '{print $5}')
        [ x"$l_deploy_ready_lvalue" = x"$l_deploy_ready_rvalue" ] && l_deploy_ready=1
      fi
    fi
    [ $l_deploy_ready -eq 0 ] && sleep 5 && echo -n '.'
  done
  echo 'OK'
}

########################################################################
# start all - assumes from zero
function lcl-k8s-x-start {
  # start the cluster
  "$g_DOCKER_KUBE_FOR_MAC_LOCATION"/hacks/v${g_DOCKER_KUBE_FOR_MAC_K8S_VERSION}/run docker-kube-for-mac.sh start

  # locals
  local l_ready=0
  local l_comp_ready=0
  local l_comp_line=''
  local l_rc=0
  local l_comp_ready_lvalue=''
  local l_comp_ready_rvalue=''
  local l_tmp_file=''

  # all known controllers
  echo ''
  echo ''
  echo -n 'Wait for k8s controllers: '
  l_ready=0
  while [ $l_ready -eq 0 ] ; do
    l_ready=1
    for i in k8s-master k8s-etcd k8s-proxy ; do
      l_comp_ready=0
      l_comp_line=$(kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT get pods --namespace=kube-system 2>/dev/null | grep -e "$i" | awk '{print $2}')
      l_rc=$?
      if [ $l_rc -eq 0 ] ; then
        if [ x"$l_comp_line" != x ] ; then
          l_comp_ready_lvalue=$(echo "$l_comp_line" | awk -F'/' '{print $1}')
          l_comp_ready_rvalue=$(echo "$l_comp_line" | awk -F'/' '{print $2}')
          [ x"$l_comp_ready_lvalue" = x"$l_comp_ready_rvalue" ] && l_comp_ready=1
        fi
      fi
      [ $l_comp_ready -eq 0 ] && l_ready=0 && break
    done
    [ $l_ready -eq 0 ] && sleep 5 && echo -n '.'
  done
  echo 'OK'

  # deploy addons
  lcl-k8s-i-deploy 'kube-dns' 'DNS' 'DNS'
  lcl-k8s-i-deploy 'kubernetes-dashboard' 'DASHBOARD' 'Dashboard'

  # handle helm (tiller)
  if hash helm ; then
    l_comp_line=$(kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT get deploy tiller-deploy --namespace=kube-system 2>/dev/null | grep -e "tiller-deploy")
    if [ x"$l_comp_line" = x ] ; then
      helm init
      l_rc=$?
      [ $l_rc -ne 0 ] && echo "Failed helm init" && return $l_rc
    fi

    # wait for it to be ready...
    echo -n 'Wait for helm tiller: '
    l_comp_ready=0
    while [ $l_comp_ready -eq 0 ] ; do
      l_comp_line=$(kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT get deploy tiller-deploy --namespace=kube-system | grep -e "tiller-deploy")
      [ x"$l_comp_line" = x ] && echo "Failed to locate tiller-deploy" && return $l_rc
      l_comp_ready_lvalue=$(echo "$l_comp_line" | awk '{print $2}')
      l_comp_ready_rvalue=$(echo "$l_comp_line" | awk '{print $5}')
      [ x"$l_comp_ready_lvalue" = x"$l_comp_ready_rvalue" ] && l_comp_ready=1
      [ $l_comp_ready -eq 0 ] && echo -n '.' && sleep 4
    done
    echo 'OK'
  fi

#  # make sure we have a global pv available for ill-behaved apps
#  echo -n 'Check for global PV: '
#  mkdir -p "$g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_LOCATION"
#  l_comp_line=$(kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT get pv $g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_NAME 2>/dev/null | grep -e "$g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_NAME")
#  if [ x"$l_comp_line" = x ] ; then
#    echo -n 'Create: '
#    l_tmp_file="/tmp/lcl-k8s-x-start.$$"
#    cat > "$l_tmp_file" << EOF
#apiVersion: v1
#kind: PersistentVolume
#metadata:
#  name: $g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_NAME
#spec:
#  accessModes:
#  - ReadWriteOnce
#  capacity:
#    storage: $DOCKER_KUBE_FOR_MAC_GLOBAL_PV_SIZE
#  hostPath:
#    path: "$g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_LOCATION"
#EOF
#    #cat "$l_tmp_file"
#    kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT create -f "$l_tmp_file" >/dev/null 2>&1
#    l_rc=$?
#    set +x
#    rm -f "$l_tmp_file"
#    [ $l_rc -ne 0 ] && echo 'Failure' && return $l_rc
#  fi
#
#  # verify global PV
#  l_comp_line=$(kubectl --context=$g_DOCKER_KUBE_FOR_MAC_CONTEXT get pv $g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_NAME 2>/dev/null | grep -e "$g_DOCKER_KUBE_FOR_MAC_GLOBAL_PV_NAME")
#  l_rc=$?
#  [ $l_rc -ne 0 ] && echo 'Failure' && return $l_rc
#  [ x"$l_comp_line" = x ] && echo 'Failure' && return $l_rc
#  echo 'OK'
}

########################################################################
# stop all
function lcl-k8s-x-stop {
  # start the cluster
  "$g_DOCKER_KUBE_FOR_MAC_LOCATION"/hacks/v${g_DOCKER_KUBE_FOR_MAC_K8S_VERSION}/run docker-kube-for-mac.sh stop
}

########################################################################
# optional call support
l_do_run=0
if [ "x$1" != "x" ]; then
  [ "x$1" != "xsource-only" ] && l_do_run=1
fi
if [ $l_do_run -eq 1 ]; then
  l_func="$1"; shift
  [ x"$l_func" != x ] && eval lcl-k8s-x-"$l_func" "$@"
fi

