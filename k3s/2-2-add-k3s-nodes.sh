#!/bin/bash
###---------------------------------------------------------------------------
#Author: cnak47
#Date: 2022-01-17 13:57:59
# LastEditors: cnak47
# LastEditTime: 2022-09-26 11:16:09
# FilePath: /docker_workspace/ak47Docker/k3s/2-2-add-k3s-nodes.sh
#Description:
#
#Copyright (c) 2022 by cnak47, All Rights Reserved.
###---------------------------------------------------------------------------
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

K3S_VERSION="v${k8sversion:?}+k3s1"
read -r -p "Which multipass node do you want to join k3s cluster promt with [ENTER]:" inputK3sNode
K3sNode="${inputK3sNode}"
WARNING_MSG "$MODULE" "############################################################################"
WARNING_MSG "$MODULE" "Now deploying k3s $K3S_VERSION on $K3sNode"
WARNING_MSG "$MODULE" "############################################################################"
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info k3s-master | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec k3s-master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes
k3s_url="https://rancher-mirror.oss-cn-beijing.aliyuncs.com"
multipass exec "${K3sNode}" -- /bin/bash -c "curl -sfL $k3s_url/k3s/k3s-install.sh | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_MIRROR=cn K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -" | grep -w "Using"
sleep 10
# worker 设置node 标签
# 设置Label
# kubectl label node node1 node-role.kubernetes.io/node=
# 移除Label
#kubectl label node node1 node-role.kubernetes.io/node-
kubectl label node "${K3sNode}" node-role.kubernetes.io/k3s-node= >/dev/null
INFO_MSG "$MODULE" "label ${K3sNode} with node"
sleep 20
kubectl get nodes
SUCCESS_MSG "$MODULE" "############################################################################"
SUCCESS_MSG "$MODULE" "Success k3s deployment rolled out"
SUCCESS_MSG "$MODULE" "############################################################################"
