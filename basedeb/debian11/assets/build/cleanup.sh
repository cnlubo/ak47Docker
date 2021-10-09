#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-11-20 16:27:19
# @LastEditors: cnak47
# @LastEditTime: 2019-09-25 11:19:25
# @Description:
###

# shellcheck disable=SC1091
set -e
source /assets/buildconfig
[[ ${debug:?} == true ]] && set -x

apt-get autoremove -y &&
    apt-get clean -y &&
    apt-get autoclean -y &&
    rm -rf /var/lib/apt/lists/* &&
    rm -rf /var/cache/debconf/*-old &&
    rm -f /etc/dpkg/dpkg.cfg.d/02apt-speedup &&
    rm -f /etc/ssh/ssh_host_* &&
    rm -rf /root/.gnupg &&
    rm -rf /assets &&
    rm -rf "${build_src:?}"
shopt -s extglob
cd /var/log && rm -rf !(supervisor|syslog)
shopt -u extglob
rm -rf /usr/local/share/man && mkdir -p /usr/local/share/man/man1

find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests \) \) \
    -o \
    \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' +
