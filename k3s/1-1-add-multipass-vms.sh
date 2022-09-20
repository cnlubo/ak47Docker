#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-09 16:56:18
# LastEditors: cnak47
# LastEditTime: 2022-09-20 13:36:52
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
NODES+=$WORKER

# # Create containers
for NODE in ${NODES}; do
    INFO_MSG "$MODULE" "############################################################################"
    INFO_MSG "$MODULE" "Deploy multipass vm $NODE"
    multipass launch --name ${NODE} --cpus ${cpuCount} \
        --mem ${memCount}G --disk ${diskCount}G --bridged \
        --cloud-init cloud-config.yaml "$OSversion"
done

sleep 10

for NODE in ${NODES}; do
    multipass transfer ~/.ssh/id_rsa.pub ${NODE}:
    multipass exec ${NODE} -- sudo iptables -P FORWARD ACCEPT
    multipass exec ${NODE} -- bash -c 'sudo cat /home/ubuntu/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
done
