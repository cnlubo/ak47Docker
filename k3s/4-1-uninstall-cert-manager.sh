#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-12 11:29:53
# LastEditors: cnak47
# LastEditTime: 2022-09-26 11:28:44
# FilePath: /docker_workspace/ak47Docker/k3s/4-1-uninstall-cert-manager.sh
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
INFO_MSG "$MODULE" "Uninstall cert-manager ${certmanager_version:?}"
kubectl delete -f addons/cert-manager/"$certmanager_version"/cert-manager.yaml
sleep 15
SUCCESS_MSG "$MODULE" "Uninstall cert-manager $certmanager_version Successful"
