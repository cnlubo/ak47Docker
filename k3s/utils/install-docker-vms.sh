#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-04-29 17:02:24
# LastEditors: cnak47
# LastEditTime: 2022-04-29 21:10:30
# FilePath: /docker_workspace/ak47Docker/k3s/utils/install-docker-vms.sh
# Description: 
# 
# Copyright (c) 2022 by cnak47, All Rights Reserved. 
###----------------------------------------------------------------------------
cpuCount=2
memCount=1
diskCount=10
OSversion=20.04
multipass launch --name mup-docker \
    --cpus ${cpuCount} \
    --mem ${memCount}G \
    --disk ${diskCount}G \
    --cloud-init cloud-config.yaml \
    "$OSversion"
