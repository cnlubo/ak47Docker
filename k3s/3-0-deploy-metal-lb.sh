#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-12 09:40:46
# LastEditors: cnak47
# LastEditTime: 2022-09-29 17:25:10
# FilePath: /docker_workspace/ak47Docker/k3s/3-0-deploy-metal-lb.sh
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

WARNING_MSG "$MODULE" "Deploying MetalLB LoadBalancer v${metallb_version:?}"
WARNING_MSG "$MODULE" " ############################################################################"

if [ ! -d addons/metal-lb/"${metallb_version:?}" ]; then
    mkdir -p addons/metal-lb/"$metallb_version"
    wget https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/config/manifests/metallb-native.yaml \
        -O addons/metal-lb/$metallb_version/metallb-native.yaml
fi

WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    INFO_MSG "$MODULE" "set Label metallb-speaker on ${WORKER}"
    kubectl label --overwrite nodes "${WORKER}" metallb-speaker=true
done
kubectl apply -f addons/metal-lb/"$metallb_version"/metallb-native.yaml
# INFO_MSG "$MODULE" "Create secret memberList"
# kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
# INFO_MSG "$MODULE" "Create secret memberList"
sleep 20
# kubectl create -f addons/metal-lb/$metallb_version/metal-lb-layer2-config.yaml
kubectl get pods -n metallb-system

WARNING_MSG "$MODULE" "are the nodes ready?"
WARNING_MSG "$MODULE" "if you face problems, please open an issue on github"

SUCCESS_MSG "$MODULE" "############################################################################"
SUCCESS_MSG "$MODULE" "Success k3s deployment rolled out"
SUCCESS_MSG "$MODULE" "############################################################################"
