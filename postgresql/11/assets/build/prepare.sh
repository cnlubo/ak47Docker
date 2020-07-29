#!/bin/bash
# @Author: cnak47
# @Date: 2018-07-31 14:42:46
# @LastEditors: cnak47
# @LastEditTime: 2019-12-21 11:17:38
# @Description: 
# #

set -e
# shellcheck disable=SC1091
source /build/buildconfig
[[ ${debug:?} == true ]] && set -x

# Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi
