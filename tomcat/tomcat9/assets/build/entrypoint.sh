#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-11-03 21:29:23
 # @LastEditors: cnak47
 # @LastEditTime: 2019-11-05 17:48:03
 # @Description: 
 ###

set -ex
# shellcheck disable=SC1091
# shellcheck disable=SC1090
source "${PG_APP_HOME}"/functions

# allow arguments to be passed to postgres
# 允许传递参数 to postgres
# [ ${1:0:1} = '-' ] It's a test for a - dashed argument option
# ${@:2} 第2个参数开始后的所有参数
if [[ ${1:0:1} = '-' ]]; then
    EXTRA_ARGS=( "$@" )
    set --
elif [[ ${1} == postgres || ${1} == $(which postgres) ]]; then
    EXTRA_ARGS=( "${@:2}" )
    set --
fi

# default behaviour is to launch postgres
if [[ -z ${1} ]]; then

    map_uidgid
    create_datadir
    create_certdir
    create_logdir
    create_rundir

    set_resolvconf_perms
    configure_postgresql

    info "Starting PostgreSQL ${PG_VERSION}..."
    exec tini -- start-stop-daemon --start --chuid "${PG_USER}":"${PG_USER}" \
        --exec "${PG_BINDIR}"/postgres -- -D "${PG_DATADIR}" "${EXTRA_ARGS[@]}"
else
    exec tini -- "$@"
fi
