#!/bin/bash
set -e
source /build/buildconfig
set -x
${yum_install:?} make gcc gcc-c++ autoconf bison cmake bzip2 expect bc \
    libaio-devel ncurses-devel

mkdir -p /opt/src

# #############################################################################
#     boost sourcecode
# #############################################################################
src_url=https://sourceforge.net/projects/boost/files/boost/${boost_major_version:?}/boost_${boost_version:?}.tar.gz
wget -c -O /opt/src/boost_${boost_version:?}.tar.gz --no-check-certificate $src_url
tar -zxf /opt/src/boost_${boost_version:?}.tar.gz -C /opt/src/

# #############################################################################
#     jemalloc
# #############################################################################

src_url=https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version:?}/jemalloc-$jemalloc_version.tar.bz2
wget -c -O /opt/src/jemalloc-$jemalloc_version.tar.bz2 --no-check-certificate $src_url
tar -xf /opt/src/jemalloc-$jemalloc_version.tar.bz2 -C /opt/src/
cd /opt/src/jemalloc-$jemalloc_version && ./configure && make && make install && ldconfig
# #############################################################################
#     mysql configuration
# #############################################################################
HostIP=`python /build/get_local_ip.py`
b=`echo ${HostIP:?}|cut -d\. -f2`
c=`echo ${HostIP:?}|cut -d\. -f3`
d=`echo ${HostIP:?}|cut -d\. -f4`
pt=`echo ${MysqlPort:?} % 256 | bc`
# shellcheck disable=SC2034
server_id=`expr $b \* 256 \* 256 \* 256 + $c \* 256 \* 256 + $d \* 256 + $pt`
#create group and user
groupadd ${mysql_user:?} && useradd -g $mysql_user  -M -s /sbin/nologin $mysql_user
# create dir
MysqlOptPath=/u01/mybase/my$MysqlPort/mysql/${mysql_5_7_version:?}
MysqlDataPath="${MysqlOptPath:?}/data"
MysqlLogPath="$MysqlOptPath/log"
MysqlConfigPath="$MysqlOptPath/etc"
MysqlTmpPath="$MysqlOptPath/tmp"
MysqlRunPath="$MysqlOptPath/run"
for path in ${MysqlLogPath:?} ${MysqlConfigPath:?} ${MysqlDataPath:?} ${MysqlTmpPath:?} ${MysqlRunPath:?};do
    [ -d $path ] && rm -rf $path
    mkdir -p $path && chmod 755 $path && chown -R $mysql_user:$mysql_user $path
done
