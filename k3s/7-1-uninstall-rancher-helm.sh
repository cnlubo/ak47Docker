#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-05-09 10:45:56
# LastEditors: cnak47
# LastEditTime: 2022-05-18 22:31:10
# FilePath: /docker_workspace/ak47Docker/k3s/7-1-uninstall-rancher-helm.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
###----------------------------------------------------------------------------
# set -e
MODULE="$(basename $0)"
# dirname $0，取得当前执行的脚本文件的父目录
# cd `dirname $0`，进入这个目录(切换当前工作目录)
# pwd，显示当前工作目录(cd执行后的)
parentdir=$(dirname "$0")
ScriptPath=$(cd "${parentdir:?}" && pwd)
# BASH_SOURCE[0] 等价于 BASH_SOURCE,取得当前执行的shell文件所在的路径及文件名
scriptdir=$(dirname "${BASH_SOURCE[0]}")
#加载配置内容
# shellcheck disable=SC1091
source "$ScriptPath"/include/color.sh
# shellcheck disable=SC1091
source "$ScriptPath"/include/common.sh
SOURCE_SCRIPT "${scriptdir:?}"/options.conf

# Check kubectl existence
if ! type kubectl >/dev/null 2>&1; then
    EXIT_MSG "$MODULE" "kubectl not found in PATH, make sure kubectl is available"
fi

# Check timeout existence
if ! type timeout >/dev/null 2>&1; then
    EXIT_MSG "$MODULE" "timeout not found in PATH, make sure timeout is available"
fi

# Test connectivity
if ! kubectl get nodes >/dev/null 2>&1; then
    EXIT_MSG "$MODULE" "'kubectl get nodes' exited non-zero, make sure environment variable KUBECONFIG is set to a working kubeconfig file"
fi

# echo "=> Printing cluster info for confirmation"
# kubectl cluster-info
# kubectl get nodes -o wide

WARNING_MSG "$MODULE" "==================== WARNING ===================="
WARNING_MSG "$MODULE" "THIS WILL DELETE ALL RESOURCES CREATED BY RANCHER"
WARNING_MSG "$MODULE" "MAKE SURE YOU HAVE CREATED AND TESTED YOUR BACKUPS"
WARNING_MSG "$MODULE" "THIS IS A NON REVERSIBLE ACTION"
WARNING_MSG "$MODULE" "==================== WARNING ===================="
input_n='n'
read -r -p "Are you sure to remove Rancher V${rancher_version:?} ? [y/n] " input
result="${input:-$input_n}"
if ! [ "$result" = "y" -o "$result" = "Y" ]; then
    exit 1
fi
kcd() {
    i="0"
    while [ $i -lt 4 ]; do

        timeout 21 sh -c \
            'kubectl delete --ignore-not-found=true --grace-period=15 --timeout=20s '"$@"''
        if [ $? -eq 0 ]; then
            break
        fi
        i=$(($i + 1))
    done
}

kcpf() {
    FINALIZERS=$(kubectl get -o jsonpath="{.metadata.finalizers}" "$@")
    if [ "x${FINALIZERS}" != "x" ]; then
        #echo "Finalizers before for $@: ${FINALIZERS}"
        echo "Finalizers before for $*: ${FINALIZERS}"
        kubectl patch -p '{"metadata":{"finalizers":null}}' --type=merge "$@"
        echo "Finalizers after for $*: $(kubectl get -o jsonpath="{.metadata.finalizers}" "$@")"
    fi
}

kcdns() {
    if kubectl get namespace "$1"; then
        kcpf namespace "$1"
        FINALIZERS=$(kubectl get -o jsonpath="{.spec.finalizers}" namespace "$1")
        if [ "x${FINALIZERS}" != "x" ]; then
            echo "Finalizers before for namespace $1: ${FINALIZERS}"
            kubectl get -o json namespace "$1" | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/"$1"/finalize -f -
            echo "Finalizers after for namespace $1: $(kubectl get -o jsonpath="{.spec.finalizers}" namespace "$1")"
        fi
        i="0"
        while [ $i -lt 4 ]; do
            timeout 21 sh -c 'kubectl delete --ignore-not-found=true --grace-period=15 --timeout=20s namespace '"$1"''
            if [ $? -eq 0 ]; then
                break
            fi
            i=$(($i + 1))
        done
    fi
}

printapiversion() {
    if echo "$1" | grep -q '/'; then
        echo "$1" | cut -d'/' -f1
    else
        echo ""
    fi
}

