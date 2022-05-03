#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-29 17:02:24
# LastEditors: cnak47
# LastEditTime: 2022-05-01 08:30:32
# FilePath: /docker_workspace/ak47Docker/k3s/7-deploy-rancher-on-k3s.sh
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

# ./utils/dependency-chec-helm.sh

WARNING_MSG "$MODULE" "############################################################################"
WARNING_MSG "$MODULE" "Now deploying Rancher latest in namespace cattle-system"
WARNING_MSG "$MODULE" "############################################################################"

kubectl create namespace cattle-system
INFO_MSG "$MODULE" "Create tls-ca secret"
if [ ! -f cacerts.pem ]; then
    ./include/export-ca-cert.sh
fi
kubectl -n cattle-system create secret generic tls-ca \
    --from-file=cacerts.pem=./cacerts.pem
INFO_MSG "$MODULE" "Create rancher certificate"
kubectl apply -f addons/rancher/rancher-certificate.yaml
INFO_MSG "$MODULE" "add helm repo"
helm repo add rancher-stable http://rancher-mirror.oss-cn-beijing.aliyuncs.com/server-charts/stable
helm repo update
helm repo list
INFO_MSG "$MODULE" "helm install rancher "
helm install rancher rancher-stable/rancher \
    --namespace cattle-system \
    --values=./addons/rancher/rancher-values-custom.yaml \
    --version "$rancher_version"
# helm install rancher rancher-latest/rancher \
#     --namespace cattle-system \
#     --set hostname=rancher.my.org \
#     --version $rancher_version

# Wait a few seconds for deployment to be created
sleep 20

kubectl -n cattle-system rollout status deploy/rancher

# echo "Exposing Rancher deployment with loadbalancer service"
# kubectl expose deployment rancher --type=LoadBalancer --name=rancher -n cattle-system
# kubectl get svc rancher -n cattle-system

# echo "############################################################################"
# echo -e "[${GREEN}Success rancher deployment rolled out${NC}]"
# echo "############################################################################"
