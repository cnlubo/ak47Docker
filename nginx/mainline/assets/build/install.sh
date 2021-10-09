#!/bin/bash
# shellcheck disable=SC1091
###
# @Author: cnak47
# @Date: 2019-09-16 21:59:56
 # @LastEditors: cnak47
 # @LastEditTime: 2019-11-02 11:26:01
# @Description:
###

set -e
source /assets/build/buildconfig
source /opt/ak47/base/libbase.sh
source /assets/build/func/clang.sh
[[ ${debug:?} == true ]] && set -x
apt-get update
BaseDeps='gettext-base '
if [ -n "$BaseDeps" ]; then
    # shellcheck disable=SC2086
    ${apt_install:?} $BaseDeps
fi

buildDeps='build-essential bzip2 cmake curl ca-certificates git-core '
if [[ "${CLANG:?}" == 'y' ]]; then
    buildDeps=$buildDeps'libatomic-ops-dev make patch pkg-config uuid-dev wget '
else
    buildDeps=$buildDeps'gcc g++ libatomic-ops-dev make patch pkg-config uuid-dev wget '
fi
if [[ "${libressl_switch:?}" == 'y' ]]; then
    buildDeps=$buildDeps'golang '
elif [[ "${boringssl_switch:?}" == 'y' ]]; then
    buildDeps=$buildDeps'golang '
else
    buildDeps=$buildDeps
fi

if ! command -v gpg >/dev/null; then
    buildDeps=${buildDeps}'gnupg dirmngr '
fi
# shellcheck disable=SC2086
savedAptMark="$(apt-mark showmanual)" &&
    ${apt_install:?} $buildDeps
# install clang
if [[ "${CLANG:?}" == 'y' ]]; then
    install_clang8
fi
################################################################################
# build dependency
################################################################################
if [[ "${cloudflare_zlib:?}" == 'y' ]]; then
    # Cloudflare 改版的zlib,仅适用于Nginx/PHP相关的应用,不适合替换系统的zlib
    # https://github.com/cloudflare/zlib.git
    cd "${build_src:?}"
    git clone https://github.com/cloudflare/zlib.git zlib-cf
    cd zlib-cf
    make -f Makefile.in distclean
    ./configure --prefix="${zlibcf_install_dir:?}"
    make -j "$(nproc)" && make install
    if [[ "$(uname -m)" == 'x86_64' ]]; then
        ln -sf "${zlibcf_install_dir:?}"/lib "${zlibcf_install_dir:?}"/lib64
    fi
    ZLIB_RPATH="$zlibcf_install_dir/lib:"
    ZLIB_OPT="-L$zlibcf_install_dir/lib "
    ZLIBINC_OPT="-I$zlibcf_install_dir/include "
# ZLIBCUSTOM_OPT=" --with-zlib=../zlib-cloudflare-${CLOUDFLARE_ZLIBVER}"
else
    ZLIB_RPATH="${sharelib_install_dir:?}/lib:"
    ZLIB_OPT="-L$sharelib_install_dir/lib "
    ZLIBINC_OPT="-I$sharelib_install_dir/include "
fi
# pcre
src_url=https://sourceforge.net/projects/pcre/files/pcre/${pcre_version:?}/pcre-$pcre_version.tar.gz/download
download_and_extract "$src_url" "$build_src/pcre-$pcre_version" "$build_src"
if [[ "${nginx_pcre_dynamic:?}" == 'y' ]]; then
    cd "$build_src"/pcre-"$pcre_version"
    make clean
    ./configure --enable-utf8 --enable-unicode-properties --enable-pcre16 --enable-pcre32 --enable-pcregrep-libz --enable-pcregrep-libbz2 --enable-pcretest-libreadline --enable-jit
    make -j "$(nproc)" && make install
    PCREJITOPT=" --with-pcre-jit"
else
    PCREJITOPT=" --with-pcre=$build_src/pcre-$pcre_version --with-pcre-jit"
fi
PCRE_LD=' -lpcre'

