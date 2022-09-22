#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-09 16:56:18
# LastEditors: cnak47
# LastEditTime: 2022-09-22 17:43:08
# FilePath: /docker_workspace/ak47Docker/k3s/1-0-deploy-multipass-vms.sh
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
# shellcheck disable=SC1090
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf

nodeCount=3
read -r -p "How many worker nodes do you want?(default:$nodeCount) promt with [ENTER]:" inputNode
nodeCount="${inputNode:-$nodeCount}"
cpuCount=2
read -r -p "How many cpus do you want per node?(default:$cpuCount) promt with [ENTER]:" inputCpu
cpuCount="${inputCpu:-$cpuCount}"
memCount=4
read -r -p "How many gigabyte memory do you want per node?(default:$memCount) promt with [ENTER]:" inputMem
memCount="${inputMem:-$memCount}"
diskCount=10
read -r -p "How many gigabyte diskspace do you want per node?(default:$diskCount) promt with [ENTER]:" inputDisk
diskCount="${inputDisk:-$diskCount}"
read -r -p "Which Ubuntu version do you want to use? check multipass find (default:$OSversion) promt with [ENTER]:" inputOSversion
OSversion="${inputOSversion:-$OSversion}"

# MASTER=$(echo "k3s-master ")
MASTER="k3s-master "
WORKER=$(eval 'echo k3s-worker{1..'"$nodeCount"'}')

NODES+=$MASTER
NODES+=$WORKER

for NODE in ${NODES}; do
    multipass launch --name "${NODE}" --cpus "${cpuCount}" \
        --mem "${memCount}"G --disk "${diskCount}"G \
        --cloud-init cloud-config.yaml "$OSversion"
done
# --bridged
# Wait a few seconds for nodes to be up
sleep 5
# create hosts files for multipass vms and cluster access with local environment
./utils/create-hosts.sh
INFO_MSG "$MODULE" "We need to write the host entries on your local machine to /etc/hosts"
WARNING_MSG "$MODULE" "Please provide your sudo password:"
sudo cp hosts.local /etc/hosts

INFO_MSG "$MODULE" "############################################################################"
INFO_MSG "$MODULE" "Writing multipass host entries to /etc/hosts on the VMs:"

for NODE in ${NODES}; do
    multipass transfer hosts.vm "${NODE}":
    multipass transfer ~/.ssh/id_rsa.pub "${NODE}":
    multipass exec "${NODE}" -- sudo iptables -P FORWARD ACCEPT
    multipass exec "${NODE}" -- bash -c 'sudo cat /home/ubuntu/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
    multipass exec "${NODE}" -- bash -c 'sudo chown ubuntu:ubuntu /etc/hosts'
    multipass exec "${NODE}" -- bash -c 'sudo cat /home/ubuntu/hosts.vm >> /etc/hosts'
done

# cleanup tmp hostfiles
rm hosts.vm
