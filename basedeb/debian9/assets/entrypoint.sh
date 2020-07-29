#!/bin/bash
### 
# @Author: cnak47
 # @Date: 2018-11-03 21:27:35
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 11:29:10
 # @Description: 
 ###

# shellcheck disable=SC1091
set -e
source /opt/ak47/base/liblog.sh
info "start ......"
exec tini -- "$@"
