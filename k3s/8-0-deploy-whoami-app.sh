#!/bin/bash
###---------------------------------------------------------------------------
#Author: cnak47
#Date: 2022-04-13 21:59:12
# LastEditors: cnak47
# LastEditTime: 2022-09-17 11:31:23
# FilePath: /docker_workspace/ak47Docker/k3s/8-0-deploy-whoami-app.sh
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

INFO_MSG "$MODULE" "deploy whoami app"
kubectl apply -f example/whoami/whoami-deploy.yaml
sleep 10
INFO_MSG "$MODULE" "deploy whoami app certificate"
kubectl apply -f example/whoami/whoami-certificate.yaml
sleep 10
ingressclass="ingress-nginx"
if [ $ingressclass = "traefik" ]; then
    INFO_MSG "$MODULE" "deploy whoami app ingressroute"
    kubectl apply -f example/whoami/traefik/whoami-redirect-https.yaml
    kubectl apply -f example/whoami/traefik/whoami-http-ingressroute.yaml
    kubectl apply -f example/whoami/traefik/whoami-https-ingressroute.yaml
else
    INFO_MSG "$MODULE" "deploy whoami app ingress-nginx"
    kubectl apply -f example/whoami/ingress/whoami-tls-ingress.yaml
fi
sleep 5
