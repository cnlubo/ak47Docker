#!/bin/bash
# check if required applications and files are available
#./utils/dependency-check.sh

nodeCount=1
read -p "How many worker nodes do you want to add?(default:$nodeCount) promt with [ENTER]:" inputNode
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
OSversion=18.04
read -p "Which Ubuntu version do you want to use? check multipass find (default:$OSversion) promt with [ENTER]:" inputOSversion
OSversion="${inputOSversion:-$OSversion}"
num_Worker=$(multipass list | grep worker | wc -l)
begin_num=$(($num_Worker + 1))
end_num=$(($num_Worker + $nodeCount))
WORKER=$(eval 'echo k3s-worker{'"$begin_num"'..'"$end_num"'}')
NODES+=$WORKER
# # Create containers
for NODE in ${NODES}; do
  echo "############################################################################"
  echo "Deploy multipass vm $NODE"
  multipass launch --name ${NODE} --cpus ${cpuCount} --mem ${memCount}G --disk ${diskCount}G --cloud-init cloud-config.yaml "$OSversion"
done

# Wait a few seconds for nodes to be up
sleep 5

for NODE in ${NODES}; do
  multipass transfer ~/.ssh/id_rsa.pub ${NODE}:
  multipass exec ${NODE} -- sudo iptables -P FORWARD ACCEPT
  multipass exec ${NODE} -- bash -c 'sudo cat /home/ubuntu/id_rsa.pub >> /home/ubuntu/.ssh/authorized_keys'
done
