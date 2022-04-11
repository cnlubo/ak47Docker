#!/bin/bash
cpuCount=4
memCount=2
diskCount=10
OSversion=20.04
multipass launch --name mup-docker \
    --cpus ${cpuCount} \
    --mem ${memCount}G \
    --disk ${diskCount}G \
    --cloud-init cloud-config.yaml \
    "$OSversion"
