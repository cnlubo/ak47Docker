#!/bin/bash
###
# @Author: your name
# @Date: 2021-10-10 11:27:35
# @LastEditTime: 2021-12-30 15:10:30
# @LastEditors: Please set LastEditors
# @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
# @FilePath: /ak47Docker/k3s/3-install-metal-lb.sh
###
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color

echo -e "[${GREEN}Deploying MetalLB LoadBalancer${NC}]"
echo "############################################################################"

metallb_version=0.11.0
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/namespace.yaml
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/metallb.yaml
# kubectl label nodes k3s-worker1 k3s-worker2 metallb-speaker=true
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    echo -e "[${LB}Info${NC}] set Label metallb-speaker on ${WORKER}"
    kubectl label nodes ${WORKER} metallb-speaker=true
done
echo -e "[${GREEN}namespace.yaml${NC}]"
kubectl apply -f addons/metal-lb/namespace.yaml
echo -e "[${GREEN}meltallb.yaml${NC}]"
kubectl apply -f addons/metal-lb/metallb.yaml
echo -e "[${GREEN}Create secret memberList${NC}]"
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
echo -e "[${GREEN}Create secret memberList${NC}]"
kubectl create -f addons/metal-lb/metal-lb-layer2-config.yaml
