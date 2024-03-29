#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-29 17:02:24
# LastEditors: cnak47
# LastEditTime: 2022-10-16 10:21:50
# FilePath: /docker_workspace/ak47Docker/k3s/install-docker-vms.sh
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
install_method="manual"
INFO_MSG "$MODULE" "Create mup-docker VM "
cpuCount=2
memCount=4
diskCount=20
# dockerdata="/Users/ak47/workspace/docker-workspace/dockerdata"
# if [ ! -d $dockerdata ]; then
#     mkdir -p $dockerdata
# fi
if [ $install_method = "auto" ]; then
    multipass launch --name mup-docker \
        --cpus ${cpuCount} \
        --mem ${memCount}G \
        --disk ${diskCount}G \
        --cloud-init docker-config.yaml \
        --timeout 600 \
        "$OSversion"
    sleep 10
    # multipass mount $dockerdata mup-docker:"/home/docker" -u 501:0
else
    multipass launch --name mup-docker \
        --cpus ${cpuCount} \
        --mem ${memCount}G \
        --disk ${diskCount}G \
        --cloud-init docker-config-manual.yaml \
        --timeout 600 \
        "$OSversion"
# --bridged \
    # 离线安装包下载地址
    # https://download.docker.com/linux/ubuntu/dists/focal/pool/stable/amd64/
    sleep 10
    # multipass mount $dockerdata mup-docker:"/home/docker" -u 501:0
    multipass transfer soft/docker/20.10.19_3/*.deb mup-docker:"/home/ubuntu"
    multipass transfer soft/docker/daemon.json mup-docker:"/home/ubuntu"
    multipass transfer soft/docker/overwrite.conf mup-docker:"/home/ubuntu"
    multipass exec -d "/home/ubuntu" mup-docker -- bash -c 'sudo dpkg -i containerd.io_1.6.8-1_amd64.deb'
    multipass exec -d "/home/ubuntu" mup-docker -- bash -c 'sudo dpkg -i docker-ce-cli_20.10.19~3-0~ubuntu-focal_amd64.deb'
    multipass exec -d "/home/ubuntu" mup-docker -- bash -c 'sudo dpkg -i docker-ce_20.10.19~3-0~ubuntu-focal_amd64.deb'
    multipass exec -d "/home/ubuntu" mup-docker -- bash -c 'sudo dpkg -i docker-compose-plugin_2.6.0~ubuntu-focal_amd64.deb'
    multipass exec -d "/home/ubuntu" mup-docker -- bash -c 'sudo mv daemon.json /etc/docker/ && sudo chmod +0644 /etc/docker/daemon.json'
    multipass exec -d "/home/ubuntu" mup-docker -- bash -c 'sudo mkdir -p /lib/systemd/system/docker.service.d/ && sudo mv overwrite.conf /lib/systemd/system/docker.service.d/ && sudo chmod +0644 /lib/systemd/system/docker.service.d/overwrite.conf'
    multipass exec -d "/home/ubuntu" mup-docker -- bash -c 'sudo systemctl daemon-reload && sudo systemctl restart docker.service'
fi
sleep 10
INFO_MSG "$MODULE" "Please add below line to .zshrc"
INFO_MSG "$MODULE" 'export DOCKER_HOST="tcp://mup-docker.local:2375'
docker version
