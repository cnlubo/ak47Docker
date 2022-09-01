#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-09 16:56:18
# LastEditors: cnak47
# LastEditTime: 2022-08-15 22:02:47
# FilePath: /docker_workspace/ak47Docker/k3s/2-0-deploy-k3s.sh
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
# shellcheck disable=SC1090
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf

read -p "Which k8s version do you want to use? check https://github.com/k3s-io/k3s/releases (default:$k8sversion) promt with [ENTER]:" inputK8Sversion
k8sversion="${inputK8Sversion:-$k8sversion}"
echo "$k8sversion" >k8sversion
K3S_VERSION="v$(cat k8sversion)+k3s1"
echo "version" "$K3S_VERSION"
k3s_url="https://rancher-mirror.oss-cn-beijing.aliyuncs.com"
rm k8sversion
WARNING_MSG "$MODULE" "############################################################################"
WARNING_MSG "$MODULE" "Now deploying k3s on multipass VMs"
WARNING_MSG "$MODULE" "############################################################################"

INFO_MSG "$MODULE" "deploy k3s on k3s-master"
# disable traefik servicelb
# multipass exec k3s-master -- /bin/bash -c "curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_CHANNEL=latest INSTALL_K3S_MIRROR=cn K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=servicelb,traefik"  sh -" ｜grep -w "Using"
multipass exec k3s-master -- /bin/bash -c "curl -sfL $k3s_url/k3s/k3s-install.sh | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_MIRROR=cn K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=servicelb,traefik"  sh -" ｜grep -w "Using"

sleep 10
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info k3s-master | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec k3s-master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    INFO_MSG "$MODULE" "deploy k3s on ${WORKER}"
    multipass exec "${WORKER}" -- /bin/bash -c "curl -sfL $k3s_url/k3s/k3s-install.sh | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_MIRROR=cn K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -" | grep -w "Using"
done
sleep 10

INFO_MSG "$MODULE" "############################################################################"
INFO_MSG "$MODULE" "exporting KUBECONFIG file from master node"
multipass exec k3s-master -- bash -c 'sudo cat /etc/rancher/k3s/k3s.yaml' >k3s.yaml
sed -i'.back' -e 's/127.0.0.1/k3s-master/g' k3s.yaml
if [ ! -d /Users/ak47/.kube ]; then
    mkdir -p /Users/ak47/.kube
else
    cp ~/.kube/config ~/.kube/config_bak
fi
cp $(pwd)/k3s.yaml ~/.kube/config
chmod go-r ~/.kube/config
kubectl config rename-context default k3s-multipass
INFO_MSG "$MODULE" "tainting master node: k3s-master"
# 设置污点默认情况下master节点将不会调度运行Pod
kubectl taint node k3s-master node-role.kubernetes.io/master=effect:NoSchedule
sleep 3
# worker 设置node 标签
# 设置Label
# kubectl label node node1 node-role.kubernetes.io/node=
# 移除Label
#kubectl label node node1 node-role.kubernetes.io/node-
for WORKER in ${WORKERS}; do
    kubectl label node ${WORKER} node-role.kubernetes.io/k3s-node= >/dev/null
    INFO_MSG "$MODULE" "label ${WORKER} with node"
done
sleep 10
kubectl get nodes
WARNING_MSG "$MODULE" "are the nodes ready?"
WARNING_MSG "$MODULE" "if you face problems, please open an issue on github"
SUCCESS_MSG "$MODULE" "############################################################################"
SUCCESS_MSG "$MODULE" "Success k3s deployment rolled out"
SUCCESS_MSG "$MODULE" "############################################################################"
rm -rf ~/.kube/config_bak
