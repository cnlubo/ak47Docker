#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-17 10:37:56
# @LastEditors: cnak47
# @LastEditTime: 2019-12-23 16:42:12
# @Description: 
# #

set -e
# shellcheck disable=SC1091
source /build/buildconfig
[[ ${debug:?} == true ]] && set -x
# Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io >/etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi
