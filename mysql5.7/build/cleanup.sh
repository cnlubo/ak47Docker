#!/bin/bash
set -ex
yum remove -y make gcc gcc-c++ autoconf cmake bzip2 expect bc \
    && yum autoremove -y \
    && yum clean all \
    && rm -rf /etc/ld.so.cache \
    && rm -rf /var/cache/yum/* \
    && rm -f /var/log/yum.log \
    && rm -rf /tmp/* /var/tmp/* /build /opt/src