# Namespaces with resources that probably have finalizers/dependencies (needs manual traverse to patch and delete else it will hang)
# CATTLE_NAMESPACES="local cattle-system cattle-impersonation-system cattle-global-data cattle-global-nt"
# TOOLS_NAMESPACES="istio-system cattle-resources-system cis-operator-system cattle-dashboards cattle-gatekeeper-system cattle-alerting cattle-logging cattle-pipeline cattle-prometheus rancher-operator-system cattle-monitoring-system cattle-logging-system"
# FLEET_NAMESPACES="cattle-fleet-clusters-system cattle-fleet-local-system cattle-fleet-system fleet-default fleet-local fleet-system"
KUBE_CONFIG="$HOME/.kube/config"
CATTLE_NAMESPACES='local|cattle-system|cattle-impersonation-system|cattle-global-data|cattle-global-nt'
TOOLS_NAMESPACES='istio-system|cattle-resources-system|cis-operator-system|cattle-dashboards|cattle-gatekeeper-system|cattle-alerting|cattle-logging|cattle-pipeline|cattle-prometheus|rancher-operator-system|cattle-monitoring-system|cattle-logging-system'
FLEET_NAMESPACES='cattle-fleet-clusters-system|cattle-fleet-local-system|cattle-fleet-system|fleet-default|fleet-local|fleet-system'

ALLNS="$CATTLE_NAMESPACES|$TOOLS_NAMESPACES|$FLEET_NAMESPACES"
ALLNAMESPACES=$(kubectl get ns | grep -E "$ALLNS" | awk '{print $1}')
# echo -e $ALLNAMESPACES

# System namespaces
# SYSTEM_NAMESPACES="kube-system ingress-nginx"

K8S_API_URL=$(kubectl --kubeconfig="${KUBE_CONFIG}" config view --raw -o json | jq -r '.clusters[0].cluster.server')

# # 注意：如果 config 中证书是以文件保存，此处命令
# kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json |
#     jq -r '.users[0].user."client-certificate-data"' |
#     tr -d '"' | base64 --decode >tmp/client_cert.pem

# kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json |
#     jq -r '.users[0].user."client-key-data"' |
#     tr -d '"' | base64 --decode >tmp/client_key.pem

# kubectl --kubeconfig=${KUBE_CONFIG} config view --raw -o json |
#     jq -r '.clusters[0].cluster."certificate-authority-data"' |
#     tr -d '"' | base64 --decode >tmp/client_ca.pem
# INFO_MSG "$MODULE" "处理删除中断"

# curl -k ${K8S_API_URL}/api/v1/namespaces/local/finalize \
#     --cert tmp/client_cert.pem \
#     --key tmp/client_key.pem \
#     --cacert tmp/client_ca.pem \
#     -H "Content-Type: application/json" \
#     -X PUT \
#     -d '{"apiVersion":"v1","kind":"Namespace","metadata":{"name":"local"},"spec":{"finalizers":[]}}'

# Delete rancher install to not have anything running that (re)creates resources
INFO_MSG "$MODULE" "Delete rancher install resources"
kcd "-n cattle-system deploy,ds --all"
kubectl -n cattle-system wait --for delete pod --selector=app=rancher
# Delete the only resource not in cattle namespaces
INFO_MSG "$MODULE" "Delete the only resource not in cattle namespaces"
kcd "-n kube-system configmap cattle-controllers"

# Delete any blocking webhooks from preventing requests
INFO_MSG "$MODULE" "Delete any blocking webhooks from preventing requests"
if [ -n "$(kubectl get mutatingwebhookconfigurations -o name | grep cattle\.io)" ]; then
    kcd "$(kubectl get mutatingwebhookconfigurations -o name | grep cattle\.io)"
fi
if [ -n "$(kubectl get validatingwebhookconfigurations -o name | grep cattle\.io)" ]; then
    kcd "$(kubectl get validatingwebhookconfigurations -o name | grep cattle\.io)"
fi
# Delete any istio webhooks
INFO_MSG "$MODULE" "Delete any istio webhooks"
if [ -n "$(kubectl get mutatingwebhookconfigurations -o name | grep istio)" ]; then
    kcd "$(kubectl get mutatingwebhookconfigurations -o name | grep istio)"
fi
if [ -n "$(kubectl get validatingwebhookconfigurations -o name | grep istio)" ]; then
    kcd "$(kubectl get validatingwebhookconfigurations -o name | grep istio)"
fi
# Cluster api
INFO_MSG "$MODULE" "Delete Cluster api"
if [ -n "$(kubectl get validatingwebhookconfiguration.admissionregistration.k8s.io -ojson | grep validating-webhook-configuration)" ]; then
    kcd validatingwebhookconfiguration.admissionregistration.k8s.io/validating-webhook-configuration
fi
if [ -n "$(kubectl get mutatingwebhookconfiguration.admissionregistration.k8s.io -ojson | grep mutating-webhook-configuration)" ]; then
    kcd mutatingwebhookconfiguration.admissionregistration.k8s.io/mutating-webhook-configuration
fi

