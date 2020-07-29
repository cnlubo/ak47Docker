#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2019-09-14 10:41:21
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-15 10:35:36
 # @Description: 
 ###

set -e
# shellcheck disable=SC1091
source /assets/buildconfig
[[ ${debug:?} == true ]] && set -x

cp /assets/entrypoint.sh /sbin/entrypoint.sh
chmod 755 /sbin/entrypoint.sh
