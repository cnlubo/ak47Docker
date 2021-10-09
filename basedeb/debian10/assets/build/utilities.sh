#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-11-23 11:32:38
 # @LastEditors: Please set LastEditors
 # @LastEditTime: 2021-06-24 16:22:47
# @Description:
###

# shellcheck disable=SC1091
set -e
source /assets/buildconfig
source opt/ak47/base/liblog.sh
source opt/ak47/base/libbase.sh
source /opt/ak47/base/libvalidations.sh
[[ ${debug:?} == true ]] && set -x

BaseDeps='less netbase procps tree sudo net-tools curl'
apt-get update
if [ -n "$BaseDeps" ]; then
    # shellcheck disable=SC2086
    ${apt_install:?} $BaseDeps
fi
BuildDeps='autoconf automake apt-transport-https ca-certificates bzip2 git-core xz-utils gcc g++ make libtool patch wget libperl-dev '
if ! command -v gpg >/dev/null; then
    BuildDeps=${BuildDeps}'gnupg dirmngr '
fi
# shellcheck disable=SC2086
savedAptMark="$(apt-mark showmanual)" &&
    ${apt_install:?} $BuildDeps

mkdir -p "${build_src:?}"
#
if [ "${ssl_version:?}" -eq 0 ]; then
    # zlib
    src_url=http://zlib.net/zlib-${zlib_version:?}.tar.gz
    download_and_extract "$src_url" "$build_src/zlib-${zlib_version:?}" "$build_src"
    cd "$build_src"/zlib-"${zlib_version:?}"
    ./configure --prefix="${sharelib_dir:?}" -shared
    make && make install
    if [ -f "${sharelib_dir:?}"/lib/libz.a ]; then
        info "[zlib-${zlib_version:?} installed successful !!!]"
        [ -f /etc/ld.so.conf.d/sharelib.conf ] && rm -rf /etc/ld.so.conf.d/sharelib.conf
        echo "${sharelib_dir:?}/lib" >/etc/ld.so.conf.d/sharelib.conf
        ldconfig
    else
        error "[install zlib-${zlib_version:?} failed !!!]"
    fi
    ##############################################################################
    # openssl
    # https://www.openssl.org/
    ##############################################################################

    src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz

    download_and_extract "$src_url" "$build_src/openssl-${openssl_version:?}" "$build_src"
    #1.1.1 版本默认启用tls1.3
    cd "$build_src"/openssl-"${openssl_version:?}"
    ./Configure --prefix="${ssl_install_dir:?}" \
        shared zlib \
        --with-zlib-include="${sharelib_dir:?}"/include \
        --with-zlib-lib="${sharelib_dir:?}"/lib \
        enable-crypto-mdebug enable-crypto-mdebug-backtrace \
        linux-x86_64

    make -j "$(nproc)" && make install_sw && cd /
    mkdir -p "${ssl_install_dir:?}"/ssl/
    curl -o "${ssl_install_dir:?}"/ssl/cert.pem https://curl.haxx.se/ca/cacert.pem

    if [ -f "${ssl_install_dir:?}"/lib/libcrypto.a ]; then
        info "[openssl-${openssl_version:?} installed successful !!!]"
        echo "${ssl_install_dir:?}/lib" >/etc/ld.so.conf.d/openssl.conf
        ldconfig
    else
        error "[install openssl-${openssl_version:?} failed !!!]"
    fi
    ln -s -t /usr/local/bin "${ssl_install_dir:?}"/bin/*
# test tls1_3
# openssl ciphers -v | awk '{print $2}' | sort | uniq
# apt-get update
# apt-get install bsdmainutils
# openssl ciphers -V tls1_3 | column -t
# openssl ciphers -s -tls1_3
# openssl s_client nodeedge.com:443
else
    ##############################################################################
    # libreSSL
    # https://www.libressl.org/releases.html
    # https://github.com/libressl-portable/portable
    ##############################################################################
    src_url=https://github.com/libressl-portable/portable/archive/v${libreSSL_version:?}.tar.gz
    download_and_extract "$src_url" "$build_src/libreSSL-${libreSSL_version:?}" "$build_src"
    cd "$build_src"/libreSSL-"${libreSSL_version:?}"
    ./autogen.sh
    ./configure --prefix="${ssl_install_dir:?}" --enable-nc
    make -j "$(nproc)"
    make install
    if [ -f "${ssl_install_dir:?}"/lib/libcrypto.a ]; then
        info "[ libreSSL-${libreSSL_version:?} installed successful !!! ]"
        echo "${ssl_install_dir:?}/lib" >/etc/ld.so.conf.d/libressl.conf
        ldconfig
        rm -rf "${ssl_install_dir:?}"/share/man
    else
        error "[ install libreSSL-${libreSSL_version:?} failed !!! ]"
    fi
    ln -s -t /usr/local/bin "${ssl_install_dir:?}"/bin/*
fi
##############################################################################
# gosu
# https://github.com/tianon/gosu/releases
##############################################################################
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
wget -O /usr/local/bin/gosu \
    "https://github.com/tianon/gosu/releases/download/${gosu_version:?}/gosu-$dpkgArch"
wget -O /usr/local/bin/gosu.asc \
    "https://github.com/tianon/gosu/releases/download/$gosu_version/gosu-$dpkgArch.asc"

key='B42F6819007F00F88E364FD4036A9C25BF357DD4'

if verify_signature $key; then
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu &&
        gpgconf --kill all &&
        rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc
    chmod +x /usr/local/bin/gosu
    gosu --version
    gosu nobody true
else
    error "gosu verify_signature failure !!!!"
fi

##############################################################################
# grab tini for signal processing and zombie killing
# https://github.com/krallin/tini/releases
##############################################################################
wget -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v${tini_version:?}/tini-$dpkgArch"
wget -O /usr/local/bin/tini.asc "https://github.com/krallin/tini/releases/download/v$tini_version/tini-$dpkgArch.asc"

key='6380DC428747F6C393FEACA59A84159D7001A4E5'
if verify_signature $key; then
    gpg --batch --verify /usr/local/bin/tini.asc /usr/local/bin/tini &&
        gpgconf --kill all &&
        rm -r "$GNUPGHOME" /usr/local/bin/tini.asc &&
        chmod +x /usr/local/bin/tini &&
        tini -h
else
    error " tini verify_signature failure !!!!"
fi

# zsh
if [ "${disable_zsh:?}" -eq 0 ]; then
    chmod +x /assets/tools/zsh/zsh.sh
    /assets/tools/zsh/zsh.sh || true
fi

##############################################################################
# yq
# https://github.com/mikefarah/yq
# wait-for-port
# https://github.com/bitnami/wait-for-port
# render-template
# https://github.com/bitnami/render-templat
# ini-file
# https://github.com/bitnami/ini-file
##############################################################################

wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${yq_version:?}/yq_linux_amd64" && chmod +x /usr/local/bin/yq


apt-mark auto '.*' >/dev/null

find /usr/local -type f -executable -not \( -name '*tkinter*' \) -exec ldd '{}' ';' |
    awk '/=>/ { print $(NF-1) }' |
    sort -u |
    xargs -r dpkg-query --search |
    cut -d: -f1 |
    sort -u |
    xargs -r apt-mark manual

# shellcheck disable=SC2086
if [ -n "${savedAptMark:?}" ]; then
    apt-mark manual $savedAptMark
fi
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false
