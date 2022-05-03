#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-29 17:02:24
# LastEditors: cnak47
# LastEditTime: 2022-04-30 21:54:06
# FilePath: /docker_workspace/ak47Docker/k3s/cleanup.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###----------------------------------------------------------------------------
set -e
MODULE="$(basename $0)"
# dirname $0，取得当前执行的脚本文件的父目录
# cd `dirname $0`，进入这个目录(切换当前工作目录)
# pwd，显示当前工作目录(cd执行后的)
parentdir=$(dirname "$0")
ScriptPath=$(cd "${parentdir:?}" && pwd)
# BASH_SOURCE[0] 等价于 BASH_SOURCE,取得当前执行的shell文件所在的路径及文件名
scriptdir=$(dirname "${BASH_SOURCE[0]}")
#加载配置内容
# shellcheck disable=SC1090
source "$ScriptPath"/include/color.sh
# shellcheck disable=SC1091
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf

MASTER=$(echo $(multipass list | grep master | awk '{print $1}'))
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
NODES+=$MASTER
NODES+=" "
NODES+=$WORKERS

cleanupAnsw="y"
read -p "Do you want to clean your /etc/hosts from multipass entries (y/n)?(default:y) promt with [ENTER]:" input
cleanupAnsw="${input:-$cleanupAnsw}"

if [ $cleanupAnsw == 'y' ]; then
  # seach for existing multipass config
  exists=$(grep -n "####### multipass hosts start ##########" hosts.local | awk -F: '{print $1}' | head -1)
  # check if var is empty
  if test -z "$exists"; then
    exists=0
  else
    WARNING_MSG "$MODULE" "We need to remove the host entries on your local machine from /etc/hosts"
    WARNING_MSG "$MODULE" "Before modifying /etc/hosts will be backuped at hosts.cleanup.backup"
    WARNING_MSG "$MODULE" "Please provide your sudo password:"

    # backup before cleanup
    cp /etc/hosts hosts.cleanup.backup
    cp hosts.cleanup.backup hosts.local
  fi

  # cut existing config
  if (("$exists" > "0")); then
    start=$(grep -n "####### multipass hosts start ##########" hosts.local | awk -F: '{print $1}' | head -1)
    ((start = start - 1))
    end=$(grep -n "####### multipass hosts end   ##########" hosts.local | awk -F: '{print $1}' | head -1)
    sed -i '' ${start},${end}d hosts.local
  fi

  # copy cleaned hosts to /etc/hosts
  sudo cp hosts.local /etc/hosts
fi

# Stop then delete nodes
for NODE in ${NODES}; do multipass stop ${NODE} && multipass delete ${NODE}; done
# Free discspace
multipass purge


WARNING_MSG "$MODULE" "[FINISHED]"
WARNING_MSG "$MODULE" "############################################################################"
WARNING_MSG "$MODULE" "[Please cleanup the host entries in your /etc/hosts manually"

rm hosts.local hosts.backup k3s.yaml.back k3s.yaml get_helm.sh 2>/dev/null
