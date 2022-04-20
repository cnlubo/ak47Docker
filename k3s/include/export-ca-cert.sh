#!/bin/bash
###---------------------------------------------------------------------------
#Author: cnak47
#Date: 2022-04-20 22:42:21
#LastEditors: cnak47
#LastEditTime: 2022-04-20 22:42:22
#FilePath: /ak47Docker/k3s/include/export-ca-cert.sh
#Description: 
#
#Copyright (c) 2022 by cnak47, All Rights Reserved. 
###---------------------------------------------------------------------------
# 导出 CA 证书
kubectl get secret/selfsigned-ca-root-secret -n cert-manager -o json \
  | jq -r '.data["ca.crt"]' \
  | base64 -D > selfsigned-root-ca.crt