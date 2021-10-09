#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-09-16 21:59:56
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 17:52:32
 # @Description: 
 ###

set -e
# shellcheck disable=SC1091
source /assets/build/buildconfig
[[ ${debug:?} == true ]] && set -x
## Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

adduser --disabled-login --gecos 'Nginx' "${NGINX_USER:?}"
passwd -d "${NGINX_USER:?}"
