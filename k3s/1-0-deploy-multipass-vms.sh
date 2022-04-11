#!/bin/bash
###
# @Author: cnak47
# @Date: 2022-01-17 13:57:59
# @LastEditors: cnak47
# @LastEditTime: 2022-04-09 17:12:09
# @FilePath: /docker_workspace/ak47Docker/k3s/1-0-deploy-multipass-vms.sh
# @Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###
# check if required applications and files are available
#./utils/dependency-check.sh
set -e
nodeCount=2
read -p "How many worker nodes do you want?(default:$nodeCount) promt with [ENTER]:" inputNode
nodeCount="${inputNode:-$nodeCount}"
cpuCount=4
read -p "How many cpus do you want per node?(default:$cpuCount) promt with [ENTER]:" inputCpu
cpuCount="${inputCpu:-$cpuCount}"
memCount=2
read -p "How many gigabyte memory do you want per node?(default:$memCount) promt with [ENTER]:" inputMem
memCount="${inputMem:-$memCount}"
diskCount=5
read -p "How many gigabyte diskspace do you want per node?(default:$diskCount) promt with [ENTER]:" inputDisk
diskCount="${inputDisk:-$diskCount}"
OSversion=20.04
read -p "Which Ubuntu version do you want to use? check multipass find (default:$OSversion) promt with [ENTER]:" inputOSversion
OSversion="${inputOSversion:-$OSversion}"

MASTER=$(echo "k3s-master ")
WORKER=$(eval 'echo k3s-worker{1..'"$nodeCount"'}')

NODES+=$MASTER
NODES+=$WORKER

# Create containers
for NODE in ${NODES}; do
    multipass launch --name ${NODE} --cpus ${cpuCount} \
        --mem ${memCount}G --disk ${diskCount}G \
        --cloud-init cloud-config.yaml "$OSversion"
done

# Wait a few seconds for nodes to be up
sleep 5

# # create hosts files for multipass vms and cluster access with local environment
./utils/create-hosts.sh

echo "We need to write the host entries on your local machine to /etc/hosts"
echo "Please provide your sudo password:"
sudo cp hosts.local /etc/hosts

echo "############################################################################"
echo "Writing multipass host entries to /etc/hosts on the VMs:"

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