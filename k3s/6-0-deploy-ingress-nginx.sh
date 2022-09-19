#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2021-12-30 23:07:02
# LastEditors: cnak47
# LastEditTime: 2022-09-16 13:22:52
# FilePath: /docker_workspace/ak47Docker/k3s/6-0-deploy-ingress-nginx.sh
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
# shellcheck disable=SC1090
source "$ScriptPath"/include/color.sh
# shellcheck disable=SC1091
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf

if [ ! -d addons/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version ]; then
    mkdir -p addons/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version
    wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v$k8s_ingress_controller_version/deploy/static/provider/cloud/deploy.yaml \
        -O addons/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version/deploy-clound.yaml
fi
INFO_MSG "$MODULE" "Install k8s_ingress_nginx_controller v$k8s_ingress_controller_version"
INFO_MSG "$MODULE" "############################################################################"

WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))

for WORKER in ${WORKERS}; do
    INFO_MSG "$MODULE" "deploy images on ${WORKER}"
    multipass transfer docker-images/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version/ingress-nginx-controller.tar "${WORKER}":
    multipass transfer docker-images/k8s-ingress-nginx/controller-v$k8s_ingress_controller_version/ingress-nginx-kube-webhook-certgen.tar "${WORKER}":
    multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-controller.tar" | grep -w "unpacking"
    multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-kube-webhook-certgen.tar" | grep -w "unpacking"
    multipass exec "${WORKER}" -- /bin/bash -c "sudo crictl images" | grep -w "ingress-nginx"
    INFO_MSG "$MODULE" "set Label isIngress on ${WORKER}"
    kubectl label nodes "${WORKER}" isIngress="true"
done
sleep 5
kubectl create -f addons/k8s-Ingress-nginx/controller-v$k8s_ingress_controller_version/deploy-clound.yaml
sleep 30
INFO_MSG "$MODULE" "check ingress-nginx status"
POD_NAMESPACE=ingress-nginx
POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "$POD_NAME" -n $POD_NAMESPACE -- /nginx-ingress-controller --version
