#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-09-19 10:00:53
# LastEditors: cnak47
# LastEditTime: 2022-09-27 11:39:41
# FilePath: /docker_workspace/ak47Docker/k3s/9-0-deploy-istio.sh
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
# istio_version=$(get_latest_release istio/istio)
INFO_MSG "$MODULE" "Install istioctl v${istio_version:?}"
if [ ! -d soft/istio/"istio-$istio_version" ]; then
    cd soft/istio
    curl -L https://istio.io/downloadIstio | ISTIO_VERSION=$istio_version TARGET_ARCH=x86_64 sh -
    cd "$scriptdir"
fi
if [ ! -d /usr/local/Cellar/istio ]; then
    mkdir -p /usr/local/Cellar/istio
fi
cp soft/istio/istio-"${istio_version:?}"/bin/istioctl /usr/local/Cellar/istio/
INFO_MSG "$MODULE" "Generate istio install profile"

istioctl manifest generate --set profile=demo \
    --set .values.global.imagePullPolicy=IfNotPresent >istio-demo.yaml
INFO_MSG "$MODULE" "Install istio v${istio_version:?}"
kubectl create namespace istio-system
kubectl apply -f istio-demo.yaml
sleep 20
istioctl version
# kubectl get svc -n istio-system
# rm istio-demo.yaml
