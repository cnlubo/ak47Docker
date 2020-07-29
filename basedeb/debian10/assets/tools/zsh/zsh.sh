#!/bin/bash
###
# @Author: cnak47
# @Date: 2018-11-23 09:45:01
 # @LastEditors: cnak47
 # @LastEditTime: 2019-09-25 10:43:13
# @Description:
###
# shellcheck disable=SC1091
set -e
source /assets/buildconfig
source /opt/ak47/base/liblog.sh
source /opt/ak47/base/libbase.sh
set -x
BuildDeps='git-core libncurses5-dev'
# shellcheck disable=SC2086
apt-get update && ${apt_install:?} $BuildDeps && rm -rf /var/lib/apt/lists/*
src_url=https://sourceforge.net/projects/zsh/files/zsh/${zsh_version:?}/zsh-$zsh_version.tar.xz/download
download_and_extract "$src_url" "${build_src:?}/zsh-$zsh_version" "$build_src" "0" zsh-"$zsh_version".tar.xz
cd "${build_src:?}"/zsh-"$zsh_version"
./configure --with-tcsetpgrp
make -j "$(nproc)" && make install

if [ "$(grep -c /usr/local/bin/zsh /etc/shells)" -eq 0 ]; then
    echo "/usr/local/bin/zsh" | tee -a /etc/shells
fi
cd "${build_src:?}"
git clone https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
mkdir -p /root/.oh-my-zsh/custom/themes/ &&
    cp /assets/template/ak47.zsh-theme /root/.oh-my-zsh/custom/themes/
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc
# modify theme
sed -i '\@ZSH_THEME=@s@^@\#@1' /root/.zshrc
sed -i "s@^#ZSH_THEME.*@&\nsetopt no_nomatch@" /root/.zshrc
sed -i "s@^#ZSH_THEME.*@&\nZSH_THEME=\"ak47\"@" /root/.zshrc
sed -i "/^plugins=(git)/c plugins=(git z wd extract)" /root/.zshrc
sed -i "s@^# export LANG=en_US.UTF-8@&\nexport LANG=en_US.UTF-8@" /root/.zshrc
chsh -s /usr/local/bin/zsh
info "zsh instal success !!!"
