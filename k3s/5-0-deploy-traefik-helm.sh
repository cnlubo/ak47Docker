#!/bin/bash
###---------------------------------------------------------------------------
#Author: cnak47
#Date: 2022-04-19 09:48:38
#LastEditors: cnak47
#LastEditTime: 2022-04-23 10:23:18
#FilePath: /ak47Docker/k3s/5-0-deploy-traefik-helm.sh
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

if [ ! -f "/usr/local/bin/helm" ]; then
    EXIT_MSG ""$MODULE"" "Please first install Helm !!!"
fi
if [ -f addons/traefik/traefik_values_custom.yml ]; then
    rm addons/traefik/traefik_values_custom.yml
fi
INFO_MSG "$MODULE" "create traefik_values_custom.yml"
cat >addons/traefik/traefik_values_custom.yml <<EOF
image:
  name: traefik
  # defaults to appVersion
  tag: "${traefik_version:?}"
  pullPolicy: IfNotPresent
deployment:
  enabled: true
  # Can be either Deployment or DaemonSet
  kind: Deployment
  # Number of pods of the deployment (only applies when kind == Deployment)
  replicas: 2
additionalArguments: []
ingressRoute:
  dashboard:
    enabled: false
ports:
  traefik:
    port: 9000
    healthchecksPort: 9000
    expose: false
    # The exposed port for this service
    exposedPort: 9000
    protocol: TCP
  web:
    port: 8000
    expose: true
    exposedPort: 80
    protocol: TCP
    # Use nodeport if set. This is useful if you have configured Traefik in a
    # LoadBalancer
    # nodePort: 32080
    # Port Redirections
    # Added in 2.2, you can make permanent redirects via entrypoints.
    # https://docs.traefik.io/routing/entrypoints/#redirection
    redirectTo: websecure
  websecure:
    port: 8443
    # hostPort: 8443
    expose: true
    exposedPort: 443
    protocol: TCP
    # nodePort: 32443
    # Enable HTTP/3.
    # Requires enabling experimental http3 feature and tls.
    # Note that you cannot have a UDP entrypoint with the same port.
    # http3: true
    # Set TLS at the entrypoint
    # https://doc.traefik.io/traefik/routing/entrypoints/#tls
    tls:
      enabled: true
  metrics:
    port: 9100
    # hostPort: 9100
    # Defines whether the port is exposed if service.type is LoadBalancer or
    # NodePort.
    expose: true
    # The exposed port for this service
    exposedPort: 9100
    # The port protocol (TCP/UDP)
    protocol: TCP
tlsOptions:
  default:
    minVersion: VersionTLS13
service:
  enabled: true
  type: LoadBalancer
  spec: 
    loadBalancerIP: "192.168.64.120"
logs:
  # Traefik logs concern everything that happens to Traefik itself (startup, configuration, events, shutdown, and so on).
  general:
    # By default, the logs use a text format (common), but you can
    # also ask for the json format in the format option
    # format: json
    # By default, the level is set to ERROR. Alternative logging levels are DEBUG, PANIC, FATAL, ERROR, WARN, and INFO.
    level: DEBUG
  access:
    # To enable access logs
    enabled: false
EOF
WARNING_MSG "$MODULE" " ############################################################################"
WARNING_MSG "$MODULE" "Deploying traefik v${traefik_version:?}"
WARNING_MSG "$MODULE" " ############################################################################"
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
kubectl create namespace traefik
helm install traefik traefik/traefik --namespace=traefik --values=addons/traefik/traefik_values_custom.yml
helm ls -n traefik
