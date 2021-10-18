#!/bin/bash

GREEN='\033[0;32m'
LB='\033[1;34m' # light blue
NC='\033[0m'    # No Color
cpuCount=4
memCount=2
diskCount=10
OSversion=18.04
multipass launch --name mup-docker \
--cpus ${cpuCount} \
--mem ${memCount}G \
--disk ${diskCount}G \
--cloud-init cloud-config.yaml \
"$OSversion"

sleep 10

