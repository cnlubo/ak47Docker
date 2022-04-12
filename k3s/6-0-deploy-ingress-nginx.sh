#!/bin/bash
###
# @Author: cnak47
# @Date: 2021-12-30 23:07:02
 # @LastEditors: cnak47
 # @LastEditTime: 2022-04-12 17:47:39
 # @FilePath: /docker_workspace/ak47Docker/k3s/6-0-deploy-ingress-nginx.sh
# @Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###

set -e

# Color Palette
RESET='\033[0m'
BOLD='\033[1m'
## Foreground
BLACK='\033[38;5;0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
BLUE='\033[38;5;4m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'
WHITE='\033[38;5;7m'
## Background
ON_BLACK='\033[48;5;0m'
ON_RED='\033[48;5;1m'
ON_GREEN='\033[48;5;2m'
ON_YELLOW='\033[48;5;3m'
ON_BLUE='\033[48;5;4m'
ON_MAGENTA='\033[48;5;5m'
ON_CYAN='\033[48;5;6m'
ON_WHITE='\033[48;5;7m'

MODULE="$(basename $0)"

stderr_print() {
    printf "%b\\n" "${*}" >&2
}
log() {
    stderr_print "[${BLUE}${MODULE} ${MAGENTA}$(date "+%Y-%m-%d %H:%M:%S ")${RESET}] ${*}"
}
info() {

    log "${GREEN}INFO ${RESET} ==> ${*}"
}
warn() {

    log "${YELLOW}WARN ${RESET} ==> ${*}"
}
error() {
    log "${RED}ERROR${RESET} ==> ${*}"
}
k8s_ingress_controller_version='1.1.3'
if [ ! -d addons/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version ]; then
    mkdir -p addons/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version
    wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v$k8s_ingress_controller_version/deploy/static/provider/cloud/deploy.yaml \
        -O addons/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version/deploy-clound.yaml
fi
info "Install k8s_ingress_nginx_controller v$k8s_ingress_controller_version"
# echo -e "[${GREEN}Deploying Nginx Ingress Controller${NC}]"
# echo "############################################################################"
info "############################################################################"
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    #     echo -e "[${LB}Info${NC}] deploy images on ${WORKER}"
    #     multipass transfer addons/ingress-nginx/1.0.3/ingress-nginx-controller.tar "${WORKER}":
    #     multipass transfer addons/ingress-nginx/1.0.3/ingress-nginx-kube-webhook-certgen.tar "${WORKER}":
    #     multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-controller.tar" | grep -w "unpacking"
    #     multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-kube-webhook-certgen.tar" | grep -w "unpacking"
    #     multipass exec "${WORKER}" -- /bin/bash -c "sudo crictl images" | grep -w "ingress-nginx"
    # echo -e "[${LB}Info${NC}] set Label isIngress on ${WORKER}"
    info "set Label isIngress on ${WORKER}"
    kubectl label nodes ${WORKER} isIngress="true"

done
sleep 5
kubectl create -f addons/k8s-Ingress-nginx/controller-v$k8s_ingress_controller_version/deploy-clound.yaml
sleep 30
POD_NAMESPACE=ingress-nginx
POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "$POD_NAME" -n $POD_NAMESPACE -- /nginx-ingress-controller --version
