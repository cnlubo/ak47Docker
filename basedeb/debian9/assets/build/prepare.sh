#!/bin/bash
###
# @Author: cnak47
# @Date: 2019-09-14 10:41:21
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 11:18:50
# @Description:
###

set -e
# shellcheck disable=SC1091
source /assets/buildconfig
[[ ${debug:?} == true ]] && set -x
mv /assets/opt/ak47 /opt/
mkdir -p /usr/local/software/
# mv /assets/tools/tools /usr/local/software/
# chmod +x /usr/local/software/tools/*
# ln -s -t /usr/local/bin /usr/local/software/tools/*

# Temporarily disable dpkg fsync to make building faster.
if [[ ! -e /etc/dpkg/dpkg.cfg.d/docker-apt-speedup ]]; then
    echo force-unsafe-io >/etc/dpkg/dpkg.cfg.d/docker-apt-speedup
fi

# dpkg options
cp /assets/conf/dpkg_nodoc /etc/dpkg/dpkg.cfg.d/01_nodoc
cp /assets/conf/dpkg_nolocales /etc/dpkg/dpkg.cfg.d/01_nolocales

## Fix some issues with APT packages.
## See https://github.com/dotcloud/docker/issues/1024
dpkg-divert --local --rename --add /sbin/initctl
ln -sf /bin/true /sbin/initctl

## Replace the 'ischroot' tool to make it always return true.
## Prevent initscripts updates from breaking /dev/shm.
## https://journal.paul.querna.org/articles/2013/10/15/docker-ubuntu-on-rackspace/
## https://bugs.launchpad.net/launchpad/+bug/974584
dpkg-divert --local --rename --add /usr/bin/ischroot
ln -sf /bin/true /usr/bin/ischroot

# Disable some init scripts that aren't relevant in Docker.

for DAEMON in hwclock.sh mountall-bootclean.sh mountall.sh \
    checkroot-bootclean.sh checkfs.sh checkroot.sh motd bootlogs \
    mountdevsubfs.sh procps \
    hostname.sh mountkernfs.sh \
    checkfs.sh urandom \
    mountnfs-bootclean.sh mountnfs.sh umountnfs.sh umountfs umountroot; do
    update-rc.d -f $DAEMON remove || true
done

echo ">>>> Removing init system"
(
    if grep -xFq 'VERSION="7 (wheezy)"' /etc/os-release; then # wheezy
        dpkg --force-remove-essential -P \
            debconf-i18n \
            e2fsprogs e2fslibs
    elif grep -xFq 'VERSION="8 (jessie)"' /etc/os-release; then # jessie
        dpkg --force-remove-essential -P \
            acl debconf-i18n \
            dmsetup libdevmapper1.02.1 libcryptsetup4 \
            init systemd systemd-sysv sysvinit-core upstart udev \
            e2fsprogs e2fslibs
    else # >= stretch
        dpkg --force-remove-essential -P \
            e2fsprogs e2fslibs
    fi
)

echo ">>>> Removing  unused packages"

# dpkg --get-selections | grep -v deinstall
echo "Yes, do as I say!" | apt-get purge \
    libncursesw5 \
    libsmartcols1 \
    ncurses-base \
    ncurses-bin \
    tzdata \
    libsystemd0 \
    libmount1 \
    libudev1

# cleanup
(
    apt-get autoremove -y && apt-get clean -y
    rm -rf \
        /usr/share/doc \
        /usr/share/man \
        /usr/share/info \
        /usr/share/locale \
        /var/lib/apt/lists/* \
        /var/log/* \
        /var/cache/debconf/* \
        /usr/share/common-licenses* \
        ~/.bashrc \
        /etc/systemd \
        /lib/lsb \
        /lib/udev \
        /usr/lib/x86_64-linux-gnu/gconv/IBM* \
        /usr/lib/x86_64-linux-gnu/gconv/EBC*
    mkdir -p /usr/share/man/man1 /usr/share/man/man2 \
        /usr/share/man/man3 /usr/share/man/man4 \
        /usr/share/man/man5 /usr/share/man/man6 \
        /usr/share/man/man7 /usr/share/man/man8
)

## Upgrade all packages.
apt-get update &&
    apt-get dist-upgrade -y --no-install-recommends \
        -o Dpkg::Options::="--force-confold" \
        -o Dpkg::Options::="--force-confdef"

# fix locale
apt-get update && ${apt_install:?} locales
echo "en_US.UTF-8 UTF-8" >/etc/locale.gen &&
    locale-gen --purge en_US.UTF-8 &&
    update-locale LANG=en_US.UTF-8 LC_CTYPE=en_US.UTF-8

# timezone setting
ln -snf /usr/share/zoneinfo/"$TZ" /etc/localtime && echo "$TZ" >/etc/timezone
