#!/bin/bash
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m' # No Color

echo -e "[${GREEN}Deploying MetalLB LoadBalancer${NC}]"
echo "############################################################################"

export KUBECONFIG=`pwd`/k3s.yaml
metallb_version=0.10.2
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/metallb.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v$metallb_version/manifests/namespace.yaml
# On first install only
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
# kubectl create -f metal-lb-layer2-config.yaml