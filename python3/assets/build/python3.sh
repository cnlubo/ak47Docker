#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-11-23 11:27:37
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 15:29:27
# @Description:
###

# shellcheck disable=SC1091
set -e
source /assets/buildconfig
source opt/ak47/base/liblog.sh
source /opt/ak47/base/libvalidations.sh
source opt/ak47/base/libbase.sh
[[ ${debug:?} == true ]] && set -x
BuildPythonDeps='dpkg-dev libbz2-dev libc6-dev libffi-dev '
BuildPythonDeps=$BuildPythonDeps'libgdbm-dev liblzma-dev libncursesw5-dev libreadline-dev '
BuildPythonDeps=$BuildPythonDeps'libsqlite3-dev libssl-dev tcl-dev tk-dev uuid-dev '
# shellcheck disable=SC2086
apt-get update && ${apt_install:?} $BuildPythonDeps && rm -rf /var/lib/apt/lists/*
src_url="https://www.python.org/ftp/python/${python3_version:?%%[a-z]*}/Python-$python3_version.tar.xz"
download_and_extract "$src_url" "${build_src:?}/python" "$build_src" "1" python.tar.xz
src_url="https://www.python.org/ftp/python/${python3_version%%[a-z]*}/Python-$python3_version.tar.xz.asc"
download_and_extract "$src_url" "${build_src:?}/python" "$build_src" "1" python.tar.xz.asc
gpg_key='0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D'

if verify_signature $gpg_key; then

    gpg --batch --verify "${build_src:?}"/python.tar.xz.asc "${build_src:?}"/python.tar.xz &&
        { command -v gpgconf >/dev/null && gpgconf --kill all || :; } &&
        rm -rf "$GNUPGHOME" "${build_src:?}"/python.tar.xz.asc
else
    error "python verify_signature failure !!!!"
fi
mkdir -p "${build_src:?}"/python
tar -xJC "${build_src:?}"/python --strip-components=1 -f "${build_src:?}"/python.tar.xz &&
    rm "${build_src:?}"/python.tar.xz

cd "${build_src:?}"/python
gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"
export LDFLAGS="-L${sharelib_install_dir:?}/lib/ -L${ssl_install_dir:?}/lib/"
export CPPFLAGS="-I${sharelib_install_dir:?}/include -I${ssl_install_dir:?}/include/openssl"
export LIBRARY_PATH=${sharelib_install_dir:?}/lib:${ssl_install_dir:?}/lib:$LIBRARY_PATH \
    PKG_CONFIG_PATH=${ssl_install_dir:?}/lib/pkgconfig:$PKG_CONFIG_PATH
CXX="/usr/bin/g++" \
    ./configure \
    --prefix="${python3_install_dir:?}" \
    --build="$gnuArch" \
    --enable-optimizations \
    --enable-loadable-sqlite-extensions \
    --enable-shared \
    --with-system-expat \
    --with-system-ffi \
    --without-ensurepip &&
    make -j "$(nproc)"
# setting PROFILE_TASK makes "--enable-optimizations" reasonable: https://bugs.python.org/issue36044 / https://github.com/docker-library/python/issues/160#issuecomment-509426916
PROFILE_TASK='-m test.regrtest --pgo
			test_array
			test_base64
			test_binascii
			test_binhex
			test_binop
			test_bytes
			test_c_locale_coercion
			test_class
			test_cmath
			test_codecs
			test_compile
			test_complex
			test_csv
			test_decimal
			test_dict
			test_float
			test_fstring
			test_hashlib
			test_io
			test_iter
			test_json
			test_long
			test_math
			test_memoryview
			test_pickle
			test_re
			test_set
			test_slice
			test_struct
			test_threading
			test_time
			test_traceback
			test_unicode' &&
    make install && ldconfig
# make some useful symlinks that are expected to exist
ln -s -t /usr/local/bin "$python3_install_dir"/bin/python3
ln -s -t /usr/local/bin "$python3_install_dir"/bin/python3-config
ln -s -t /usr/local/bin "$python3_install_dir"/bin/python3.7m
ln -s -t /usr/local/bin "$python3_install_dir"/bin/python3.7m-config
ln -s -t /usr/local/bin "$python3_install_dir"/bin/pyvenv
ln -s -t /usr/local/bin "$python3_install_dir"/bin/idle3
ln -s -t /usr/local/bin "$python3_install_dir"/bin/pydoc3
ln -s -t /usr/local/bin "$python3_install_dir"/bin/2to3

ln -s -t /usr/local/lib "$python3_install_dir"/lib/libpython3*
ln -s -t /usr/local/lib "$python3_install_dir"/lib/python3.7
[ ! -d /usr/local/lib/pkgconfig ] && mkdir -p /usr/local/lib/pkgconfig
ln -s -t /usr/local/lib/pkgconfig "$python3_install_dir"/lib/pkgconfig/*

ln -s -t /usr/local/include "$python3_install_dir"/include/python3.7m
ldconfig
# make python3 as default python
ln -s /usr/local/bin/idle3 /usr/local/bin/idle
ln -s /usr/local/bin/pydoc3 /usr/local/bin/pydoc
ln -s /usr/local/bin/python3 /usr/local/bin/python
ln -s /usr/local/bin/python3-config /usr/local/bin/python-config

# pip install
wget -O /usr/src/get-pip.py 'https://bootstrap.pypa.io/get-pip.py'
cd /usr/src
python3 get-pip.py \
    --disable-pip-version-check \
    --no-cache-dir

rm -rf /usr/src/python && rm -rf get-pip.py
ln -s "$python3_install_dir"/bin/pip3 /usr/local/bin/pip3
ln -s "$python3_install_dir"/bin/pip3.7 /usr/local/bin/pip3.7
ln -s "$python3_install_dir"/bin/easy_install-3.7 /usr/local/bin/easy_install-3.7
ln -s /usr/local/bin/pip3 /usr/local/bin/pip
python3 --version && pip3 --version
# python3 -c "import ssl; print(ssl.OPENSSL_VERSION)"
# python3 -c "import zlib; print(zlib.ZLIB_VERSION)"
[ -f /etc/pip.conf ] && rm -rf /etc/pip.conf
cp /assets/build/pip.conf /etc/pip.conf
# && pip list

find /usr/local -depth \
    \( \
    \( -type d -a \( -name test -o -name tests \) \) \
    -o \
    \( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
    \) -exec rm -rf '{}' +
