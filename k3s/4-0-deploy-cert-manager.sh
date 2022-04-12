#!/bin/bash
###
# @Author: cnak47
# @Date: 2022-04-11 15:58:31
 # @LastEditors: cnak47
 # @LastEditTime: 2022-04-12 11:38:27
 # @FilePath: /docker_workspace/ak47Docker/k3s/4-0-deploy-cert-manager.sh
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

certmanager_version="1.8.0"
if [ ! -d addons/cert-manager/$certmanager_version ]; then
    mkdir -p addons/cert-manager/$certmanager_version
    wget https://github.com/cert-manager/cert-manager/releases/download/v$certmanager_version/cert-manager.yaml \
        -O addons/cert-manager/$certmanager_version/cert-manager.yaml
fi
info "Install cert-manager $certmanager_version"
kubectl apply -f addons/cert-manager/$certmanager_version/cert-manager.yaml
sleep 15
# kubectl plugin install
if [ ! -f /usr/local/bin/kubectl-cert_manager ]; then
    info "Install the kubectl cert-manager plugin"
    OS=$(go env GOOS)
    ARCH=$(go env GOARCH)
    curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/latest/download/kubectl-cert_manager-$OS-$ARCH.tar.gz
    tar xzf kubectl-cert-manager.tar.gz
    sudo mv kubectl-cert_manager /usr/local/bin
fi
sleep 15
info "Check cert-manager Install"
kubectl cert-manager check api
