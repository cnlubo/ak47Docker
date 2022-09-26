#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-01-16 09:33:36
# LastEditors: cnak47
# LastEditTime: 2022-09-26 11:43:41
# FilePath: /docker_workspace/ak47Docker/k3s/6-1-uninstall-ingress-nginx.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###----------------------------------------------------------------------------
set -e
MODULE=$(basename "$0")
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

INFO_MSG "$MODULE" "Uninstall Nginx Ingress Controller v${k8s_ingress_controller_version:?}"
INFO_MSG "$MODULE" "############################################################################"
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    INFO_MSG "$MODULE" "delete Label isIngress on ${WORKER}"
    kubectl label nodes "${WORKER}" isIngress-
done
sleep 5
kubectl delete -f addons/k8s-ingress-nginx/controller-v"$k8s_ingress_controller_version"/deploy-clound.yaml
sleep 10
kubectl get pods -A
