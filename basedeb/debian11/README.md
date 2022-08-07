<!--
 * @Author: cnak47
 * @Date: 2018-11-04 18:35:27
LastEditors: cnak47
LastEditTime: 2020-10-07 11:44:20
 * @Description: 
 -->

# About

My Debian boilerplate image that forms the base for my docker containers.

The image is built on top of the most recently tagged debian-slim:10.5 image and installs the following extra packages:

- less
- netbase
- procps
- tree

The image installs the follow softwares from source code:

- tini
  <https://github.com/krallin/tini>
- gosu
- zsh
- zlib 1.2.12
- openssl 1.1.1q
- yq
  <https://github.com/mikefarah/yq>
- wait-for-port
  <https://github.com/bitnami/wait-for-port>
- render-template
  <https://github.com/bitnami/render-template>
- ini-file
  <https://github.com/bitnami/ini-file>
