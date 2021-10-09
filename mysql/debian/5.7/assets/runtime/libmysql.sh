#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-23 15:47:16
# @LastEditors: cnak47
# @LastEditTime: 2019-12-23 16:35:22
# @Description:
# #
# shellcheck disable=SC1091
source /opt/ak47/base/liblog.sh


########################
# Loads global variables used on MySQL/MariaDB configuration.
# Globals:
#   DB_FLAVOR
#   DB_SBIN_DIR
#   MYSQL_*/MARIADB_*
# Arguments:
#   None
# Returns:
#   Series of exports to be used as 'eval' arguments
#########################
mysql_env() {
    cat <<"EOF"
export DB_FLAVOR="${DB_FLAVOR:-mysql}"
# Format log messages
export MODULE="$DB_FLAVOR"
# export BITNAMI_DEBUG="${BITNAMI_DEBUG:-false}"
# Paths
export DB_VOLUME_DIR="/opt/$DB_FLAVOR"
export DB_DATA_DIR="$DB_VOLUME_DIR/data"
export DB_BASE_DIR="/opt/bitnami/$DB_FLAVOR"
export DB_CONF_DIR="$DB_BASE_DIR/conf"
export DB_LOG_DIR="$DB_BASE_DIR/logs"
export DB_TMP_DIR="$DB_BASE_DIR/tmp"
export DB_BIN_DIR="$DB_BASE_DIR/bin"
export DB_SBIN_DIR="${DB_SBIN_DIR:-$DB_BASE_DIR/bin}"
export PATH="$DB_BIN_DIR:$PATH"
# Users
export DB_DAEMON_USER="mysql"
export DB_DAEMON_GROUP="mysql"
# Settings
export DB_MASTER_HOST="$(get_env_var_value MASTER_HOST)"
MASTER_PORT_NUMBER="$(get_env_var_value MASTER_PORT_NUMBER)"
export DB_MASTER_PORT_NUMBER="${MASTER_PORT_NUMBER:-3306}"
PORT_NUMBER="$(get_env_var_value PORT_NUMBER)"
export DB_PORT_NUMBER="${PORT_NUMBER:-3306}"
export DB_REPLICATION_MODE="$(get_env_var_value REPLICATION_MODE)"
read -r -a DB_EXTRA_FLAGS <<< "$(mysql_extra_flags)"
export DB_EXTRA_FLAGS
# Authentication
export ALLOW_EMPTY_PASSWORD="${ALLOW_EMPTY_PASSWORD:-no}"
ROOT_USER="$(get_env_var_value ROOT_USER)"
export DB_ROOT_USER="${ROOT_USER:-root}"
export DB_DATABASE="$(get_env_var_value DATABASE)"
export DB_USER="$(get_env_var_value USER)"
export DB_REPLICATION_USER="$(get_env_var_value REPLICATION_USER)"
MASTER_ROOT_USER="$(get_env_var_value MASTER_ROOT_USER)"
export DB_MASTER_ROOT_USER="${MASTER_ROOT_USER:-root}"
EOF
    DB_FLAVOR="${DB_FLAVOR:-mysql}"
    # Credentials should be allowed to be mounted as files to avoid sensitive data
    # in the environment variables
    password_file="$(get_env_var_value ROOT_PASSWORD_FILE)"
    if [[ -f "${password_file:-}" ]]; then
        cat <<"EOF"
    DB_ROOT_PASSWORD_FILE="$(get_env_var_value ROOT_PASSWORD_FILE)"
    export DB_ROOT_PASSWORD="$(< "${DB_ROOT_PASSWORD_FILE}")"
EOF
    else
        cat <<"EOF"
    DB_ROOT_PASSWORD="$(get_env_var_value ROOT_PASSWORD)"
    export DB_ROOT_PASSWORD="${DB_ROOT_PASSWORD:-}"
EOF
    fi
    password_file="$(get_env_var_value PASSWORD_FILE)"
    if [[ -f "${password_file:-}" ]]; then
        cat <<"EOF"
    DB_PASSWORD_FILE="$(get_env_var_value PASSWORD_FILE)"
    export DB_PASSWORD="$(< "${DB_PASSWORD_FILE}")"
EOF
    else
        cat <<"EOF"
    DB_PASSWORD="$(get_env_var_value PASSWORD)"
    export DB_PASSWORD="${DB_PASSWORD:-}"
EOF
    fi
    password_file="$(get_env_var_value REPLICATION_PASSWORD_FILE)"
    if [[ -f "${password_file:-}" ]]; then
        cat <<"EOF"
    DB_REPLICATION_PASSWORD_FILE="$(get_env_var_value REPLICATION_PASSWORD_FILE)"
    export DB_REPLICATION_PASSWORD="$(< "${DB_REPLICATION_PASSWORD_FILE}")"
EOF
    else
        cat <<"EOF"
    DB_REPLICATION_PASSWORD="$(get_env_var_value REPLICATION_PASSWORD)"
    export DB_REPLICATION_PASSWORD="${DB_REPLICATION_PASSWORD:-}"
EOF
    fi
    password_file="$(get_env_var_value MASTER_ROOT_PASSWORD_FILE)"
    if [[ -f "${password_file:-}" ]]; then
        cat <<"EOF"
    DB_MASTER_ROOT_PASSWORD_FILE="$(get_env_var_value MASTER_ROOT_PASSWORD_FILE)"
    export DB_MASTER_ROOT_PASSWORD="$(< "${DB_MASTER_ROOT_PASSWORD_FILE}")"
EOF
    else
        cat <<"EOF"
    DB_MASTER_ROOT_PASSWORD="$(get_env_var_value MASTER_ROOT_PASSWORD)"
    export DB_MASTER_ROOT_PASSWORD="${DB_MASTER_ROOT_PASSWORD:-}"
EOF
    fi
}
