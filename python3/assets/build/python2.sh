#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-11-21 14:21:58
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 16:06:50
# @Description:
###

# shellcheck disable=SC1091
set -e
source /assets/buildconfig
source opt/ak47/base/liblog.sh
source /opt/ak47/base/libvalidations.sh
source opt/ak47/base/libbase.sh

BuildPythonDeps='dpkg-dev file libbz2-dev libc6-dev libexpat1-dev libffi-dev libdb-dev '
BuildPythonDeps=$BuildPythonDeps'libgdbm-dev liblzma-dev libncursesw5-dev libreadline-dev '
BuildPythonDeps=$BuildPythonDeps'libsqlite3-dev libssl-dev tcl-dev tk-dev xz-utils '
# shellcheck disable=SC2086
apt-get update && ${apt_install:?} $BuildPythonDeps && rm -rf /var/lib/apt/lists/*

src_url="https://www.python.org/ftp/python/${python2_version:?%%[a-z]*}/Python-$python2_version.tar.xz"
download_and_extract "$src_url" "${build_src:?}/python2" "$build_src" "1" python2.tar.xz
src_url="https://www.python.org/ftp/python/${python2_version%%[a-z]*}/Python-$python2_version.tar.xz.asc"
download_and_extract "$src_url" "${build_src:?}/python2" "$build_src" "1" python2.tar.xz.asc

gpg_key='C01E1CAD5EA2C4F0B8E3571504C367C218ADD4FF'
if verify_signature $gpg_key; then
    gpg --batch --verify "${build_src:?}"/python2.tar.xz.asc "${build_src:?}"/python2.tar.xz &&
        { command -v gpgconf >/dev/null && gpgconf --kill all || :; } &&
        rm -rf "$GNUPGHOME" "${build_src:?}"/python2.tar.xz.asc
else
    error "python2 verify_signature failure !!!!"
fi
mkdir -p "${build_src:?}"/python2
tar -xJC "${build_src:?}"/python2 --strip-components=1 -f "${build_src:?}"/python2.tar.xz &&
    rm "${build_src:?}"/python2.tar.xz
cd "${build_src:?}"/python2
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
export LDFLAGS="-L${sharelib_install_dir:?}/lib/ -L${ssl_install_dir:?}/lib/"
export CPPFLAGS="-I${sharelib_install_dir:?}/include -I${ssl_install_dir:?}/include/openssl"
export LIBRARY_PATH=${sharelib_install_dir:?}/lib:${ssl_install_dir:?}/lib:$LIBRARY_PATH \
    PKG_CONFIG_PATH=${ssl_install_dir:?}/lib/pkgconfig:$PKG_CONFIG_PATH
CXX="/usr/bin/g++" \
    ./configure \
    --prefix="${python2_install_dir:?}" \
    --build="$gnuArch" \
    --enable-shared \
    --enable-unicode=ucs4
make -j "$(nproc)"
make install
# make some useful symlinks that are expected to exist
ln -s -t /usr/local/bin "$python2_install_dir"/bin/python2
ln -s -t /usr/local/bin "$python2_install_dir"/bin/python2-config

ln -s -t /usr/local/lib "$python2_install_dir"/lib/libpython2*
ln -s -t /usr/local/lib "$python2_install_dir"/lib/python2.7
[ ! -d /usr/local/lib/pkgconfig ] && mkdir -p /usr/local/lib/pkgconfig
ln -s -t /usr/local/lib/pkgconfig "$python2_install_dir"/lib/pkgconfig/*

ln -s -t /usr/local/include "$python2_install_dir"/include/python2.7

ldconfig

# pip install
wget -O /usr/src/get-pip.py 'https://bootstrap.pypa.io/get-pip.py'
cd /usr/src
python2 get-pip.py \
    --disable-pip-version-check \
    --no-cache-dir

rm -rf /usr/src/python2 && rm -rf get-pip.py
ln -s "$python2_install_dir"/bin/pip2 /usr/local/bin/pip2
ln -s "$python2_install_dir"/bin/pip2.7 /usr/local/bin/pip2.7
ln -s "$python2_install_dir"/bin/easy_install-2.7 /usr/local/bin/easy_install-2.7
python2 --version && pip2 --version
# test zlib ssl version
# python2 -c "import ssl; print ssl.OPENSSL_VERSION"
# python2 -c "import zlib; print zlib.ZLIB_VERSION"
[ -f /etc/pip.conf ] && rm -rf /etc/pip.conf
cp /assets/build/pip.conf /etc/pip.conf && pip2 list

find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests \) \) \
    -o \
    \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' +
