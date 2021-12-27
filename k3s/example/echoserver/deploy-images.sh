#!/bin/bash
###
 # @Author: your name
 # @Date: 2021-12-27 10:29:08
 # @LastEditTime: 2021-12-27 10:32:02
 # @LastEditors: Please set LastEditors
 # @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 # @FilePath: /ak47Docker/k3s/example/echoserver/deploy-images.sh
### 
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color
echo -e "[${GREEN}Deploying gcr echoserver image ${NC}]"
echo "############################################################################"
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    echo -e "[${LB}Info${NC}] deploy images on ${WORKER}"
    multipass transfer gcr.io-google-containers-echoserver-v1.10.tar "${WORKER}":
    multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import gcr.io-google-containers-echoserver-v1.10.tar" | grep -w "unpacking"
    
done
sleep 5