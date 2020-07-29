#!/bin/bash
continername=cnlubo/centos-mysql5.7:v1
docker run --rm -it  ${continername}

# 启动systemd --privileged 在容器内具有所有的权限默认为false
# docker run --privileged  -it -e "container=docker"  cnlubo/mycentos:v1 /usr/sbin/init
