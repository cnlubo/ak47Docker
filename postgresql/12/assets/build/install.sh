#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-11-03 21:29:23
# @LastEditors: cnak47
# @LastEditTime: 2020-08-02 18:34:01
# @Description:
###

set -e
# shellcheck disable=SC1091
source /build/buildconfig
# shellcheck disable=SC1091
source opt/ak47/base/liblog.sh
# shellcheck disable=SC1091
source /opt/ak47/base/libvalidations.sh
[[ ${debug:?} == true ]] && set -x
apt-get update
BaseDeps='acl '
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
apt-mark auto '.*' >/dev/null
#############################################################################
# postgresql install
#############################################################################
# key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'

# if verify_signature $key; then

#     gpg --batch --export "$key" >/etc/apt/trusted.gpg.d/postgres.gpg &&
#         command -v gpgconf >/dev/null && gpgconf --kill all &&
#         rm -rf "$GNUPGHOME" &&
#         apt-key list
# fi
# echo 'deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main' ${PG_VERSION:?} \
#     >/etc/apt/sources.list.d/pgdg.list
# apt-get update && ${apt_install:?} postgresql-common

# import GPG key used for signing packages
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
# add PostgreSQL repository
echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main $PG_VERSION" | tee /etc/apt/sources.list.d/pgdg.list

apt update && ${apt_install:?} postgresql-common
sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf
${apt_install:?} postgresql-"$PG_VERSION"
# ${apt_install:?} postgresql-$PG_VERSION=${pg_deb_version:?} postgresql-contrib-$PG_VERSION

mkdir -p PG_DATADIR="${PG_HOME}/${PG_VERSION}"/main
mkdir -p /etc/postgresql/"${PG_VERSION}"/main
ln -sf "${PG_DATADIR}"/postgresql.conf /etc/postgresql/"${PG_VERSION}"/main/postgresql.conf
ln -sf "${PG_DATADIR}"/pg_hba.conf /etc/postgresql/"${PG_VERSION}"/main/pg_hba.conf
ln -sf "${PG_DATADIR}"/pg_ident.conf /etc/postgresql/"${PG_VERSION}"/main/pg_ident.conf
rm -rf "${PG_HOME}"
[ ! -d "$PG_APP_HOME" ] && mkdir -p "$PG_APP_HOME"
mv /runtime/* "$PG_APP_HOME"/
cp /build/entrypoint.sh /usr/local/bin/entrypoint.sh
chmod 755 /usr/local/bin/entrypoint.sh
ln -s /usr/local/bin/entrypoint.sh / # backwards compat

# # make the sample config easier to munge (and "correct by default")
# mv -v "/usr/share/postgresql/$PG_VERSION/postgresql.conf.sample" /usr/share/postgresql/
# ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_VERSION/"
# sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" \
#     /usr/share/postgresql/postgresql.conf.sample
# # create dir
# mkdir -p /var/run/postgresql
# chown -R $pgsql_user:$pgsql_user /var/run/postgresql
# chmod g+s /var/run/postgresql
# mkdir -p "$PGDATA"
# chown -R postgres:postgres "$PGDATA"
# chmod 777 "$PGDATA"
# # this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)
# cp /build/docker-entrypoint.sh /usr/local/bin/
# ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
# mkdir /docker-entrypoint-initdb.d
# cp /build/scripts/*.sh /docker-entrypoint-initdb.d

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
