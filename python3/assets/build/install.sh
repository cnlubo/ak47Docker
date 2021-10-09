#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-09-14 10:41:21
# @LastEditors: cnak47
# @LastEditTime: 2019-09-25 16:07:34
# @Description:
###

set -e
# shellcheck disable=SC1091
source /assets/buildconfig
[[ ${debug:?} == true ]] && set -x
BaseDeps='ca-certificates libexpat1-dev '
apt-get update
if [ -n "$BaseDeps" ]; then
    # shellcheck disable=SC2086
    ${apt_install:?} $BaseDeps
fi
BuildDeps='apt-transport-https xz-utils bzip2 gcc g++ make patch wget curl '
if ! command -v gpg >/dev/null; then
    BuildDeps=${BuildDeps}'gnupg dirmngr '
fi
# shellcheck disable=SC2086
savedAptMark="$(apt-mark showmanual)" &&
    ${apt_install:?} $BuildDeps

mkdir -p "${build_src:?}"

if [ "${disable_python3:?}" -eq 0 ]; then
    chmod +x /assets/build/python3.sh
    /assets/build/python3.sh || true
fi
if [ "${disable_python2:?}" -eq 0 ]; then
    chmod +x /assets/build/python2.sh
    /assets/build/python2.sh || true
fi
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
