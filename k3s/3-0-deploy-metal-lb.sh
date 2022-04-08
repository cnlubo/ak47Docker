#!/bin/bash
###
# @Author: your name
# @Date: 2021-10-10 11:27:35
 # @LastEditTime: 2022-04-04 09:23:58
 # @LastEditors: cnak47
 # @FilePath: /ak47Docker/k3s/3-deploy-metal-lb.sh
###
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color

echo -e "[${GREEN}Deploying MetalLB LoadBalancer${NC}]"
echo "############################################################################"

metallb_version=0.12.1
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/namespace.yaml
# kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/metallb.yaml
mkdir -p addons/metal-lb/$metallb_version
wget https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/namespace.yaml -O addons/metal-lb/$metallb_version/namespace.yaml
wget https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/metallb.yaml -O addons/metal-lb/$metallb_version/metallb.yaml
# WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
# for WORKER in ${WORKERS}; do
#     echo -e "[${LB}Info${NC}] set Label metallb-speaker on ${WORKER}"
#     kubectl label  --overwrite nodes ${WORKER} metallb-speaker=true
# done
# echo -e "[${GREEN}namespace.yaml${NC}]"
# kubectl apply -f addons/metal-lb/$metallb_version/namespace.yaml
# echo -e "[${GREEN}meltallb.yaml${NC}]"
# kubectl apply -f addons/metal-lb/$metallb_version/metallb.yaml
# echo -e "[${GREEN}Create secret memberList${NC}]"
# kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
# echo -e "[${GREEN}Create secret memberList${NC}]"
# kubectl create -f addons/metal-lb/metal-lb-layer2-config.yaml
