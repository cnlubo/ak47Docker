#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-22 11:43:26
# LastEditors: cnak47
# LastEditTime: 2022-04-22 14:54:49
# FilePath: /docker_workspace/ak47Docker/k3s/5-1-deploy-traefik-manual.sh
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

addons_dir=addons/traefik/$traefik_version

if [ ! -d "$addons_dir"/crd ]; then
    INFO_MSG "$MODULE" "Download traefik CRD files"
    mkdir -p $addons_dir/crd
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressroutes.yaml \
        -o $addons_dir/crd/01-traefik.containo.us_ingressroutes.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressroutetcps.yaml \
        -o $addons_dir/crd/02-traefik.containo.us_ingressroutetcps.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressrouteudps.yaml \
        -o $addons_dir/crd/03-traefik.containo.us_ingressrouteudps.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewares.yaml \
        -o $addons_dir/crd/04-traefik.containo.us_middlewares.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewaretcps.yaml \
        -o $addons_dir/crd/05-traefik.containo.us_middlewaretcps.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_serverstransports.yaml \
        -o $addons_dir/crd/06-traefik.containo.us_serverstransports.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_tlsoptions.yaml \
        -o $addons_dir/crd/07-traefik.containo.us_tlsoptions.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_tlsstores.yaml \
        -o $addons_dir/crd/08-traefik.containo.us_tlsstores.yaml
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_traefikservices.yaml \
        -o $addons_dir/crd/09-traefik.containo.us_traefikservices.yaml
    echo -e "[${GREEN}Download traefik RBAC file${NC}]"
    curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml \
        -o addons/traefik/$traefik_version/001-01-rabc.yaml
fi
