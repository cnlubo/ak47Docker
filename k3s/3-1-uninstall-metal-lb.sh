#!/bin/bash
###
# @Author: cnak47
# @Date: 2022-04-09 18:30:44
 # @LastEditors: cnak47
 # @LastEditTime: 2022-04-09 18:54:38
 # @FilePath: /docker_workspace/ak47Docker/k3s/3-1-uninstall-metal-lb.sh
# @Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color
metallb_version=0.12.1
echo -e "[${GREEN}Uninstall METALLB${NC}]"
echo "############################################################################"
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    echo -e "[${LB}Info${NC}] delete Label metallb-speaker=true on ${WORKER}"
    kubectl label nodes "${WORKER}" metallb-speaker-
done
sleep 5
kubectl delete -f addons/metal-lb/$metallb_version/metallb.yaml
sleep 10
kubectl delete -f addons/metal-lb/$metallb_version/namespace.yaml
sleep 5
kubectl get pods -A