# PCREJITOPT=" --with-pcre-jit"
#       LIBBROTLIENC_OPT='-L/usr/local/lib '
#       LIBBROTLIINC_OPT='-I/usr/local/include '
#     else
#       PCREJITOPT=" --with-pcre=../$PCRELINKDIR --with-pcre-jit"
#     fi

# Nginx SSL
if [[ "${boringssl_switch:?}" == 'y' ]]; then
    info "Compiling BoringSSL..."
    # Download and prepare BoringSSL source
    cd "${build_src:?}"
    git clone --depth 1 https://github.com/google/boringssl.git
    cd boringssl && mkdir -p build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
        -DBUILD_SHARED_LIBS=1 ../
    sed -i 's|tls13_variant_t tls13_variant = tls13_rfc;|tls13_variant_t tls13_variant = tls13_all;|g' "${build_src:?}"/boringssl/ssl/internal.h
    make -j "$(nproc)"
    cd ../
    mkdir -p .openssl/lib && cd .openssl
    ln -s ../include .
    cd ../
    cp build/crypto/libcrypto.a build/ssl/libssl.a .openssl/lib
    cp build/crypto/libcrypto.so build/ssl/libssl.so .openssl/lib
    # Prevent build-error 127 which seems to be caused by the ssl.h file missing
    touch .openssl/include/openssl/ssl.h
    BORINGSSL_LIBOPT="-L${build_src:?}/boringssl/.openssl/lib -lcrypto -lssl "
    BORINGSSL_RPATH="${build_src:?}/boringssl/.openssl/lib:"
    BORINGSSLINC_OPT="-I${build_src}/boringssl/.openssl/include "
else
    # openssl
    src_url=https://www.openssl.org/source/openssl-${openssl_version:?}.tar.gz
    download_and_extract "$src_url" "$build_src/openssl-${openssl_version:?}" "$build_src"
    # openssl patch
    info "Openssl-${openssl_version:?} patch install ..."
    cd "${build_src:?}"
    git clone https://github.com/hakasenyang/openssl-patch.git
    cd openssl-"${openssl_version:?}"
    patch -p1 <../openssl-patch/openssl-equal-"${openssl_version:?}"_ciphers.patch
    patch -p1 <../openssl-patch/openssl-"${openssl_version:?}"-chacha_draft.patch
    openssl_opt="zlib enable-tls1_3 enable-weak-ssl-ciphers enable-ec_nistp_64_gcc_128 -march=native -ljemalloc -Wl,-flto"

fi
# google gperftools
if [[ "${gperftools:?}" == 'y' ]]; then
    info "Install libunwind..."
    cd "${build_src:?}"
    src_url=libunwind_link=https://download.savannah.gnu.org/releases/libunwind/libunwind-${libunwind_version:?}.tar.gz
    download_and_extract "$src_url" "$build_src/libunwind-$libunwind_version" "$build_src"
    cd libunwind-"$libunwind_version"
    ./configure && make -j "$(nproc)" && make install

    info "Install google-perftools..."
    cd "${build_src:?}"
    src_url=https://github.com/gperftools/gperftools/releases/download/gperftools-${gperftools_version:?}/gperftools-${gperftools_version}.tar.gz
    download_and_extract "$src_url" "$build_src/gperftools-$gperftools_version" "$build_src"
    if [[ "${gperftools_tmalloclargepages:?}" == [y] ]]; then
        tcmalloc_pagesize='32'
    else
        tcmalloc_pagesize='8'
    fi
    cd gperftools-"$gperftools_version"
    ./configure --with-tcmalloc-pagesize="$tcmalloc_pagesize"
    make -j "$(nproc)" && make install
else
    # jemalloc
    cd "${build_src:?}"
    src_url=https://github.com/jemalloc/jemalloc/releases/download/${jemalloc_version:?}/jemalloc-$jemalloc_version.tar.bz2
    download_and_extract "$src_url" "$build_src/jemalloc-$jemalloc_version" "$build_src"
    cd jemalloc-"$jemalloc_version"
    ./configure && make -j "$(nproc)"
    cp lib/libjemalloc.so.2 /usr/local/lib
    cp lib/libjemalloc.so /usr/local/lib
    JEMALLOC_LD='-ljemalloc'
