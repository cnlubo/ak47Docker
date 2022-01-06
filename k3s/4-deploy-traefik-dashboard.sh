#!/bin/bash
###
 # @Author: your name
 # @Date: 2022-01-06 15:19:35
 # @LastEditTime: 2022-01-06 15:19:51
 # @LastEditors: your name
 # @Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 # @FilePath: /ak47Docker/k3s/4-deploy-traefik-dashboard.sh
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