#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-11-03 21:29:23
 # @LastEditors: cnak47
 # @LastEditTime: 2019-11-05 16:28:00
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

# explicitly set user/group IDs
pgsql_user=postgres
groupadd -r $pgsql_user --gid=999 &&
    useradd -r -g $pgsql_user --uid=999 --home-dir="$PG_HOME" $pgsql_user

# create the postgres user's home directory with appropriate permissions
# see https://github.com/docker-library/postgres/issues/274
mkdir -p "$PG_HOME" &&
    chown -R $pgsql_user:$pgsql_user "$PG_HOME"