fi
ldconfig -v

################################################################################
# additional Nginx modules
################################################################################

# Certificate Transparency (CT)
# info "ngx-ct Download .... "
# cd "${build_src:?}"
# git clone https://github.com/grahamedgecombe/nginx-ct.git

info "headers-more-nginx-module Download .... "
# https://github.com/openresty/headers-more-nginx-module.git
cd /assets/build/src
# git clone --depth 1 https://github.com/openresty/headers-more-nginx-module.git
git clone -b master --depth=1 https://github.com/openresty/headers-more-nginx-module.git headers-more-nginx-module-master

info "ngx_http_substitutions_filter_module Download .... "
# https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
git clone --depth 1 https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git

info "echo-nginx-module Download .... "
git clone --depth 1 https://github.com/openresty/echo-nginx-module.git

info "ngx_http_geoip2_module Download ...."
git clone --depth 1 https://github.com/leev/ngx_http_geoip2_module.git

# Brotli (eustas版本)
info "ngx_brotli Download .... "
git clone https://github.com/eustas/ngx_brotli.git
cd ngx_brotli
git submodule update --init --recursive

info "Nginx HTTP rDNS module Download .... "
cd /assets/build/src
git clone https://github.com/flant/nginx-http-rdns.git nginx-http-rdns

info "testcookie-nginx-module download .... "
cd /assets/build/src
git clone -b master --depth=1 https://github.com/kyprizel/testcookie-nginx-module

info "ginx-length-hiding-filter-module download .... "
cd /assets/build/src
git clone -b master --depth=1 https://github.com/nulab/nginx-length-hiding-filter-module nginx-length-hiding-filter-module

if [[ "$NGINX_NJS" == [yY] ]]; then
    info "nginScript download .... "
    cd /assets/build/src
    git clone --depth=1 https://github.com/nginx/njs
    FLTO_OPT=""
    NGINX_NJSOPT=' --add-dynamic-module=../njs/nginx'
else
    NGINX_NJSOPT=""
    FLTO_OPT=' -flto'

fi
################################################################################
# nginx configure
################################################################################

# nginx_ld_opt="-lrt -L /usr/local/lib -ljemalloc -Wl,-Bsymbolic-functions -fPIE -pie -Wl,-z,relro -Wl,-z,now -fPIC"
# NGINX_LD_OPT="-Wl,-E -L /usr/local/lib "
# NGINX_EXPORTLD_OPT='-Wl,-E '
LIBBROTLIENC_OPT='-L/usr/local/lib '
LIBBROTLIINC_OPT='-I/usr/local/include '

NGINX_LD_OPT="-Wl,-E $ZLIB_OPT"
LRT='-lrt '
MARCH_TARGET='x86-64'
NGX_FOPENOPT=' -DTCP_FASTOPEN=23'
GCC_NONNATIVEFLAGS=""
if [[ "$CLANG" == 'y' ]]; then
    CCM=64
    MTUNEOPT="-m${CCM} -march=${MARCH_TARGET}${NGX_FOPENOPT} "
    CLANG_CCOPT=' -Wno-sign-compare -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings -Wno-unused-command-line-argument'
    # CLANG_CCOPT=' -Wno-sign-compare -Wno-int-conversion -Wno-implicit-function-declaration -Wno-incompatible-library-redeclaration -Wno-format -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings'

 else
    CCM=64
    MTUNEOPT="-m${CCM} -march=${MARCH_TARGET}${GCC_NONNATIVEFLAGS}${NGX_FOPENOPT} "
fi

