#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-15 11:15:49
# LastEditors: cnak47
# LastEditTime: 2022-04-18 10:33:58
# FilePath: /docker_workspace/ak47Docker/k3s/4-2-deploy-selfsigned-ca.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###----------------------------------------------------------------------------
set -e
MODULE="$(basename $0)"
# dirname $0，取得当前执行的脚本文件的父目录
# cd `dirname $0`，进入这个目录(切换当前工作目录)
# pwd，显示当前工作目录(cd执行后的)
parentdir=$(dirname "$0")
ScriptPath=$(cd "${parentdir:?}" && pwd)
# BASH_SOURCE[0] 等价于 BASH_SOURCE,取得当前执行的shell文件所在的路径及文件名
scriptdir=$(dirname "${BASH_SOURCE[0]}")
#加载配置内容
# shellcheck disable=SC1091
source "$ScriptPath"/include/color.sh
# shellcheck disable=SC1091
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf

if [ -f addons/cert-manager/selfsigned-ca-custom.yaml ]; then
  rm addons/cert-manager/selfsigned-ca-custom.yaml
fi
INFO_MSG "$MODULE" "create selfsigned-cert.custom.yaml"
cat >addons/cert-manager/selfsigned-ca-custom.yaml <<EOF
---
# 创建自签名发行者
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: selfsigned-cluster-issuer
  namespace: cert-manager
spec:
  selfSigned: {}
---
# 生成CA证书
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-ca
  namespace: cert-manager 
spec:
  # name of the tls secret to store
  # the generated certificate/key pair
  secretName: selfsigned-ca-root-secret 
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  subject:
    organizations:
      - Soft Inc
  commonName: selfsigned-ca
  ### 修改为true,将此证书标记为对证书签名有效。这会将cert sign自动添加到usages列表中。
  isCA: true 
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  issuerRef:
    name: selfsigned-cluster-issuer
    kind: Issuer
    group: cert-manager.io
---
# 创建CA发行者(ClusterIssuer)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
  namespace: cert-manager
spec:
  ca:
    secretName: selfsigned-ca-root-secret
EOF
INFO_MSG "$MODULE" "deploy  selfsigned-ca"

kubectl apply -f addons/cert-manager/selfsigned-ca-custom.yaml
sleep 20
INFO_MSG "$MODULE" "Test that the certificate"
openssl x509 -in <(kubectl -n cert-manager get secret \
  selfsigned-ca-root-secret -o jsonpath='{.data.tls\.crt}' | base64 -d) \
  -text -noout
