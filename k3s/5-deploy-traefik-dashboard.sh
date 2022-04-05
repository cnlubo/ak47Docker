#!/bin/bash
###
# @Author: your name
# @Date: 2022-01-06 15:19:35
 # @LastEditTime: 2022-04-04 19:19:32
 # @LastEditors: cnak47
# @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 # @FilePath: /ak47Docker/k3s/5-deploy-traefik-dashboard.sh
###
# # deploy traefik with dashboard
# export KUBECONFIG=k3s.yaml
# kubectl delete deployment -n kube-system traefik
# kubectl delete daemonset -n kube-system svclb-traefik
# kubectl delete service -n kube-system traefik
# kubectl delete job -n kube-system helm-install-traefik
# kubectl create ns traefik
# kubectl apply -f ./traefik/ -n traefik
# kubectl -n traefik rollout status deployment traefik-ingress-controller
# #sleep 90
# open https://node3
# # username / password : admin / admin
# kubectl delete deployment -n kube-system traefik
# kubectl delete daemonset -n kube-system svclb-traefik
# kubectl delete service -n kube-system traefik
# kubectl delete job -n kube-system helm-install-traefik
set -e
traefik_version=2.6.3
crd_dir=addons/traefik/$traefik_version/crd
echo -e "[${GREEN}Download traefik CRD file${NC}]"
mkdir -p $crd_dir
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressroutes.yaml \
    -o $crd_dir/01-traefik.containo.us_ingressroutes.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressroutetcps.yaml \
    -o $crd_dir/02-traefik.containo.us_ingressroutetcps.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressrouteudps.yaml \
    -o $crd_dir/03-traefik.containo.us_ingressrouteudps.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewares.yaml \
    -o $crd_dir/04-traefik.containo.us_middlewares.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewaretcps.yaml \
    -o $crd_dir/05-traefik.containo.us_middlewaretcps.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_serverstransports.yaml \
    -o $crd_dir/06-traefik.containo.us_serverstransports.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_tlsoptions.yaml \
    -o $crd_dir/07-traefik.containo.us_tlsoptions.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_tlsstores.yaml \
    -o $crd_dir/08-traefik.containo.us_tlsstores.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_traefikservices.yaml \
    -o $crd_dir/09-traefik.containo.us_traefikservices.yaml
echo -e "[${GREEN}Download traefik RBAC file${NC}]"
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml \
    -o addons/traefik/$traefik_version/001-01-rabc.yaml