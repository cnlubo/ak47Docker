#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-09 16:56:18
# LastEditors: cnak47
# LastEditTime: 2022-09-22 11:05:59
# FilePath: /docker_workspace/ak47Docker/k3s/1-1-add-multipass-vms.sh
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

nodeCount=1
read -p "How many worker nodes do you want to add?(default:$nodeCount) promt with [ENTER]:" inputNode
nodeCount="${inputNode:-$nodeCount}"
cpuCount=2
read -p "How many cpus do you want per node?(default:$cpuCount) promt with [ENTER]:" inputCpu
cpuCount="${inputCpu:-$cpuCount}"
memCount=4
read -p "How many gigabyte memory do you want per node?(default:$memCount) promt with [ENTER]:" inputMem
memCount="${inputMem:-$memCount}"
diskCount=10
read -p "How many gigabyte diskspace do you want per node?(default:$diskCount) promt with [ENTER]:" inputDisk
diskCount="${inputDisk:-$diskCount}"
read -p "Which Ubuntu version do you want to use? check multipass find (default:$OSversion) promt with [ENTER]:" inputOSversion
OSversion="${inputOSversion:-$OSversion}"
num_Worker=$(multipass list | grep worker | wc -l)
begin_num=$(($num_Worker + 1))
end_num=$(($num_Worker + $nodeCount))
WORKER=$(eval 'echo k3s-worker{'"$begin_num"'..'"$end_num"'}')
INCREASED_NODES+=$WORKER

for NODE in ${INCREASED_NODES}; do
    INFO_MSG "$MODULE" "############################################################################"
    INFO_MSG "$MODULE" "Deploy multipass vm $NODE"
    multipass launch --name ${NODE} --cpus ${cpuCount} \
        --mem ${memCount}G --disk ${diskCount}G \
        --cloud-init cloud-config.yaml "$OSversion"
done

sleep 10

for NODE in ${INCREASED_NODES}; do
    multipass transfer ~/.ssh/id_rsa.pub ${NODE}:
    multipass exec ${NODE} -- sudo iptables -P FORWARD ACCEPT
    multipass exec ${NODE} -- bash -c 'sudo cat /home/ubuntu/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
done

# create hosts files for multipass vms and cluster access with local environment
./utils/create-hosts.sh

INFO_MSG "$MODULE" "We need to write the host entries on your local machine to /etc/hosts"
WARNING_MSG "$MODULE" "Please provide your sudo password:"
sudo cp hosts.local /etc/hosts

INFO_MSG "$MODULE" "############################################################################"
INFO_MSG "$MODULE" "Writing multipass host entries to /etc/hosts on the VMs:"
MASTER=$(echo $(multipass list | grep master | awk '{print $1}'))
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
NODES+=$MASTER
NODES+=" "
NODES+=$WORKERS

for NODE in ${NODES}; do
    multipass transfer hosts.vm ${NODE}:
    multipass transfer ~/.ssh/id_rsa.pub ${NODE}:
    multipass exec ${NODE} -- sudo iptables -P FORWARD ACCEPT
    multipass exec ${NODE} -- bash -c 'sudo cat /home/ubuntu/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
    multipass exec ${NODE} -- bash -c 'sudo chown ubuntu:ubuntu /etc/hosts'
    multipass exec ${NODE} -- bash -c 'sudo cat /home/ubuntu/hosts.vm >> /etc/hosts'
done

# cleanup tmp hostfiles
rm hosts.vm
