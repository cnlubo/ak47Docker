#!/bin/bash
###
# @Author: your name
# @Date: 2021-12-27 16:24:59
 # @LastEditTime: 2021-12-28 14:02:35
 # @LastEditors: Please set LastEditors
# @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
# @FilePath: /ak47Docker/k3s/example/echoserver/services_with_nodeport.sh
###
NODEPORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services nodeport -n echoserver)
NODES=$(kubectl get nodes -l '!node-role.kubernetes.io/master' -o jsonpath='{ $.items[*].status.addresses[?(@.type=="InternalIP")].address }')

for node in $NODES; do
    echo $node:$NODEPORT
    #echo ""
    curl -s $node:$NODEPORT | grep -i client_address
done
