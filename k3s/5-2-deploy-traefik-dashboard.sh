#!/bin/bash
###---------------------------------------------------------------------------
#Author: cnak47
#Date: 2022-04-19 11:37:23
# LastEditors: cnak47
# LastEditTime: 2022-04-22 11:20:56
# FilePath: /docker_workspace/ak47Docker/k3s/5-2-deploy-traefik-dashboard.sh
#Description:
#
#Copyright (c) 2022 by cnak47, All Rights Reserved.
###---------------------------------------------------------------------------
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
# shellcheck disable=SC1090
source "$ScriptPath"/include/color.sh
# shellcheck disable=SC1091
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf
WARNING_MSG "$MODULE" "############################################################################"
WARNING_MSG "$MODULE" "Deploying traefik v${traefik_version:?} dashboard"
WARNING_MSG "$MODULE" "############################################################################"

INFO_MSG "$MODULE" "create traefik_dashboard_custom.yml"
dns_name='dashboard.traefik.com'
cat >addons/traefik/traefik_dashboard_custom.yml <<EOF
---
# 参考：https://cert-manager.io/docs/usage/certificate/
# api参考：https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.Certificate
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: traefik-tls-cert
  # 需要使用证书的应用所在的命名空间
  namespace: traefik
spec:
  secretName: traefik-tls-secret
  duration: 2160h # 90d
  renewBefore: 360h # 15d
  subject:
    organizations:
      - soft Inc.
  commonName: $dns_name
  isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  dnsNames:
    - $dns_name
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
# ---
# apiVersion: traefik.containo.us/v1alpha1
# kind: TLSStore
# metadata:
#   name: default
#   namespace: traefik
# spec:
#   defaultCertificate:
#     secretName: traefik-tls-secret
---
# https://doc.traefik.io/traefik/middlewares/http/basicauth/#users
# Note: in a kubernetes secret the string (e.g. generated by htpasswd) must be base64-encoded first.
# To create an encoded user:password pair, the following command can be used:
# htpasswd -nb admin admin@12345 | base64
apiVersion: v1
kind: Secret
metadata:
  name: traefik-basic-auth
  namespace: traefik
data:
  users: |2
    YWRtaW46JGFwcjEkQmhuTUNZeUEkRGRkNWFzOW9qdGtUdGttTDlrMTRqLwoK
EOF
cat >addons/traefik/traefik_dashboard_middleware.yml <<EOF
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: traefik-basic-auth
  namespace: traefik
spec:
  basicAuth:
    secret: traefik-basic-auth
---
apiVersion: traefik.containo.us/v1alpha1
kind: Middleware
metadata:
  name: traefik-redirect-https
  namespace: traefik
spec:
  redirectScheme:
    scheme: https
    permanent: true
EOF
cat >addons/traefik/traefik_dashboard_route.yml <<EOF
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard-https-route
  namespace: traefik
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(\`$dns_name\`)
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
      middlewares:
        - name: traefik-basic-auth
          namespace: traefik
  tls: 
    secretName: traefik-tls-secret
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-dashboard-http-route
  namespace: traefik
spec:
  entryPoints:
    - web
  routes:
    - match: Host(\`$dns_name\`)
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
      middlewares:
        - name: traefik-basic-auth
          namespace: traefik
        - name: traefik-redirect-https
          namespace: traefik
EOF
kubectl apply -f addons/traefik/traefik_dashboard_custom.yml
kubectl apply -f addons/traefik/traefik_dashboard_middleware.yml
kubectl apply -f addons/traefik/traefik_dashboard_route.yml