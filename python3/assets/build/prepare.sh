#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-09-14 10:41:21
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 15:19:38
# @Description:
###

set -e
# shellcheck disable=SC1091
source /assets/buildconfig
[[ ${debug:?} == true ]] && set -x
## Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi