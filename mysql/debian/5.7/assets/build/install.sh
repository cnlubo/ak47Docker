#!/bin/bash
# @Author: cnak47
# @Date: 2019-12-17 10:37:56
# @LastEditors: cnak47
# @LastEditTime: 2019-12-24 17:32:56
# @Description:
# #
set -e
# shellcheck disable=SC1091
source /build/buildconfig
# shellcheck disable=SC1091
source opt/ak47/base/liblog.sh
# shellcheck disable=SC1091
source opt/ak47/base/libbase.sh
# shellcheck disable=SC1091
source /opt/ak47/base/libvalidations.sh
[[ ${debug:?} == true ]] && set -x

apt-get update
BaseDeps='libao-dev '
if [ -n "$BaseDeps" ]; then
    # shellcheck disable=SC2086
    ${apt_install:?} $BaseDeps
fi

BuildDeps='ca-certificates wget '
if ! command -v gpg >/dev/null; then
    BuildDeps=${BuildDeps}'gnupg dirmngr '
fi
# shellcheck disable=SC2086
savedAptMark="$(apt-mark showmanual)" &&
    ${apt_install:?} $BuildDeps
# create group and user
groupadd "${mysql_user:?}" && useradd -g "$mysql_user" -M -s /sbin/nologin "$mysql_user"

# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'
if verify_signature $key; then
    gpg --batch --export "$key" >/etc/apt/trusted.gpg.d/mysql.gpg &&
        command -v gpgconf >/dev/null && gpgconf --kill all &&
        rm -rf "$GNUPGHOME" &&
        apt-key list
fi

echo "deb http://repo.mysql.com/apt/debian/ stretch mysql-${mysql_major:?}" >/etc/apt/sources.list.d/mysql.list

# the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# also, we set debconf keys to make APT a little quieter
{
    echo mysql-community-server mysql-community-server/data-dir select ''
    echo mysql-community-server mysql-community-server/root-pass password ''
    echo mysql-community-server mysql-community-server/re-root-pass password ''
    echo mysql-community-server mysql-community-server/remove-test-db select false
} | debconf-set-selections

apt-get update && apt-get install -y mysql-server="${mysql_version:?}"
rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld &&
    chown -R "$mysql_user":"$mysql_user" /var/lib/mysql /var/run/mysqld
# ensure that /var/run/mysqld (used for socket and lock files) 
# is writable regardless of the UID our mysqld instance ends up having at runtime
chmod 777 /var/run/mysqld

# comment out a few problematic configuration values
# find /etc/mysql/ -name '*.cnf' -print0 |
#     xargs -0 grep -lZE '^(bind-address|log)' |
#     xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/'

# don't reverse lookup hostnames, they are usually another container
echo -e '[mysqld]\nskip-host-cache\nskip-name-resolve' >/etc/mysql/conf.d/docker.cnf
# 创建相关目录




apt-mark auto '.*' >/dev/null
find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' |
    awk '/=>/ { print $(NF-1) }' |
    sort -u |
    xargs -r dpkg-query --search |
    cut -d: -f1 |
    sort -u |
    xargs -r apt-mark manual
# shellcheck disable=SC2086
[ -z "${savedAptMark:?}" ] || apt-mark manual $savedAptMark

apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
