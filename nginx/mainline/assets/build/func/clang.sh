#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-10-22 17:24:28
 # @LastEditors: cnak47
 # @LastEditTime: 2019-10-22 17:42:29
# @Description:
###
# shellcheck disable=SC1091
source /opt/ak47/base/liblog.sh

install_clang8() {
    info " Install clang 8 ..... "
    echo -e 'deb http://apt.llvm.org/stretch/ llvm-toolchain-stretch-8 main\ndeb-src http://apt.llvm.org/stretch/ llvm-toolchain-stretch-8 main\n' >>/etc/apt/sources.list
    aptitude install clang-8 clang-tools-8 clang-format-8
    aptitude install libc++-8-dev libclang-8-dev libc++abi-8-dev
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-8 100
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-8 100
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-8 100
    update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-8 100

}

uninstall_clang8() {
    info " Uninstall clang ..... "
    apt-get purge --auto-remove clang
}
