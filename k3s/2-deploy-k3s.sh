#!/bin/bash
###
 # @Author: your name
 # @Date: 2021-10-10 11:27:35
 # @LastEditTime: 2021-11-13 10:40:28
 # @LastEditors: your name
 # @Description: In User Settings Edit
 # @FilePath: /ak47Docker/k3s/2-deploy-k3s.sh
### 
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color

k8sversion=1.22.4
read -p "Which k8s version do you want to use? check https://github.com/k3s-io/k3s/releases (default:$k8sversion) promt with [ENTER]:" inputK8Sversion
k8sversion="${inputK8Sversion:-$k8sversion}"
echo "$k8sversion" >k8sversion
K3S_VERSION="v$(cat k8sversion)+k3s1"
echo "version" "$K3S_VERSION"
rm k8sversion

echo "############################################################################"
echo "Now deploying k3s on multipass VMs"
echo "############################################################################"

echo -e "[${LB}Info${NC}] deploy k3s on k3s-master"
# disable traefik
#multipass exec k3s-master -- /bin/bash -c "curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_MIRROR=cn INSTALL_K3S_CHANNEL=stable K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=traefik"  sh -" ｜grep -w "Using"
#multipass exec k3s-master -- /bin/bash -c "curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=stable K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=traefik"  sh -" ｜grep -w "Using
#multipass exec k3s-master -- /bin/bash -c "curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_VERSION=${K3S_VERSION} INSTALL_K3S_MIRROR=cn K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=traefik"  sh -" ｜grep -w "Using"
multipass exec k3s-master -- /bin/bash -c "curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_CHANNEL=latest INSTALL_K3S_MIRROR=cn K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=traefik"  sh -" ｜grep -w "Using"
#multipass exec k3s-master -- /bin/bash -c "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--disable=traefik" sh -" | grep "Using"
sleep 10
# Get the IP of the master node
K3S_NODEIP_MASTER="https://$(multipass info k3s-master | grep "IPv4" | awk -F' ' '{print $2}'):6443"
# Get the TOKEN from the master node
K3S_TOKEN="$(multipass exec k3s-master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"
# Deploy k3s on the worker nodes

WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    echo -e "[${LB}Info${NC}] deploy k3s on ${WORKER}"
     multipass exec ${WORKER} -- /bin/bash -c "curl -sfL http://rancher-mirror.cnrancher.com/k3s/k3s-install.sh | INSTALL_K3S_CHANNEL=latest INSTALL_K3S_MIRROR=cn K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -" | grep -w "Using"
    #multipass exec ${WORKER} -- /bin/bash -c "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${K3S_VERSION} K3S_TOKEN=${K3S_TOKEN} K3S_URL=${K3S_NODEIP_MASTER} sh -" | grep -w "Using"
done
sleep 10

echo "############################################################################"
echo exporting KUBECONFIG file from master node
multipass exec k3s-master -- bash -c 'sudo cat /etc/rancher/k3s/k3s.yaml' >k3s.yaml
sed -i'.back' -e 's/127.0.0.1/k3s-master/g' k3s.yaml
export KUBECONFIG=$(pwd)/k3s.yaml && echo -e "[${LB}Info${NC}] setting KUBECONFIG=${KUBECONFIG}"

kubectl config rename-context default k3s-multipass

echo -e "[${LB}Info${NC}] tainting master node: k3s-master"
# 设置污点默认情况下master节点将不会调度运行Pod
kubectl taint node k3s-master node-role.kubernetes.io/master=effect:NoSchedule

sleep 3
# worker 设置node 标签
# 设置Label
# kubectl label node node1 node-role.kubernetes.io/node=
# 移除Label
#kubectl label node node1 node-role.kubernetes.io/node-
for WORKER in ${WORKERS}; do kubectl label node ${WORKER} node-role.kubernetes.io/k3s-node= >/dev/null && echo -e "[${LB}Info${NC}] label ${WORKER} with node"; done

sleep 10

kubectl get nodes

echo "are the nodes ready?"
echo "if you face problems, please open an issue on github"

echo "############################################################################"
echo -e "[${GREEN}Success k3s deployment rolled out${NC}]"
echo "############################################################################"