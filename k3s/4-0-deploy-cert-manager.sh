#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-11 15:58:31
# LastEditors: cnak47
# LastEditTime: 2022-09-26 11:26:16
# FilePath: /docker_workspace/ak47Docker/k3s/4-0-deploy-cert-manager.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###----------------------------------------------------------------------------

#set -e
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

if [ ! -d addons/cert-manager/"${certmanager_version:?}" ]; then
    INFO_MSG "$MODULE" "Download cert-manager v$certmanager_version"
    mkdir -p addons/cert-manager/"$certmanager_version"
    wget https://github.com/cert-manager/cert-manager/releases/download/v$certmanager_version/cert-manager.yaml \
        -O addons/cert-manager/$certmanager_version/cert-manager.yaml
fi
INFO_MSG "$MODULE" "Install cert-manager v$certmanager_version"
kubectl apply -f addons/cert-manager/"$certmanager_version"/cert-manager.yaml
sleep 15
# kubectl plugin install
if [ ! -f /usr/local/bin/kubectl-cert_manager ]; then
    INFO_MSG "$MODULE" "Install the kubectl cert-manager plugin"
    OS=$(go env GOOS)
    ARCH=$(go env GOARCH)
    curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/latest/download/kubectl-cert_manager-$OS-$ARCH.tar.gz
    tar xzf kubectl-cert-manager.tar.gz
    sudo mv kubectl-cert_manager /usr/local/bin
fi
sleep 20
kubectl get pods -n cert-manager
# INFO_MSG "$MODULE" "Check cert-manager Status"
# kubectl cert-manager check api
