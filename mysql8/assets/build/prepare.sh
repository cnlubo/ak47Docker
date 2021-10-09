#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-11-03 21:29:23
# @LastEditors: Please set LastEditors
# @LastEditTime: 2021-07-25 11:55:38
# @Description:
###
set -e
# shellcheck disable=SC1091
source /build/buildconfig
[[ ${debug:?} == true ]] && set -x

# Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io >/etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

# explicitly set user/group IDs

groupadd -r $MySQL_USER --gid=999 &&
    useradd -r -g $MySQL_USER --uid=999 --home-dir="$MySQL_HOME" $MySQL_USER

# create the MySQL user's home directory with appropriate permissions
mkdir -p "$MySQL_HOME" &&
    chown -R $MySQL_USER:$MySQL_USER "$MySQL_HOME"
