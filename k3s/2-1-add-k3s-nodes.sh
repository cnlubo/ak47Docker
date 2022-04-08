#!/bin/bash
###
# @Author: your name
# @Date: 2022-01-04 09:57:53
# @LastEditTime: 2022-01-06 18:07:03
# @LastEditors: your name
# @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
# @FilePath: /ak47Docker/k3s/2-deploy-k3s.sh
###
###
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color

k8sversion=1.22.5
read -p "Which k8s version do you want to use? check https://github.com/k3s-io/k3s/releases (default:$k8sversion) promt with [ENTER]:" inputK8Sversion
k8sversion="${inputK8Sversion:-$k8sversion}"
echo "$k8sversion" >k8sversion
K3S_VERSION="v$(cat k8sversion)+k3s1"
echo "version" "$K3S_VERSION"
rm k8sversion
read -p "Which multipass node do you want to join k3s cluster promt with [ENTER]:" inputK3sNode
K3sNode="${inputK3sNode}"
echo "############################################################################"
echo "Now deploying k3s on $K3sNode"
echo "############################################################################"
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info k3s-master | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec k3s-master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes
multipass exec "${K3sNode}" -- /bin/bash -c "curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_MIRROR=cn K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -" | grep -w "Using"
#multipass exec "${K3sNode}" -- /bin/bash -c "curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_CHANNEL=latest INSTALL_K3S_MIRROR=cn K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -" | grep -w "Using"
sleep 10
# worker 设置node 标签
# 设置Label
# kubectl label node node1 node-role.kubernetes.io/node=
# 移除Label
#kubectl label node node1 node-role.kubernetes.io/node-
kubectl label node "${K3sNode}" node-role.kubernetes.io/k3s-node= >/dev/null 
echo -e "[${LB}Info${NC}] label ${K3sNode} with node"
sleep 10
kubectl get nodes
echo "############################################################################"
echo -e "[${GREEN}Success k3s deployment rolled out${NC}]"
echo "############################################################################"
