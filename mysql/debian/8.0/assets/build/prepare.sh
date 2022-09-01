#!/bin/bash
###---------------------------------------------------------------------------
# Author: cnak47
# Date: 2022-08-29 10:18:18
# LastEditors: cnak47
# LastEditTime: 2022-09-01 11:09:56
# FilePath: /docker_workspace/ak47Docker/mysql/debian/8.0/assets/build/prepare.sh
# Description:
#
# Copyright (c) 2022 by cnak47, All Rights Reserved.
set -e
# shellcheck disable=SC1091
source /build/buildconfig
[[ ${debug:?} == true ]] && set -x
# Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io >/etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

groupadd -r "$MYSQL_USER" --gid=999 &&
    useradd -r -g "$MYSQL_USER" --uid=999 --home-dir="$MYSQL_HOME" "$MYSQL_USER"

mkdir -p "$MYSQL_HOME" &&
    chown -R "$MYSQL_USER":"$MYSQL_USER" "$MYSQL_HOME"
