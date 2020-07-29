#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-09-15 16:52:25
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-15 20:35:21
# @Description: Find 3 latest major Golang releases
###

# set -o xtrace
set -o nounset
set -o errexit
set -o pipefail

function decrement_version() {
    local VERSION="$1"

    local DECREMENTED_VERSION=
    if [[ "$VERSION" =~ .*\..* ]]; then
        DECREMENTED_VERSION="${VERSION%.*}.$((${VERSION##*.} - 1))"
    else
        DECREMENTED_VERSION="$((${VERSION##*.} - 1))"
    fi

    echo "$DECREMENTED_VERSION"
}

function find_latest_minor_release() {
    local RELEASES=("$@")
    local MAJOR_RELEASE="${RELEASES[-1]}"

    for version in "${RELEASES[@]}"; do
        if [[ "$version" =~ ^"$MAJOR_RELEASE" ]]; then
            echo "$version"
            break
        fi
    done
}

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

bash_version=$(echo "$BASH_VERSION" | cut -d '.' -f 1,2)
if version_gt "$bash_version" 4.3; then
    readarray releases_list <<<"$(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p' | uniq)"
else
    read -r -a releases_list <<<"$(wget -qO- https://golang.org/dl/ | grep -oP 'https:\/\/dl\.google\.com\/go\/go([0-9\.]+)\.linux-amd64\.tar\.gz' | sed -nre 's/^[^0-9]*(([0-9]+\.)*[0-9]+).*/\1/p' | uniq)"
fi

latest_release=${releases_list[0]}
latest_major_release=$(cut -d '.' -f 1 <<<${releases_list[0]})"."$(cut -d . -f 2 <<<${releases_list[0]})

previous_major_release=$(decrement_version $latest_major_release)
previous_major_release2=$(decrement_version $previous_major_release)

previous_release=$(find_latest_minor_release ${releases_list[@]} $previous_major_release)
previous_release2=$(find_latest_minor_release ${releases_list[@]} $previous_major_release2)

echo $latest_release
echo $previous_release
echo $previous_release2
