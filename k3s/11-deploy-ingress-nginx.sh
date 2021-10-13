#!/bin/bash
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color

echo -e "[${GREEN}Deploying Nginx Ingress Controller${NC}]"
echo "############################################################################"
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
for WORKER in ${WORKERS}; do
    echo -e "[${LB}Info${NC}] deploy images on ${WORKER}"
    multipass  transfer addons/ingress-nginx/1.0.3/ingress-nginx-controller.tar "${WORKER}":
    multipass  transfer addons/ingress-nginx/1.0.3/ingress-nginx-kube-webhook-certgen.tar "${WORKER}":
    multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-controller.tar" | grep -w "unpacking"
    multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-kube-webhook-certgen.tar" | grep -w "unpacking"
    multipass exec "${WORKER}" -- /bin/bash -c "sudo crictl images" | grep -w "ingress-nginx"
   
done
sleep 5
#export KUBECONFIG=$(pwd)/k3s.yaml
kubectl create ns ingress-nginx
kubectl create -f addons/ingress-nginx/1.0.3/deploy.yaml

sleep 10
POD_NAMESPACE=ingress-nginx
POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD_NAME -n $POD_NAMESPACE -- /nginx-ingress-controller --version
