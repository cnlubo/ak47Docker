#!/bin/bash
set -e
source /build/buildconfig
set -x
#######################################################################
# install mysql
#######################################################################
src_url=http://cdn.mysql.com//Downloads/MySQL-5.7/mysql-${mysql_5_7_version:?}.tar.gz
wget -c -O /opt/src/mysql-${mysql_5_7_version:?}.tar.gz --no-check-certificate $src_url
tar -zxf /opt/src/mysql-${mysql_5_7_version:?}.tar.gz -C /opt/src/
cd /opt/src/mysql-$mysql_5_7_version
MysqlBasePath=/u01/mysql/$mysql_5_7_version
# cmake -DCMAKE_INSTALL_PREFIX=$MysqlBasePath \
#     -DDEFAULT_CHARSET=utf8mb4 \
#     -DDEFAULT_COLLATION=utf8mb4_general_ci \
#     -DWITH_ARCHIVE_STORAGE_ENGINE=1 \
#     -DWITH_BLACKHOLE_STORAGE_ENGINE=1 \
#     -DWITH_INNOBASE_STORAGE_ENGINE=1 \
#     -DENABLED_LOCAL_INFILE=1 \
#     -DWITH_BOOST=/opt/src/boost_${boost_version:?} \
#     -DBUILD_CONFIG=mysql_release \
#     -DWITH_INNODB_MEMCACHED=ON \
#     -DWITH_MYSQLD_LDFLAGS='-ljemalloc'
#make && make install
cmake -DCMAKE_INSTALL_PREFIX=$MysqlBasePath \
    -DDEFAULT_CHARSET=utf8mb4 \
    -DDEFAULT_COLLATION=utf8mb4_general_ci \
    -DENABLED_LOCAL_INFILE=1 \
    -DWITH_BOOST=/opt/src/boost_${boost_version:?} \
    -DBUILD_CONFIG=mysql_release \
    -DWITH_INNODB_MEMCACHED=ON \
    -DWITH_MYSQLD_LDFLAGS='-ljemalloc'
make -j "$(nproc)" && make install
