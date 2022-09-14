#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-29 17:02:24
# LastEditors: cnak47
# LastEditTime: 2022-09-14 16:08:33
# FilePath: /docker_workspace/ak47Docker/k3s/addons/metal-lb/test-metal-lb.sh
# Description: 
# 
# Copyright (c) 2022 by cnak47, All Rights Reserved. 
###----------------------------------------------------------------------------
 
kubectl apply -f whoami-deploy.yaml
sleep 10
kubectl get pods -n who
kubectl get svc -n who