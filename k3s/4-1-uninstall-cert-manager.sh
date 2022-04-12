#!/bin/bash
###
 # @Author: cnak47
 # @Date: 2022-04-12 11:29:53
 # @LastEditors: cnak47
 # @LastEditTime: 2022-04-12 11:33:42
 # @FilePath: /docker_workspace/ak47Docker/k3s/4-1-uninstall-cert-manager.sh
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
info "Uninstall cert-manager $certmanager_version"
kubectl delete -f addons/cert-manager/$certmanager_version/cert-manager.yaml
sleep 15
kubectl delete namespace cert-manager
info "Uninstall cert-manager $certmanager_version Successful"
