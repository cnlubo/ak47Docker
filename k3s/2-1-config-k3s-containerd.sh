#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-09-23 15:39:48
# LastEditors: cnak47
# LastEditTime: 2022-09-23 17:31:45
# FilePath: /docker_workspace/ak47Docker/k3s/2-3-config-k3s-containerd.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###----------------------------------------------------------------------------
set -e
MODULE=$(basename "$0")
# dirname $0，取得当前执行的脚本文件的父目录
# cd `dirname $0`，进入这个目录(切换当前工作目录)
# pwd，显示当前工作目录(cd执行后的)
parentdir=$(dirname "$0")
ScriptPath=$(cd "${parentdir:?}" && pwd)
# BASH_SOURCE[0] 等价于 BASH_SOURCE,取得当前执行的shell文件所在的路径及文件名
scriptdir=$(dirname "${BASH_SOURCE[0]}")
#加载配置内容
# shellcheck disable=SC1091
source "$ScriptPath"/include/color.sh
# shellcheck disable=SC1091
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf
INFO_MSG "$MODULE" "############################################################################"
INFO_MSG "$MODULE" "Configure containerd on k3s-master "
multipass transfer containerd/config.tmpl "k3s-master":
multipass exec "k3s-master" -- bash -c 'sudo cp /var/lib/rancher/k3s/agent/etc/containerd/config.toml /home/ubuntu/config.toml.tmpl'
multipass exec "k3s-master" -- bash -c 'sudo chown ubuntu:ubuntu /home/ubuntu/config.toml.tmpl'
multipass exec "k3s-master" -- bash -c 'sudo cat /home/ubuntu/config.tmpl >> /home/ubuntu/config.toml.tmpl'
multipass exec "k3s-master" -- bash -c 'sudo cp /home/ubuntu/config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl'
multipass exec "k3s-master" -- bash -c "sudo systemctl restart k3s"
sleep 5

WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))

for WORKER in ${WORKERS}; do
    INFO_MSG "$MODULE" "Configure containerd on ${WORKER}"
    multipass transfer containerd/config.tmpl "${WORKER}":
    multipass exec "${WORKER}" -- bash -c 'sudo cp /var/lib/rancher/k3s/agent/etc/containerd/config.toml /home/ubuntu/config.toml.tmpl'
    multipass exec "${WORKER}" -- bash -c 'sudo chown ubuntu:ubuntu /home/ubuntu/config.toml.tmpl'
    multipass exec "${WORKER}" -- bash -c 'sudo cat /home/ubuntu/config.tmpl >> /home/ubuntu/config.toml.tmpl'
    multipass exec "${WORKER}" -- bash -c 'sudo cp /home/ubuntu/config.toml.tmpl /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl'
    multipass exec "${WORKER}" -- bash -c "sudo systemctl restart k3s-agent"
    sleep 5
done