# Delete generic k8s resources either labeled with norman or resource name starting with "cattle|rancher|fleet"
# ClusterRole/ClusterRoleBinding
INFO_MSG "$MODULE" "Delete generic k8s resources ClusterRole/ClusterRoleBinding"

kubectl get clusterrolebinding -l cattle.io/creator=norman --no-headers -o custom-columns=NAME:.metadata.name | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^cattle- | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep rancher | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^fleet- | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^gitjob | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^pod-impersonation-helm- | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^gatekeeper | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^cis | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterrolebinding --no-headers -o custom-columns=NAME:.metadata.name | grep ^istio | while read CRB; do
    kcpf clusterrolebindings "$CRB"
    kcd "clusterrolebindings $CRB"
done

kubectl get clusterroles -l cattle.io/creator=norman --no-headers -o custom-columns=NAME:.metadata.name | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^cattle- | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep rancher | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^fleet | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^gitjob | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^pod-impersonation-helm | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^logging- | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^monitoring- | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^gatekeeper | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^cis | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

kubectl get clusterroles --no-headers -o custom-columns=NAME:.metadata.name | grep ^istio | while read CR; do
    kcpf clusterroles "$CR"
    kcd "clusterroles $CR"
done

INFO_MSG "MODULE" "Delete podsecuritypolicy"
# Rancher monitoring
for psp in $(kubectl get podsecuritypolicy -o name -l release=rancher-monitoring) $(kubectl get podsecuritypolicy -o name -l app=rancher-monitoring-crd-manager) $(kubectl get podsecuritypolicy -o name -l app=rancher-monitoring-patch-sa) $(kubectl get podsecuritypolicy -o name -l app.kubernetes.io/instance=rancher-monitoring); do
    kcd "$psp"
done

# Rancher OPA
for psp in $(kubectl get podsecuritypolicy -o name -l release=rancher-gatekeeper) $(kubectl get podsecuritypolicy -o name -l app=rancher-gatekeeper-crd-manager); do
    kcd "$psp"
done

# Backup restore operator
for psp in $(kubectl get podsecuritypolicy -o name -l app.kubernetes.io/name=rancher-backup); do
    kcd "$psp"
done

# Istio
INFO_MSG "MODULE" "Delete Istio podsecuritypolicy"
for psp in istio-installer istio-psp kiali-psp psp-istio-cni; do
    kcd "podsecuritypolicy $psp"
done

# Get all namespaced resources and delete in loop
# Exclude helm.cattle.io and k3s.cattle.io to not break K3S/RKE2 addons

INFO_MSG "MODULE" "Delete all namespaced resources"
kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep cattle\.io | grep -v helm\.cattle\.io | grep -v k3s\.cattle\.io | grep -v catalogtemplateversion | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
    kcpf -n $NAMESPACE "${KIND}.$(printapiversion $APIVERSION)" $NAME
    kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
done
# kubectl get "$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep cattle\.io | grep -v helm\.cattle\.io | grep -v k3s\.cattle\.io | tr "\n" "," | sed -e 's/,$//')" -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
#     kcpf -n $NAMESPACE "${KIND}.$(printapiversion $APIVERSION)" $NAME
#     kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
# done
INFO_MSG "MODULE" "Delete all namespaced resources -- logging"
# Logging
if [ -n "$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep logging\.banzaicloud\.io)" ]; then
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep logging\.banzaicloud\.io | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n $NAMESPACE "${KIND}.$(printapiversion $APIVERSION)" $NAME
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done
fi
kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | grep rancher-monitoring | while read NAME NAMESPACE KIND APIVERSION; do
    kcpf -n $NAMESPACE "${KIND}.$(printapiversion $APIVERSION)" $NAME
    kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
done

# Monitoring
INFO_MSG "MODULE" "Delete all namespaced resources -- Monitoring"
if [ -n "$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep monitoring\.coreos\.com)" ]; then
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep monitoring\.coreos\.com | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion "$APIVERSION")" $NAME
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done
fi
# Gatekeeper
INFO_MSG "MODULE" "Delete all namespaced resources -- Gatekeeper"

