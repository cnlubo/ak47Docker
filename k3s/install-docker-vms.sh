#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-29 17:02:24
# LastEditors: cnak47
# LastEditTime: 2022-09-06 17:39:48
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
install_method="manual"
INFO_MSG "$MODULE" "Create mup-docker VM "
cpuCount=2
memCount=4
diskCount=5
dockerdata="/Users/ak47/workerspace/docker_workspace/dockerdata"
if [ ! -d $dockerdata ]; then
    mkdir -p $dockerdata
fi
if [ $install_method = "auto" ]; then
    multipass launch --name mup-docker \
        --cpus ${cpuCount} \
        --mem ${memCount}G \
        --disk ${diskCount}G \
        --cloud-init docker-config.yaml \
        --timeout 1200 \
        "$OSversion"
else
    multipass launch --name mup-docker \
        --cpus ${cpuCount} \
        --mem ${memCount}G \
        --disk ${diskCount}G \
        --mount $dockerdata:"/home/docker" \
        --cloud-init docker-config-manual.yaml \
        --timeout 1200 \
        "$OSversion"
fi
sleep 10
multipass ls
INFO_MSG "$MODULE" "Please add below line to .zshrc"
INFO_MSG "$MODULE" 'export DOCKER_HOST="tcp://mup-docker.local:2375'
