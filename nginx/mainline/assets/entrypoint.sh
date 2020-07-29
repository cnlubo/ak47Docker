#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-09-16 21:59:56
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-27 12:14:20
 # @Description: 
 ###

set -e
# shellcheck disable=SC1091
source /assets/runtime/functions
# source ${NGINX_RUNTIME_ASSETS_DIR}/functions

create_log_dir() {

    info "Initializing log_dir..."
    mkdir -p "${NGINX_LOG_DIR}"
    mkdir -p "${NGINX_LOG_DIR}"/supervisor
    chmod -Rf 0755 "${NGINX_LOG_DIR}"/
    chown -Rf "${NGINX_USER}":root "${NGINX_LOG_DIR}"/
}

create_tmp_dir() {
    mkdir -p "${NGINX_TEMP_DIR}"
    chown -R root:root "${NGINX_TEMP_DIR}"
}

create_siteconf_dir() {

    info "Initializing conf_dir..."
    mkdir -p "${NGINX_SITECONF_DIR}"
    chmod -R 755 "${NGINX_SITECONF_DIR}"
}

create_log_dir
#create_tmp_dir
create_siteconf_dir

if [[ -z ${1} ]]; then
    rm -rf /var/run/supervisor.sock
    exec tini -- supervisord -nc /etc/supervisor/supervisord.conf
else
    exec tini -- "$@"
fi

# allow arguments to be passed to nginx
# if [[ ${1:0:1} = '-' ]]; then
#     EXTRA_ARGS="$*"
#     set --
# elif [[ ${1} == nginx || ${1} == $(which nginx) ]]; then
#     EXTRA_ARGS="${*:2}"
#     set --
# fi
#
# # default behaviour is to launch nginx
# if [[ -z ${1} ]]; then
#     info "Starting nginx..."
#     exec "$(which nginx)" -c $NGINX_HOME/conf/nginx.conf -g "daemon off;" ${EXTRA_ARGS}
# else
#     exec "$@"
# fi
