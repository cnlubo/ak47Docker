#!/bin/bash
###
# @Author: cnak47
# @Date: 2022-01-06 15:19:35
 # @LastEditors: cnak47
 # @LastEditTime: 2022-04-08 11:41:45
 # @FilePath: /ak47Docker/k3s/4-0-deploy-traefik-dashboard.sh
# @Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
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
addons_dir=addons/traefik/$traefik_version
echo -e "[${GREEN}Download traefik CRD file${NC}]"
mkdir -p $crd_dir
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressroutes.yaml \
    -o $addons_dir/crd/01-traefik.containo.us_ingressroutes.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressroutetcps.yaml \
    -o $addons_dir/crd/02-traefik.containo.us_ingressroutetcps.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_ingressrouteudps.yaml \
    -o $addons_dir/crd/03-traefik.containo.us_ingressrouteudps.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewares.yaml \
    -o $addons_dir/crd/04-traefik.containo.us_middlewares.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_middlewaretcps.yaml \
    -o $addons_dir/crd/05-traefik.containo.us_middlewaretcps.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_serverstransports.yaml \
    -o $addons_dir/crd/06-traefik.containo.us_serverstransports.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_tlsoptions.yaml \
    -o $addons_dir/crd/07-traefik.containo.us_tlsoptions.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_tlsstores.yaml \
    -o $addons_dir/crd/08-traefik.containo.us_tlsstores.yaml
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/traefik.containo.us_traefikservices.yaml \
    -o $addons_dir/crd/09-traefik.containo.us_traefikservices.yaml
echo -e "[${GREEN}Download traefik RBAC file${NC}]"
curl https://raw.githubusercontent.com/traefik/traefik/v$traefik_version/docs/content/reference/dynamic-configuration/kubernetes-crd-rbac.yml \
    -o addons/traefik/$traefik_version/001-01-rabc.yaml
