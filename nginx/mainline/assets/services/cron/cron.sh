#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-09-16 21:59:56
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-18 17:27:31
 # @Description: 
 ###

set -e
# shellcheck disable=SC1091
source /assets/build/buildconfig
set -x

apt-get update && ${apt_install:?} cron
chmod 600 /etc/crontab
cp /assets/services/supervisor/conf.d/crond.conf /etc/supervisor/conf.d/crond.conf
## Remove useless cron entries.
# Checks for lost+found and scans for mtab.
rm -f /etc/cron.daily/standard
rm -f /etc/cron.daily/upstart
rm -f /etc/cron.daily/dpkg
rm -f /etc/cron.daily/password
rm -f /etc/cron.daily/passwd
rm -f /etc/cron.weekly/fstrim
