#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-09-16 21:59:56
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-18 17:29:20
 # @Description: 
 ###

set -e
# shellcheck disable=SC1091
source /assets/build/buildconfig
# shellcheck disable=SC1091
source /opt/ak47/base/libbase.sh
set -x
# installing syslog-ng, with workaround https://bugs.launchpad.net/ubuntu/+source/syslog-ng/+bug/1242173
#apt-get update && ${apt_install:?} syslog-ng syslog-ng-core logrotate
GNUPGHOME="$(mktemp -d)"
export GNUPGHOME
wget -qO - http://download.opensuse.org/repositories/home:/laszlo_budai:/syslog-ng/Debian_9.0/Release.key | apt-key add -
rm -rf "$GNUPGHOME" && apt-key list
echo 'deb http://download.opensuse.org/repositories/home:/laszlo_budai:/syslog-ng/Debian_9.0 ./' >  \
    /etc/apt/sources.list.d/syslog-ng-obs.list
apt-get update && ${apt_install:?} syslog-ng-core logrotate
# can't access /proc/kmsg. https://groups.google.com/forum/#!topic/docker-user/446yoB0Vx6w
cp /etc/syslog-ng/syslog-ng.conf /etc/syslog-ng/syslog-ng.conf_bak
sed -i -E 's/^(\s*)system\(\);/\1unix-stream("\/dev\/log");/' /etc/syslog-ng/syslog-ng.conf
cat > /tmp/tt.conf <<EOF

# stdout for docker
destination d_stdout { ##SYSLOG_OUTPUT_MODE_DEV_STDOUT##("/dev/stdout"); };
EOF
sed -i '/\/var\/log\/ppp.log/r /tmp/tt.conf' /etc/syslog-ng/syslog-ng.conf
rm -rf /tmp/tt.conf
sed -i '/destination(d_syslog)/s/^/#&/' /etc/syslog-ng/syslog-ng.conf
sed -i '/destination(d_syslog)/a\log { source(s_src); filter(f_syslog3); destination(d_syslog); destination(d_stdout); };\' /etc/syslog-ng/syslog-ng.conf
# determine output mode on /dev/stdout because of the issue documented at
#  https://github.com/phusion/baseimage-docker/issues/468
if [ -p /dev/stdout ]; then
  sed -i 's/##SYSLOG_OUTPUT_MODE_DEV_STDOUT##/pipe/' /etc/syslog-ng/syslog-ng.conf
else
  sed -i 's/##SYSLOG_OUTPUT_MODE_DEV_STDOUT##/file/' /etc/syslog-ng/syslog-ng.conf
fi
touch /var/log/syslog
chmod u=rw,g=r,o= /var/log/syslog
cp /assets/services/syslog-ng/nginx.conf /etc/syslog-ng/conf.d/nginx.conf
update_template '/etc/syslog-ng/conf.d/nginx.conf' NGINX_LOG_DIR
cp /assets/services/syslog-ng/logrotate_syslogng /etc/logrotate.d/syslog-ng
cp /assets/services/supervisor/conf.d/syslog-ng.conf /etc/supervisor/conf.d/syslog-ng.conf
