#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-11-03 21:29:23
# @LastEditors: cnak47
# @LastEditTime: 2020-10-07 21:14:47
 # @Description: 
 ###
set -e
# shellcheck disable=SC1091
source /build/buildconfig
[[ ${debug:?} == true ]] && set -x

# Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi



