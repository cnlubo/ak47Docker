#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-09-16 21:59:56
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-26 12:07:50
 # @Description: 
 ###

set -e
# shellcheck disable=SC1091
source /assets/build/buildconfig
[[ ${debug:?} == true ]] && set -x
apt-get autoremove -y && \
    apt-get clean -y && \
    apt-get autoclean -y && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /var/cache/debconf/*-old && \
    rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup && \
    rm -f /etc/ssh/ssh_host_* && \
    rm -rf /assets/build
    # rm -rf $NGINX_BUILD_ASSETS_DIR
shopt -s extglob
cd /var/log && rm -rf !(supervisor|syslog)
shopt -u extglob

find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests \) \) \
    -o \
    \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' +
