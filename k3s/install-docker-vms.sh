#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-29 17:02:24
# LastEditors: cnak47
# LastEditTime: 2022-05-01 08:49:56
# FilePath: /docker_workspace/ak47Docker/k3s/install-docker-vms.sh
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

INFO_MSG "$MODULE" "Create mup-docker VM "
cpuCount=2
memCount=4
diskCount=10
multipass launch --name mup-docker \
    --cpus ${cpuCount} \
    --mem ${memCount}G \
    --disk ${diskCount}G \
    --cloud-init docker-config.yaml \
    "$OSversion"
sleep 10
multipass ls
INFO_MSG "$MODULE" "Please add below line to .zshrc"
INFO_MSG "$MODULE" 'export DOCKER_HOST="tcp://mup-docker.local:2375'