if [[ "$CENTOS_SEVEN" = '7' && "$CLANG_FOUR" = [yY] && -f "${CLANG_NEWBIN}" ]] || [[ "$CENTOS_SEVEN" = '7' && "$CLANG_FIVE" = [yY] && -f "${CLANG_NEWBIN}" ]] || [[ "$CENTOS_SEVEN" = '7' && "$CLANG_SIX" = [yY] && -f "${CLANG_NEWBIN}" ]] || [[ "$CENTOS_SEVEN" = '7' && "$CLANG_SEVEN" = [yY] && -f "${CLANG_NEWBIN}" ]] || [[ "$CENTOS_SEVEN" = '7' && "$CLANG_EIGHT" = [yY] && -f "${CLANG_NEWBIN}" ]]; then
  
  if [[ "$INITIALINSTALL" != [yY] ]]; then
    export CC="ccache ${CLANG_NEWBIN}${LLVMLTO_OPT} -ferror-limit=0${CCTOOLSET}"
    export CXX="ccache ${CLANG_NEWBIN}++${LLVMLTO_OPT} -ferror-limit=0"
    export CCACHE_CPP2=yes
    CLANG_CCOPT=' -Wno-sign-compare -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings -Wno-unused-command-line-argument'
else
    export CC="${CLANG_NEWBIN}${LLVMLTO_OPT} -ferror-limit=0${CCTOOLSET}"
    export CXX="${CLANG_NEWBIN}++${LLVMLTO_OPT} -ferror-limit=0"
    # export CCACHE_CPP2=yes
    CLANG_CCOPT=' -Wno-sign-compare -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings -Wno-unused-command-line-argument'
  fi
  ############################
  ## clang 4.0 else
else
  ## clang 4.0 else
  ############################
  if [[ "$INITIALINSTALL" != [yY] ]]; then
    export CC="ccache /usr/bin/clang -ferror-limit=0${CCTOOLSET}"
    export CXX="ccache /usr/bin/clang++ -ferror-limit=0"
    export CCACHE_CPP2=yes
    CLANG_CCOPT=' -Wno-sign-compare -Wno-int-conversion -Wno-implicit-function-declaration -Wno-incompatible-library-redeclaration -Wno-format -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings'
else
    export CC="/usr/bin/clang -ferror-limit=0${CCTOOLSET}"
    export CXX="/usr/bin/clang++ -ferror-limit=0"
    # export CCACHE_CPP2=yes
    CLANG_CCOPT=' -Wno-sign-compare -Wno-int-conversion -Wno-implicit-function-declaration -Wno-incompatible-library-redeclaration -Wno-format -Wno-string-plus-int -Wno-deprecated-declarations -Wno-unused-parameter -Wno-unused-const-variable -Wno-conditional-uninitialized -Wno-mismatched-tags -Wno-sometimes-uninitialized -Wno-parentheses-equality -Wno-tautological-compare -Wno-self-assign -Wno-deprecated-register -Wno-deprecated -Wno-invalid-source-encoding -Wno-pointer-sign -Wno-parentheses -Wno-enum-conversion -Wno-c++11-compat-deprecated-writable-strings -Wno-write-strings'
fi
  ############################
# fi # clang 4.0
else
  CLANG_CCOPT=""
  echo "CLANG_CCOPT=\"\""
fi


if [[ "${boringssl_switch:?}" == 'y' ]]; then
    NGINX_LD_OPT="$NGINX_LD_OPT$BORINGSSL_LIBOPT$LIBBROTLIENC_OPT$LRT"
    LUALD_OPT="-Wl,-rpath,${ZLIB_RPATH}${BORINGSSL_RPATH}/usr/local/lib"
    NGINX_CC_OPT=${BORINGSSLINC_OPT}$ZLIBINC_OPT$LIBBROTLIINC_OPT$MTUNEOPT
else
    NGINX_LD_OPT="$NGINX_LD_OPT$LIBBROTLIENC_OPT$LRT"
    LUALD_OPT="-Wl,-rpath,${ZLIB_RPATH}/usr/local/lib"
    NGINX_CC_OPT=$ZLIBINC_OPT$LIBBROTLIINC_OPT$MTUNEOPT
fi
if [[ "$NGINXCOMPILE_PIE" == [yY] ]]; then
    PIE_OPT='-fPIC -pie '
else
    PIE_OPT=""
fi
if [[ "$NGINX_PASSENGER" == [yY] ]]; then
    GCC_OPTLEVEL=' -O2'
