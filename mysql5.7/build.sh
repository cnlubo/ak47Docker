#!/bin/bash
docker build --no-cache -t cnlubo/centos-mysql5.7:v1 -m 4g -f Dockerfile.mysql5.7 .
