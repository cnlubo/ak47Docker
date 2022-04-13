#!/bin/bash
###
 # @Author: cnak47
 # @Date: 2022-04-13 11:43:45
 # @LastEditors: cnak47
 # @LastEditTime: 2022-04-13 11:58:21
 # @FilePath: /docker_workspace/ak47Docker/k3s/6-1-deploy-whoami-tls.sh
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

info "deploy whoami app"
kubectl apply -f example/whoami/whoami-deploy.yaml
sleep 10
info "deploy whoami app certificate"
kubectl apply -f example/whoami/whoami-certificate.yaml
sleep 10
info "deploy whoami ingress"
kubectl apply -f example/whoami/whoami-ingress-https.yaml
sleep 5
