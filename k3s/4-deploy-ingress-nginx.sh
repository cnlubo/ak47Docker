#!/bin/bash
###
 # @Author: your name
 # @Date: 2021-12-17 22:45:32
 # @LastEditTime: 2021-12-30 16:58:35
 # @LastEditors: your name
 # @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 # @FilePath: /ak47Docker/k3s/4-deploy-ingress-nginx.sh
### 
GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color

echo -e "[${GREEN}Deploying Nginx Ingress Controller${NC}]"
echo "############################################################################"
WORKERS=$(echo $(multipass list | grep worker | awk '{print $1}'))
# for WORKER in ${WORKERS}; do
#     echo -e "[${LB}Info${NC}] deploy images on ${WORKER}"
#     multipass transfer addons/ingress-nginx/1.0.3/ingress-nginx-controller.tar "${WORKER}":
#     multipass transfer addons/ingress-nginx/1.0.3/ingress-nginx-kube-webhook-certgen.tar "${WORKER}":
#     multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-controller.tar" | grep -w "unpacking"
#     multipass exec "${WORKER}" -- /bin/bash -c "sudo ctr -n=k8s.io images import ingress-nginx-kube-webhook-certgen.tar" | grep -w "unpacking"
#     multipass exec "${WORKER}" -- /bin/bash -c "sudo crictl images" | grep -w "ingress-nginx"

# done
sleep 5

kubectl create -f addons/k8s-Ingress-nginx/deploy-clound.yaml
sleep 10
POD_NAMESPACE=ingress-nginx
POD_NAME=$(kubectl get pods -n $POD_NAMESPACE -l app.kubernetes.io/name=ingress-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it "$POD_NAME" -n $POD_NAMESPACE -- /nginx-ingress-controller --version
