#!/bin/bash
# shellcheck disable=SC2034
# @Author: cnak47
# @Date: 2020-06-16 14:22:08
# @LastEditors: cnak47
# @LastEditTime: 2020-10-07 18:36:47
# @Description: 
# #
# Color Palette
RESET='\033[0m'
BOLD='\033[1m'

## Foreground
BLACK='\033[38;5;0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
BLUE='\033[38;5;4m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'
WHITE='\033[38;5;7m'

## Background
ON_BLACK='\033[48;5;0m'
ON_RED='\033[48;5;1m'
ON_GREEN='\033[48;5;2m'
ON_YELLOW='\033[48;5;3m'
ON_BLUE='\033[48;5;4m'
ON_MAGENTA='\033[48;5;5m'
ON_CYAN='\033[48;5;6m'
ON_WHITE='\033[48;5;7m'

MODULE="$(basename $0)"

stderr_print() {

    printf "%b\\n" "${*}" >&2
}

log() {

    stderr_print "[${BLUE}${MODULE} ${MAGENTA}$(date "+%Y-%m-%d %H:%M:%S ")${RESET}] ${*}"

}

info() {

    log "${GREEN}INFO ${RESET} ==> ${*}"
}

warn() {

    log "${YELLOW}WARN ${RESET} ==> ${*}"
}

error() {

    log "${RED}ERROR${RESET} ==> ${*}"
}