else
    GCC_OPTLEVEL=' -O3'
fi
FSTACKPROTECT='-fstack-protector'
if [[ "$NGINXCOMPILE_FORMATSEC" == [yY] ]]; then
    FORMATSECURITY_OPT=' -Wformat -Werror=format-security'
else
    FORMATSECURITY_OPT=""
fi

NGINX_CC_OPT="$NGINX_CC_OPT$PIE_OPT-g$GCC_OPTLEVEL $FSTACKPROTECT"
NGINX_CC_OPT="$NGINX_CC_OPT --param=ssp-buffer-size=4${FORMATSECURITY_OPT} -Wp,-D_FORTIFY_SOURCE=2  -Wp,-D_FORTIFY_SOURCE=2"
NGINX_CC_OPT="$NGINX_CC_OPT "
if [[ "${gperftools:?}" == 'n' ]]; then
    NGINX_LD_OPT="$NGINX_LD_OPT$JEMALLOC_LD"
fi
NGINX_LD_OPT="$NGINX_LD_OPT$PCRE_LD -Wl,-z,relro "
NGINX_LD_OPT=$NGINX_LD_OPT$LUALD_OPT
# nginx_cc_opt="-m64 -O3 -g -DTCP_FASTOPEN=23 -ffast-math -march=native -flto -fstack-protector-strong -fuse-ld=gold --param=ssp-buffer-size=4 -Wformat -Werror=format-security -fno-strict-aliasing -fPIC -Wdate-time -Wp,-D_FORTIFY_SOURCE=2 -gsplit-dwarf"

