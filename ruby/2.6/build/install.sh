#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-09-16 14:57:11
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 16:52:51
# @Description:
###

set -e
# shellcheck disable=SC1091
source /build/buildconfig
[[ ${debug:?} == true ]] && set -x
apt-get update
BaseDeps='libyaml-dev '
if [ -n "$BaseDeps" ]; then
    # shellcheck disable=SC2086
    ${apt_install:?} $BaseDeps
fi
buildDeps='autoconf bison dpkg-dev gcc g++ libbz2-dev libgdbm-dev '
buildDeps=$buildDeps'libglib2.0-dev libncurses-dev '
buildDeps=$buildDeps'libxml2-dev libxslt-dev make ruby wget xz-utils '
# shellcheck disable=SC2086
savedAptMark="$(apt-mark showmanual)" &&
    ${apt_install:?} $buildDeps

# jemalloc
mkdir -p /opt/src
src_url=https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version:?}/jemalloc-$jemalloc_version.tar.bz2
wget -c -O /opt/src/jemalloc-"$jemalloc_version".tar.bz2 --no-check-certificate "$src_url"
tar jxf /opt/src/jemalloc-"$jemalloc_version".tar.bz2 -C /opt/src/
cd /opt/src/jemalloc-"$jemalloc_version"
./configure && make -j "$(nproc)" && make install && cd / && rm -rf /usr/local/share/doc/*
ldconfig -v

# skip installing gem documentation
mkdir -p /usr/local/etc
{
    echo 'install: --no-document'
    echo 'update: --no-document'
} >>/usr/local/etc/gemrc

# some of ruby's build scripts are written in ruby
# we purge system ruby later to make sure our final image uses what we just built

mkdir -p /opt/src/ruby
# https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.4.tar.gz
src_url=https://cache.ruby-lang.org/pub/ruby/${ruby_major:?}/ruby-${ruby_version:?}.tar.xz
wget -c -O /opt/src/ruby.tar.xz --no-check-certificate "$src_url"
cd /opt/src
echo "${ruby_download_sha256:?} *ruby.tar.xz" | sha256sum -c -
tar -xJf /opt/src/ruby.tar.xz -C /opt/src/ruby --strip-components=1
cd /opt/src/ruby

# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
{
    echo '#define ENABLE_PATH_CHECK 0'
    echo
    cat file.c
} >file.c.new

mv file.c.new file.c
autoconf
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
# --prefix=${ruby_install_dir:?} \
export LDFLAGS="-L/${sharelib_install_dir:?}/lib/ -L/${ssl_install_dir:?}/lib/"
export CPPFLAGS="-I/${sharelib_install_dir:?}/include -I/${ssl_install_dir:?}/include/openssl"
export LIBRARY_PATH=${sharelib_install_dir:?}/lib:${ssl_install_dir:?}/lib:$LIBRARY_PATH \
    PKG_CONFIG_PATH=${ssl_install_dir:?}/lib/pkgconfig:$PKG_CONFIG_PATH
./configure \
    --build="$gnuArch" \
    --with-jemalloc \
    --disable-install-doc \
    --enable-shared
make -j "$(nproc)" && make install
cp /build/test.sh /usr/local/bin/test_ruby.sh
chmod +x /usr/local/bin/test_ruby.sh
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

cd / && rm -r /opt/src/ruby
gem update --system "${rubygems_version:?}"
gem install bundler --version "${bundler_version:?}" --force && rm -r /root/.gem/

# adjust permissions of a few directories for running "gem install" as an arbitrary user
mkdir -p "$GEM_HOME" && chmod 777 "$GEM_HOME"
# (BUNDLE_PATH = GEM_HOME, no need to mkdir/chown both)
