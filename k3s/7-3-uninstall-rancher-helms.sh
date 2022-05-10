#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-05-09 10:45:56
# LastEditors: cnak47
# LastEditTime: 2022-05-10 16:11:30
# FilePath: /docker_workspace/ak47Docker/k3s/7-3-uninstall-rancher-helms.sh
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

# 指定 kubeconfig 文件
KUBE_CONFIG="$HOME/.kube/config"

# 定义要删除的namespace
NS="cattle|fleet"
NAMESPACE=$(kubectl get ns | grep -E $NS | awk '{print $1}')
project_ns=$(kubectl get ns | egrep '^p-|local' | awk '{print $1}')

# 需要提前安装jq和rancher system-tools(https://rancher.com/docs/rancher/v2.x/en/system-tools/)
for c in "jq" "system-tools" "kubectl"; do
    if ! [ -x "$(command -v $c)" ]; then
        echo "Error: $c is not installed." >&2
        exit 1
    fi
done

echo -e "\n$NAMESPACE"

# read -r -p "Are you sure to remove the above namespace? [y/n] " input
# if ! [ $input = "y" -o $input = "Y" ]; then
#     exit 1
# fi

for ns in ${NAMESPACE}; do
    kubectl get ns $ns -ojson >tmp/$ns.json
done

# # 通过 system-tools 移除命名空间
# for ns in ${NAMESPACE}; do
#     system-tools remove -c ${KUBE_CONFIG} --namespace $ns --force
# done

# 移除 Terminating 状态的命名空间
# if kubectl get ns | grep Terminating; then
#     #TERMINATING_NAMESPACE=$(kubectl get ns | grep Terminating | awk '{print $1}')
#     TERMINATING_NAMESPACE=$NAMESPACE

#     K8S_API_URL=$(kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json | jq -r '.clusters[0].cluster.server')

#     # # 注意：如果 config 中证书是以文件保存，此处命令
#     # kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json |
#     #     jq -r '.users[0].user."client-certificate-data"' |
#     #     tr -d '"' | base64 --decode >/tmp/client_cert.pem

#     # kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json |
#     #     jq -r '.users[0].user."client-key-data"' |
#     #     tr -d '"' | base64 --decode >/tmp/client_key.pem

#     # kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json |
#     #     jq -r '.clusters[0].cluster."certificate-authority-data"' |
#     #     tr -d '"' | base64 --decode >/tmp/client_ca.pem

#     for t_ns in ${TERMINATING_NAMESPACE}; do

#         #kubectl --kubeconfig=${KUBE_CONFIG} get ns ${t_ns} -ojson >${t_ns}.json
#         # # 获取删除 finalizers 后的命名空间 json 配置
#         # kubectl --kubeconfig=${KUBE_CONFIG} get ns ${t_ns} -ojson |
#         #     jq 'del(.spec.finalizers[])' |
#         #     jq 'del(.metadata.finalizers)' >${t_ns}.json

#         # # 个别命名空间没有 .spec.finalizers，上面命令执行过程中将会报错，所以去掉.spec.finalizers 重新执行一次
#         # # 不知道jq如何在key为空时跳过，暂时这么处理，方法确实很烂
#         # if [[ ! -s ${t_ns}.json ]]; then
#         #     kubectl --kubeconfig=${KUBE_CONFIG} get ns ${t_ns} -ojson |
#         #         jq 'del(.metadata.finalizers)' >${t_ns}.json
#         # fi
#         # if [[ ! -s ${t_ns}.json ]]; then
#         #     kubectl --kubeconfig=${KUBE_CONFIG} get ns ${t_ns} -ojson |
#         #         jq 'del(.spec.finalizers[])' >${t_ns}.json
#         # fi

#         curl -k \
#             --cert /tmp/client_cert.pem \
#             --key /tmp/client_key.pem \
#             --cacert /tmp/client_ca.pem \
#             -H "Content-Type: application/json" \
#             -X PUT \
#             --data-binary @${t_ns}.json \
#             ${K8S_API_URL}/api/v1/namespaces/${t_ns}/finalize
#     done
# fi