ln -s /usr/local/software/sharelib/include/* /usr/local/include/

if [ "${without_lua:?}" -eq 0 ]; then
    #lua 相关
    cd "${build_src:?}"
    info "Nginx Lua module Download .... "
    git clone https://github.com/simpl/ngx_devel_kit.git
    git clone https://github.com/openresty/lua-nginx-module.git
    git clone https://github.com/openresty/stream-lua-nginx-module.git
    # LuaJIT
    info "Nginx LuaJIT Install .... "
    #git clone http://luajit.org/git/luajit-2.0.git
    #cd luajit-2.0 && git checkout v${LuaJIT_version:?}
    # use openresty version luajit2
    git clone https://github.com/openresty/luajit2
    cd luajit2
    make -j "$(nproc)" && make install PREFIX=/usr/local/luajit
    [ -f /etc/ld.so.conf.d/luajit.conf ] && rm -rf /etc/ld.so.conf.d/luajit.conf
    echo "/usr/local/luajit/lib" >/etc/ld.so.conf.d/luajit.conf && ldconfig -v
    # shellcheck disable=SC2181
    if [ $? -eq 0 ]; then
        info "openresty lua-cjson install.... "
        cd "${build_src:?}"
        git clone https://github.com/openresty/lua-cjson.git && cd lua-cjson
        cp Makefile Makefile.bak
        sed -i "s@^PREFIX =.*@PREFIX =             /usr/local/luajit@" Makefile
        sed -i "s@^LUA_INCLUDE_DIR ?=.*@LUA_INCLUDE_DIR ?=   /usr/local/luajit/include/luajit-2.1@" Makefile
        make -j "$(nproc)" && make install
    else
        error "LuaJIT-${LuaJIT_version:?} install failed, Please contact the author !!!"
    fi
    nginx_modules_options="--add-dynamic-module=../ngx_devel_kit"
    nginx_modules_options=$nginx_modules_options" --add-dynamic-module=../lua-nginx-module"
    nginx_modules_options=$nginx_modules_options" --add-module=../stream-lua-nginx-module"
    export LUAJIT_LIB=/usr/local/luajit/lib
    export LUAJIT_INC=/usr/local/luajit/include/luajit-2.1
fi

# 64bit OS only for Nginx compiled against zlib-ng
# https://github.com/Dead2/zlib-ng
if [[ "${nginx_zlibng:?}" == 'y' ]]; then
    cd "${build_src:?}"
    git clone https://github.com/Dead2/zlib-ng
    cd zlib-ng
    ./configure --zlib-compat
    # make${MAKETHREADS}
    # make install
    zlibng_opt=' --with-zlib=../zlib-ng'
else
    zlibng_opt=""
fi

# https://nginx.org/en/docs/http/ngx_http_slice_module.html
ngxsliceopt=' --with-http_slice_module'
stream_sslprereadopt=" --with-stream_ssl_preread_module"
httptwoopt=' --with-http_spdy_module --with-http_v2_module'
realipopt=' --with-http_realip_module'
rdnsopt=" --add-module=../nginx-http-rdns"
stubstatusopt=" --with-http_stub_status_module"
subopt=" --with-http_sub_module"
additionopt=" --with-http_addition_module"
testcookieopt=" --add-module=../testcookie-nginx-module"
hidelengthopt=" --add-dynamic-module=../nginx-length-hiding-filter-module"
imagefilteropt=" --with-http_image_filter_module=dynamic"
ngxxsltopt=" --with-http_xslt_module=dynamic"
ngxperlopt=" --with-http_perl_module=dynamic"
# accesskeyopt=" --add-module=../nginx-accesskey-2.0.3"
# NGINX_CACHEPURGE='y'         # https://github.com/FRiCKLE/ngx_cache_purge/
# NGINX_HTTPCONCAT='n'         # https://github.com/alibaba/nginx-http-concat
headersmoreopt=" --add-dynamic-module=../headers-more-nginx-module-master"
# NGINX_HTTPREDIS='y'          # Nginx redis http://wiki.nginx.org/HttpRedisModule
# NGINX_HTTPREDISVER='0.3.7'   # Nginx redis version
# httpredisopt=" --add-module=../$NGX_HTTPREDISDIR"
authreqopt=' --with-http_auth_request_module'

# pagespeed
if [ "${without_pagespeed:?}" -eq 0 ]; then
    cd "${build_src:?}"
    src_url=https://github.com/apache/incubator-pagespeed-ngx/archive/v${pagespeed_version:?}.tar.gz
    download_and_extract "$src_url" "$build_src/incubator-pagespeed-ngx" "$build_src"
    src_url=https://dl.google.com/dl/page-speed/psol/${psol_version:?}-x64.tar.gz
    download_and_extract "$src_url" "$build_src/incubator-pagespeed-ngx/psol" "$build_src"
    nginx_modules_options=$nginx_modules_options" --add-dynamic-module=../incubator-pagespeed-ngx"
fi

# download and prepare Nginx
src_url=https://nginx.org/download/nginx-${nginx_version:?}.tar.gz
download_and_extract "$src_url" "${build_src:?}/nginx" "$build_src"
cd "${build_src:?}"/nginx

export LIBRARY_PATH=${sharelib_install_dir:?}/lib:$LIBRARY_PATH
# shellcheck disable=SC2086
./configure --prefix="${NGINX_HOME:?}" \
    --user="${NGINX_USER:?}" --group="$NGINX_USER" \
    --sbin-path="${NGINX_HOME:?}"/sbin/nginx \
    --conf-path="${NGINX_HOME:?}"/conf/nginx.conf \
    --error-log-path="${NGINX_HOME:?}"/logs/error.log \
    --http-log-path="${NGINX_HOME:?}"/logs/access.log \
    --pid-path="${NGINX_HOME:?}"/run/nginx.pid \
    --lock-path="${NGINX_HOME:?}"/run/nginx.lock \
    --http-client-body-temp-path="${NGINX_HOME:?}"/tmp/client \
    --http-proxy-temp-path="${NGINX_HOME:?}"/tmp/proxy \
    --http-fastcgi-temp-path="${NGINX_HOME:?}"/tmp/fcgi \
    --without-http_ssi_module \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-compat \
    --with-file-aio \
    --with-libatomic \
    --with-threads \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --with-stream_realip_module \
    --with-http_slice_module \
    --with-pcre=../pcre-"${pcre_version:?}" \
    --with-pcre-jit \
    --with-zlib="${build_src:?}"/zlib-cf \
    --with-ld-opt="$nginx_ld_opt" \
    --with-cc-opt="$nginx_cc_opt" \
    --with-openssl="${build_src:?}"/openssl-"${openssl_version:?}" \
    --with-openssl-opt="$openssl_opt" \
    --add-dynamic-module=../ngx_brotli \
    --add-dynamic-module=../nginx-ct \
    --add-dynamic-module=../echo-nginx-module \
    --add-dynamic-module=../headers-more-nginx-module $nginx_modules_options

#close debug
sed -i 's@CFLAGS="$CFLAGS -g"@#CFLAGS="$CFLAGS -g"@' auto/cc/gcc

#enabled UTF8 support
sed -i 's@./configure --disable-shared  --enable-jit@./configure --disable-shared --enable-jit --enable-utf8 --enable-unicode-properties@' objs/Makefile
make -j "$(nproc)" && make install
# configure nginx
mkdir -p "${NGINX_HOME:?}"/conf.d
mkdir -p "${NGINX_HOME:?}"/tmp/client
chmod 4755 "${NGINX_HOME:?}"/sbin/nginx
mv "$NGINX_HOME"/conf/nginx.conf "$NGINX_HOME"/conf/nginx.conf_bak
if [ "$without_lua" -eq 0 ]; then
    cp /assets/runtime/config/nginx_lua.conf "$NGINX_HOME"/conf/nginx.conf
    update_template "$NGINX_HOME/conf/nginx.conf" \
        NGINX_USER \
        NGINX_LOG_DIR \
        NGINX_HOME \
        NGINX_SITECONF_DIR
    cp /assets/runtime/config/sites-enabled/default_lua.conf "$NGINX_HOME"/conf.d/
else
    cp /assets/runtime/config/nginx.conf "$NGINX_HOME"/conf/nginx.conf
    update_template "$NGINX_HOME/conf/nginx.conf" \
        NGINX_USER \
        NGINX_LOG_DIR \
        NGINX_HOME \
        NGINX_SITECONF_DIR
    cp /assets/runtime/config/sites-enabled/default.conf "$NGINX_HOME"/conf.d/
fi

# supervisor
pip install supervisor
ln -s -t /usr/local/bin "${python3_install_dir:?}"/bin/supervisor*
[ ! -d /etc/supervisor ] && mkdir -p /etc/supervisor
mkdir -p /etc/supervisor/conf.d /var/log/supervisor
cp /assets/services/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
# move supervisord.log file to ${NGINX_LOG_DIR}/supervisor/
sed -i "s|^logfile=.*|logfile=${NGINX_LOG_DIR}/supervisor/supervisord.log ;|" \
    /etc/supervisor/supervisord.conf

# Install a syslog daemon and logrotate.
if [ "${disable_syslog:?}" -eq 0 ]; then
    info "install syslog-ng"
    chmod +x /assets/services/syslog-ng/syslog-ng.sh
    /assets/services/syslog-ng/syslog-ng.sh || true
fi
# Install cron daemon.
if [ "${disable_cron:?}" -eq 0 ]; then
    info "install CRON"
    chmod +x /assets/services/cron/cron.sh
    /assets/services/cron/cron.sh || true
fi
# configure supervisord to start nginx
cp /assets/services/supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
update_template '/etc/supervisor/conf.d/nginx.conf' \
    NGINX_HOME \
    NGINX_USER \
    NGINX_LOG_DIR

apt-mark auto '.*' >/dev/null
# shellcheck disable=SC2086
if [ -n "${savedAptMark:?}" ]; then
    apt-mark manual $savedAptMark
fi

dpkg-query --show --showformat \
    '${package}\n' | grep -P '^syslog-ng|^logrotate|^cron' |
    xargs apt-mark manual
# if [ $? -eq 0 ]; then
#     echo ""
# else
#     echo "No packages found"
# fi
apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

mv /assets/entrypoint.sh /usr/local/bin/entrypoint.sh
chmod 755 /usr/local/bin/entrypoint.sh
ln -s /usr/local/bin/entrypoint.sh / # backwards compat
