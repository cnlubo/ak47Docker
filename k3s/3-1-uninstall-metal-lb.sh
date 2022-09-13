#!/bin/bash
###---------------------------------------------------------------------------
#Author: cnak47
#Date: 2022-04-11 21:33:14
# LastEditors: cnak47
# LastEditTime: 2022-09-13 22:58:45
# FilePath: /docker-workspace/ak47Docker/k3s/3-1-uninstall-metal-lb.sh
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
WARNING_MSG "$MODULE" "Uninstall METALLB v$metallb_version "
WARNING_MSG "$MODULE" "############################################################################"
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    INFO_MSG "$MODULE" "delete Label metallb-speaker=true on ${WORKER}"
    kubectl label nodes "${WORKER}" metallb-speaker-
done
# sleep 5
# kubectl delete -f addons/metal-lb/$metallb_version/metallb.yaml
# sleep 10
# kubectl delete -f addons/metal-lb/$metallb_version/namespace.yaml
kubectl delete -f addons/metal-lb/$metallb_version/metallb-native.yaml
sleep 10
kubectl get pods -A