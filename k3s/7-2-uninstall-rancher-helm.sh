#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-05-04 22:31:11
# LastEditors: cnak47
# LastEditTime: 2022-05-09 16:13:09
# FilePath: /docker_workspace/ak47Docker/k3s/7-2-uninstall-rancher-helm.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###----------------------------------------------------------------------------
# k8s=1.18 rchaner=2.5.5

api_server="https://k3s-master:6443"
#token=`kubectl describe secret default-token-2ppjf |grep token: |awk -F: ‘{print $2}’|sed s/’ '//g`
#token=$(cat .kube/admin-token)
#K3S_TOKEN="$(multipass exec k3s-master -- /bin/bash -c "sudo cat /var/lib/rancher/k3s/server/node-token")"

# echo "处理删除中断"
# curl -k $api_server/api/v1/namespaces/local/finalize \
#     -H "Authorization: Bearer $token" \
#     -H "Content-Type: application/json" \
#     -XPUT \
#     -d '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"local"},"spec":{"finalizers":[]}}'

kubectl patch --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' ns $(kubectl get ns | egrep 'cattle|fleet|rancher|local|^p-|^user-' | awk '{print $1}')
project_ns=$(kubectl get ns | egrep '^p-|local' | awk '{print $1}')
project_crd=(clusterroletemplatebindings.management.cattle.io clusteralertgroups.management.cattle.io projects.management.cattle.io projectalertgroups.management.cattle.io projectalertrules.management.cattle.io projectroletemplatebindings.management.cattle.io nodes.management.cattle.io)

# for ns in ${project_ns[@]}; do
#     for crd in ${project_crd[@]}; do
#         kubectl patch --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' $crd -n $ns $(kubectl get $crd -n $ns | grep -v NAME | awk '{print $1}')
#     done
# done

crd_list=$(kubectl get crd | grep cattle.io | awk '{print $1}')

# for crd in $crd_list; do

#     kubectl patch --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' $crd $(kubectl get $crd | grep -v NAME | awk '{print $1}')

# done

# echo "使用rancher清理工具 https://docs.rancher.cn/docs/rancher2/system-tools/_index/"
# ./system-tools remove -c .kube/config
#./system-tools_darwin-amd64 remove -c  ~/.kube/config

# kubectl get crd

# echo "理论上所有rancher的crd都会被删除，如果还有说明有异常，继续会强制删除"
# echo "按任意键继续"
# read anykey

# echo "helm卸载"
helm uninstall fleet -n cattle-fleet-system
helm uninstall fleet-crd -n cattle-fleet-system
helm uninstall fleet-agent-local -n cattle-fleet-local-system
helm uninstall rancher-webhook -n cattle-system
helm uninstall rancher -n cattle-system

# echo "清理剩余资源"
# sleep 5

# for ns in $(kubectl get ns | grep -v NAME | awk '{print $1}'); do
#     kubectl delete rolebinding $(kubectl get rolebinding -n $ns --selector='cattle.io/creator=norman' | grep -v NAME | awk '{print $1}') -n $ns
# done

# ns_list=$(kubectl get ns | egrep 'cattle|fleet|rancher|local' | awk '{print $1}')

# kubectl delete ns $ns_list

# kubectl patch --type='json' -p='[{"op": "remove", "path": "/metadata/finalizers"}]' crd $(kubectl get crd | grep 'cattle.io' | awk '{print $1}')
# kubectl get crd | grep 'cattle.io' | awk '{print $1}' | xargs kubectl delete crd
# kubectl get clusterrolebinding | egrep 'default-admin|fleet|pod-impersonation-helm-op|rancher' | awk '{print $1}' | xargs kubectl delete clusterrolebinding
# kubectl get clusterrole | egrep 'fleet|pod-impersonation-helm-op' | awk '{print $1}' | xargs kubectl delete clusterrole

# kubectl label ns $(kubectl get ns | egrep -v 'NAME' | awk '{print $1}') field.cattle.io/projectId-
