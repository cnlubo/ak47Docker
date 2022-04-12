#!/bin/bash
###
# @Author: cnak47
# @Date: 2022-04-12 11:41:14
 # @LastEditors: cnak47
 # @LastEditTime: 2022-04-12 16:12:09
 # @FilePath: /docker_workspace/ak47Docker/k3s/4-1-deploy-selfsigned-ca.sh
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

#cd ./addons/cert-manager || exit
if [ -f ./addons/cert-manager/selfsigned-ca.custom.yaml ]; then
  rm ./addons/cert-manager/selfsigned-ca.custom.yaml
fi
cert_name="test321-com"
org_name="soft"
domain_name="test321.com"
info "create selfsigned-cert.custom.yaml"
cat >./addons/cert-manager/selfsigned-ca.custom.yaml <<EOF
---
# 创建自签名发行者
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-issuer
  namespace: cert-manager
spec:
  selfSigned: {}
---
# 生成CA证书
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: ca-$cert_name
  namespace: cert-manager 
spec:
  # name of the tls secret to store
  # the generated certificate/key pair
  secretName: ca-$cert_name-tls 
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  subject:
    organizations:
      - $org_name
  commonName: ca.$domain_name
  isCA: true ### 修改为true,将此证书标记为对证书签名有效。这会将cert sign自动添加到usages列表中。
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  dnsNames:
    - $domain_name
  issuerRef:
    name: selfsigned-issuer
    kind: Issuer
    group: cert-manager.io
---
# 创建CA发行者(ClusterIssuer)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: ca-$cert_name-tls
EOF
cd ..
info "deploy  selfsigned-ca"
kubectl apply -f ./addons/cert-manager/selfsigned-ca.custom.yaml

info "Test that the certificate"
openssl x509 -in <(kubectl -n cert-manager get secret \
  ca-$cert_name-tls -o jsonpath='{.data.tls\.crt}' | base64 -d) \
  -text -noout