if [ -n "$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep gatekeeper\.sh)" ]; then
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep gatekeeper\.sh | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" $NAME
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done
fi
# Cluster-api
INFO_MSG "MODULE" "Delete all namespaced resources -- Cluster-api"
if [ -n "$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep cluster\.x-k8s\.io)" ]; then
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep cluster\.x-k8s\.io | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" $NAME
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done
fi
# # Get all non-namespaced resources and delete in loop
INFO_MSG "MODULE" "Delete all non-namespaced resources"
if [ -n "$(kubectl api-resources --namespaced=false --verbs=delete -o name | grep cattle\.io)" ]; then
    kubectl get $(kubectl api-resources --namespaced=false --verbs=delete -o name | grep cattle\.io | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o name | while read NAME; do
        kcpf "$NAME"
        kcd "$NAME"
    done
fi
# Logging
INFO_MSG "MODULE" "Delete all non-namespaced resources -- Logging"
if [ -n "$(kubectl api-resources --namespaced=false --verbs=delete -o name | grep logging\.banzaicloud\.io)" ]; then
    kubectl get $(kubectl api-resources --namespaced=false --verbs=delete -o name | grep logging\.banzaicloud\.io | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o name | while read NAME; do
        kcpf "$NAME"
        kcd "$NAME"
    done
fi
# Gatekeeper
INFO_MSG "MODULE" "Delete all non-namespaced resources -- Gatekeeper"
if [ -n "$(kubectl api-resources --namespaced=false --verbs=delete -o name | grep gatekeeper\.sh)" ]; then
    kubectl get $(kubectl api-resources --namespaced=false --verbs=delete -o name | grep gatekeeper\.sh | tr "\n" "," | sed -e 's/,$//') -A --no-headers -o name | while read NAME; do
        kcpf "$NAME"
        kcd "$NAME"
    done
fi
# Delete istio certs
INFO_MSG "MODULE" "Delete istio certs"
for NS in $(kubectl get ns --no-headers -o custom-columns=NAME:.metadata.name); do
    kcd "-n $NS configmap istio-ca-root-cert"
done

# # Delete all cattle namespaces, including project namespaces (p-),cluster (c-),cluster-fleet and user (user-) namespaces
INFO_MSG "MODULE" "Delete all cattle namespaces"
for NS in $ALLNAMESPACES; do

    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//') -n $NS --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" "$NAME"
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done
    kcdns "$NS"

done

for NS in $(kubectl get namespace --no-headers -o custom-columns=NAME:.metadata.name | grep "^cluster-fleet"); do
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//') -n $NS --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" "$NAME"
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done

    kcdns "$NS"
done

for NS in $(kubectl get namespace --no-headers -o custom-columns=NAME:.metadata.name | grep "^p-"); do
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//') -n $NS --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" "$NAME"
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done

    kcdns "$NS"
done

for NS in $(kubectl get namespace --no-headers -o custom-columns=NAME:.metadata.name | grep "^c-"); do
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//') -n $NS --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" "$NAME"
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done

    kcdns "$NS"
done

for NS in $(kubectl get namespace --no-headers -o custom-columns=NAME:.metadata.name | grep "^user-"); do
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//') -n $NS --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" "$NAME"
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done

    kcdns "$NS"
done

for NS in $(kubectl get namespace --no-headers -o custom-columns=NAME:.metadata.name | grep "^u-"); do
    kubectl get $(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v events\.events\.k8s\.io | grep -v ^events$ | tr "\n" "," | sed -e 's/,$//') -n $NS --no-headers -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,KIND:.kind,APIVERSION:.apiVersion | while read NAME NAMESPACE KIND APIVERSION; do
        kcpf -n "$NAMESPACE" "${KIND}.$(printapiversion $APIVERSION)" $NAME
        kcd "-n $NAMESPACE ${KIND}.$(printapiversion $APIVERSION) $NAME"
    done

    kcdns "$NS"
done

# Delete logging CRDs
INFO_MSG "MODULE" "Delete logging CRDs"

for CRD in $(kubectl get crd -o name | grep logging\.banzaicloud\.io); do
    kcd "$CRD"
done

# Delete monitoring CRDs
INFO_MSG "MODULE" "Delete monitoring CRDs"
for CRD in $(kubectl get crd -o name | grep monitoring\.coreos\.com); do
    kcd "$CRD"
done

# Delete OPA CRDs
INFO_MSG "MODULE" "Delete OPA CRDs"
for CRD in $(kubectl get crd -o name | grep gatekeeper\.sh); do
    kcd "$CRD"
done

# Delete Istio CRDs
INFO_MSG "MODULE" "Delete Istio CRDs"
for CRD in $(kubectl get crd -o name | grep istio\.io); do
    kcd "$CRD"
done

# Delete cluster-api CRDs
INFO_MSG "MODULE" "Delete cluster-api CRDs"
for CRD in $(kubectl get crd -o name | grep cluster\.x-k8s\.io); do
    kcd "$CRD"
done

# Delete all cattle CRDs
# Exclude helm.cattle.io and addons.k3s.cattle.io to not break RKE2 addons
INFO_MSG "MODULE" "Delete all cattle CRDs"
for CRD in $(kubectl get crd -o name | grep cattle\.io | grep -v helm\.cattle\.io | grep -v k3s\.cattle\.io); do
    kcd "$CRD"
done

# kubectl delete -n cattle-system MutatingWebhookConfiguration rancher.cattle.io

SUCCESS_MSG "$MODULE" "############################################################################"
SUCCESS_MSG "$MODULE" "Success uninstall Rancher V$rancher_version"
SUCCESS_MSG "$MODULE" "############################################################################"
