#!/bin/bash
# @Author: cnak47
# @Date: 2020-11-22 17:11:44
# @LastEditors: cnak47
# @LastEditTime: 2020-11-22 17:17:38
# @Description: 
# #
set -ex
#gvm pkgset use global
go get -u golang.org/x/lint/golint
go get -u golang.org/x/tools/cmd/goimports
go get -u github.com/nsf/gocode
go get -u github.com/rogpeppe/godef
go get -u github.com/zmb3/gogetdoc
go get -u github.com/go-delve/delve/cmd/dlv
go get github.com/mitchellh/gox
gox -h

