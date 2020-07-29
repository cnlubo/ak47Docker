#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-09-16 21:42:25
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-16 21:59:33
# @Description:
###
# shellcheck disable=SC1091
source opt/ak47/base/liblog.sh
info "test ruby openssl version !!!"
ruby -ropenssl -e 'puts OpenSSL::OPENSSL_LIBRARY_VERSION'
info "test ruby zlib version !!!"
ruby -rzlib -e 'puts Zlib::ZLIB_VERSION'
info "test ruby jemalloc !!!"
# test ruby 2.5 jemalloc
# ruby -r rbconfig -e "puts RbConfig::CONFIG['LIBS']"
# test ruby 2.6 jemalloc
ruby -r rbconfig -e "puts RbConfig::CONFIG['MAINLIBS']"
