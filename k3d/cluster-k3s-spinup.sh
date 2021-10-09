#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

# -----------------------------------------------------------------------------
# K3d cluster variables helpers. These functions need the
# following variables:
#
#    K3D_VERSION     -  The k3d version for running, default is v1.7.0.
#    K8S_VERSION     -  The Kubernetes version for the cluster, default is v1.18.2.
#    CLUSTER_NAME    -  The name for the cluster, default is edge.
#    CONTROL_PLANES  -  The number of the control-plane, default is 1.
#    WORKERS         -  The number of the workers, default is 3.
#    IMAGE_SUFFIX    -  The suffix for k3s image, default is k3s1, ref to: https://hub.docker.com/r/rancher/k3s/tags.

K8S_VERSION=${K8S_VERSION:-"v1.18.2"}
CLUSTER_NAME=${CLUSTER_NAME:-"edge"}
IMAGE_SUFFIX=${IMAGE_SUFFIX:-"k3s1"}

function octopus::cluster_k3d::install() {
  local version=${K3D_VERSION:-"v1.7.0"}
  curl -fL "https://github.com/rancher/k3d/releases/download/${version}/k3d-$(octopus::util::get_os)-$(octopus::util::get_arch)" -o /tmp/k3d
  chmod +x /tmp/k3d && mv /tmp/k3d /usr/local/bin/k3d
}

function octopus::cluster_k3d::validate() {
  if [[ -n "$(command -v k3d)" ]]; then
    return 0
  fi

  octopus::log::info "installing k3d"
  if octopus::cluster_k3d::install; then
    octopus::log::info "$(k3d --version 2>&1)"
    return 0
  fi
  octopus::log::error "no k3d available"
  return 1
}

function octopus::cluster_k3d::wait_node() {
  local node_name=${1}
  octopus::log::info "waiting node ${node_name} for ready"
  while true; do
    if kubectl get node "${node_name}" >/dev/null 2>&1; then
      break
    fi
    sleep 1s
  done
  kubectl wait --for=condition=Ready "node/${node_name}" --timeout=60s >/dev/null 2>&1
}

function octopus::cluster_k3d::startup() {
  if ! octopus::docker::validate; then
    octopus::log::fatal "docker hasn't been installed"
  fi
  if ! octopus::kubectl::validate; then
    octopus::log::fatal "kubectl hasn't been installed"
  fi
  if ! octopus::cluster_k3d::validate; then
    octopus::log::fatal "k3d hasn't been installed"
  fi

  octopus::log::info "creating ${CLUSTER_NAME} cluster with ${K8S_VERSION}"
  local k3s_image="rancher/k3s:${K8S_VERSION}-${IMAGE_SUFFIX}"
  # setup control-planes
  local control_planes=${CONTROL_PLANES:-1}
  if [[ ${control_planes} -lt 1 ]]; then
    control_planes=1
  fi
  for ((i = 0; i < control_planes; i++)); do
    if [[ ${i} -eq 0 ]]; then
      local random_port_start
      random_port_start=$(octopus::util::get_random_port_start 3)
      local api_port=$((random_port_start + 0))
      local ingress_http_port=$((random_port_start + 1))
      octopus::log::info "INGRESS_HTTP_PORT is ${ingress_http_port}"
      export INGRESS_HTTP_PORT=${ingress_http_port}
      local ingress_https_port=$((random_port_start + 2))
      octopus::log::info "INGRESS_HTTPS_PORT is ${ingress_https_port}"
      export INGRESS_HTTPS_PORT=${ingress_https_port}

      local node_name="edge-control-plane"
      k3d create --publish "${ingress_http_port}:80" --publish "${ingress_https_port}:443" --api-port "0.0.0.0:${api_port}" --name "${CLUSTER_NAME}" --image "${k3s_image}" --server-arg "--node-name=${node_name}" --wait 60

      # backup kubeconfig
      local kubeconfig_path="${KUBECONFIG:-}"
      if [[ -z "${kubeconfig_path}" ]]; then
        kubeconfig_path="$(cd ~ && pwd -P)/.kube/config"
        mkdir -p "$(cd ~ && pwd -P)/.kube"
      fi
      if [[ -f "${kubeconfig_path}" ]]; then
        cp -f "${kubeconfig_path}" "${kubeconfig_path}_k3d_bak"
        octopus::log::warn "default kubeconfig has been backup in ${kubeconfig_path}_k3d_bak"
      fi
      cp -f "$(k3d get-kubeconfig --name="${CLUSTER_NAME}")" "${kubeconfig_path}"
      octopus::log::info "${CLUSTER_NAME} cluster's kubeconfig wrote in ${kubeconfig_path} now"

      octopus::cluster_k3d::wait_node ${node_name}
    else
      local node_name="edge-control-plane${i}"
      k3d add-node --name "${CLUSTER_NAME}" --image "${k3s_image}" --role server --arg "--node-name=${node_name}"

      octopus::cluster_k3d::wait_node ${node_name}
    fi
  done

  # setup workers
  local workers=${WORKERS:-3}
  if [[ ${workers} -lt 1 ]]; then
    workers=1
  fi
  rm -rf /tmp/k3d/"${CLUSTER_NAME}"
  for ((i = 0; i < workers; i++)); do
    local node_name="edge-worker${i}"
    if [[ ${i} -eq 0 ]]; then
      node_name="edge-worker"
    fi

    local node_host_path="/tmp/k3d/${CLUSTER_NAME}/${node_name}"
    mkdir -p "${node_host_path}"
    k3d add-node --name "${CLUSTER_NAME}" --image "${k3s_image}" --role agent --arg "--node-name=${node_name}" --volume "${node_host_path}":/etc/rancher/node

    octopus::cluster_k3d::wait_node ${node_name}
  done
}

function octopus::cluster_k3d::cleanup() {
  octopus::log::warn "removing ${CLUSTER_NAME} cluster"
  k3d delete --name "${CLUSTER_NAME}"

  # backup kubeconfig
  local kubeconfig_path="${KUBECONFIG:-}"
  if [[ -z "${kubeconfig_path}" ]]; then
    kubeconfig_path="$(cd ~ && pwd -P)/.kube/config"
  fi
  if [[ -f "${kubeconfig_path}_k3d_bak" ]]; then
    cp -f "${kubeconfig_path}_k3d_bak" "${kubeconfig_path}"
    octopus::log::warn "default kubeconfig has been recover in ${kubeconfig_path}"
  else
    octopus::log::warn "could not find the kubeconfig of k3d backup"
  fi
}

function octopus::cluster_k3d::spinup() {
  octopus::log::info "cleanup proxy config"
  octopus::util::unsetproxy

  trap 'octopus::cluster_k3d::cleanup' EXIT
  octopus::cluster_k3d::startup

  octopus::log::warn "please input CTRL+C to stop the local cluster"
  read -r -d '' _ </dev/tty
}

function octopus::cluster_k3d::add_worker() {
  if ! octopus::docker::validate; then
    octopus::log::fatal "docker hasn't been installed"
  fi
  if ! octopus::kubectl::validate; then
    octopus::log::fatal "kubectl hasn't been installed"
  fi
  if ! octopus::cluster_k3d::validate; then
    octopus::log::fatal "k3d hasn't been installed"
  fi

  local node_name=${1}
  if [[ -z "${node_name}" ]]; then
    octopus::log::error "node name is required"
  fi

  octopus::log::info "validating node ${node_name} is not existed"
  if kubectl get node "${node_name}" >/dev/null 2>&1; then
    octopus::log::fatal "${node_name} node is existed"
  fi

  octopus::log::info "adding new node to ${CLUSTER_NAME} cluster"
  local node_host_path="/tmp/k3d/${CLUSTER_NAME}/${node_name}"
  mkdir -p "${node_host_path}"
  local k3s_image="rancher/k3s:${K8S_VERSION}-${IMAGE_SUFFIX}"
  k3d add-node --name "${CLUSTER_NAME}" --image "${k3s_image}" --role agent --arg "--node-name=${node_name}" --volume "${node_host_path}":/etc/rancher/node

  octopus::cluster_k3d::wait_node "${node_name}"
}

# Unset Proxy
function octopus::util::unsetproxy() {
    unset {http,https,ftp}_proxy
    unset {HTTP,HTTPS,FTP}_PROXY
}

function octopus::util::find_subdirs() {
  local path="$1"
  if [[ -z "$path" ]]; then
    path="./"
  fi
  # shellcheck disable=SC2010
  ls -l "$path" | grep "^d" | awk '{print $NF}'
}

function octopus::util::is_empty_dir() {
  local path="$1"
  if [[ ! -d "${path}" ]]; then
    return 0
  fi

  # shellcheck disable=SC2012
  if [[ $(ls "${path}" | wc -l) -eq 0 ]]; then
    return 0
  fi
  return 1
}

function octopus::util::join_array() {
  local IFS="$1"
  shift 1
  echo "$*"
}

function octopus::util::get_os() {
  local os
  if go env GOOS >/dev/null 2>&1; then
    os=$(go env GOOS)
  else
    os=$(echo -n "$(uname -s)" | tr '[:upper:]' '[:lower:]')
  fi

  case ${os} in
  cygwin_nt*) os="windows" ;;
  mingw*) os="windows" ;;
  msys_nt*) os="windows" ;;
  esac

  echo -n "${os}"
}

function octopus::util::get_arch() {
  local arch
  if go env GOARCH >/dev/null 2>&1; then
    arch=$(go env GOARCH)
    if [[ "${arch}" == "arm" ]]; then
      arch="${arch}v$(go env GOARM)"
    fi
  else
    arch=$(uname -m)
  fi

  case ${arch} in
  armv5*) arch="armv5" ;;
  armv6*) arch="armv6" ;;
  armv7*)
    if [[ "${1:-}" == "--full-name" ]]; then
      arch="armv7"
    else
      arch="arm"
    fi
    ;;
  aarch64) arch="arm64" ;;
  x86) arch="386" ;;
  i686) arch="386" ;;
  i386) arch="386" ;;
  x86_64) arch="amd64" ;;
  esac

  echo -n "${arch}"
}

function octopus::util::get_random_port_start() {
  local offset="${1:-1}"
  if [[ ${offset} -le 0 ]]; then
    offset=1
  fi

  while true; do
    random_port=$((RANDOM % 10000 + 50000))
    for ((i = 0; i < offset; i++)); do
      if nc -z 127.0.0.1 $((random_port + i)); then
        random_port=0
        break
      fi
    done

    if [[ ${random_port} -ne 0 ]]; then
      echo -n "${random_port}"
      break
    fi
  done
}

##
# Borrowed from github.com/kubernetes/kubernetes/hack/lib/logging.sh
##

# Handler for when we exit automatically on an error.
octopus::log::errexit() {
  local err="${PIPESTATUS[*]}"

  # if the shell we are in doesn't have errexit set (common in subshells) then
  # don't dump stacks.
  set +o | grep -qe "-o errexit" || return

  set +o xtrace
  octopus::log::panic "${BASH_SOURCE[1]}:${BASH_LINENO[0]} '${BASH_COMMAND}' exited with status ${err}" "${1:-1}"
}

octopus::log::install_errexit() {
  # trap ERR to provide an error handler whenever a command exits nonzero, this
  # is a more verbose version of set -o errexit
  trap 'octopus::log::errexit' ERR

  # setting errtrace allows our ERR trap handler to be propagated to functions,
  # expansions and subshells
  set -o errtrace
}

# Info level logging.
octopus::log::info() {
  local message="${2:-}"

  local timestamp
  timestamp="$(date +"[%m%d %H:%M:%S]")"
  echo -e "\033[34m[INFO]\033[0m ${timestamp} ${1-}"
  shift 1
  for message; do
    echo -e "       ${message}"
  done
}

# Warn level logging.
octopus::log::warn() {
  local message="${1:-}"

  local timestamp
  timestamp="$(date +"[%m%d %H:%M:%S]")"
  echo -e "\033[33m[WARN]\033[0m ${timestamp} ${1-}"
  shift 1
  for message; do
    echo -e "       ${message}"
  done
}

# Error level logging, log an error but keep going, don't dump the stack or exit.
octopus::log::error() {
  local message="${1:-}"

  local timestamp
  timestamp="$(date +"[%m%d %H:%M:%S]")"
  echo "\033[31m[ERRO]\033[0m ${timestamp} ${1-}" >&2
  shift 1
  for message; do
    echo -e "       ${message}" >&2
  done
}

# Fatal level logging, log an error but exit with 1, don't dump the stack or exit.
octopus::log::fatal() {
  local message="${1:-}"

  local timestamp
  timestamp="$(date +"[%m%d %H:%M:%S]")"
  echo -e "\033[41;33m[FATA]\033[0m ${timestamp} ${1-}" >&2
  shift 1
  for message; do
    echo -e "       ${message}" >&2
  done

  exit 1
}

# Panic level logging, dump the error stack and exit.
# Args:
#   $1 Message to log with the error
#   $2 The error code to return
#   $3 The number of stack frames to skip when printing.
octopus::log::panic() {
  local message="${1:-}"
  local code="${2:-1}"

  local timestamp
  timestamp="$(date +"[%m%d %H:%M:%S]")"
  echo -e "\033[41;33m[FATA]\033[0m ${timestamp} ${message}" >&2

  # print out the stack trace described by $function_stack
  if [[ ${#FUNCNAME[@]} -gt 2 ]]; then
    echo -e "\033[31m       call stack:\033[0m" >&2
    local i
    for ((i = 1; i < ${#FUNCNAME[@]} - 2; i++)); do
      echo -e "       ${i}: ${BASH_SOURCE[${i} + 2]}:${BASH_LINENO[${i} + 1]} ${FUNCNAME[${i} + 1]}(...)" >&2
    done
  fi

  echo -e "\033[41;33m[FATA]\033[0m ${timestamp} exiting with status ${code}" >&2

  popd >/dev/null 2>&1 || exit "${code}"
  exit "${code}"
}

function octopus::util::find_subdirs() {
  local path="$1"
  if [[ -z "$path" ]]; then
    path="./"
  fi
  # shellcheck disable=SC2010
  ls -l "$path" | grep "^d" | awk '{print $NF}'
}

function octopus::util::is_empty_dir() {
  local path="$1"
  if [[ ! -d "${path}" ]]; then
    return 0
  fi

  # shellcheck disable=SC2012
  if [[ $(ls "${path}" | wc -l) -eq 0 ]]; then
    return 0
  fi
  return 1
}

function octopus::util::join_array() {
  local IFS="$1"
  shift 1
  echo "$*"
}

function octopus::util::get_os() {
  local os
  if go env GOOS >/dev/null 2>&1; then
    os=$(go env GOOS)
  else
    os=$(echo -n "$(uname -s)" | tr '[:upper:]' '[:lower:]')
  fi

  case ${os} in
  cygwin_nt*) os="windows" ;;
  mingw*) os="windows" ;;
  msys_nt*) os="windows" ;;
  esac

  echo -n "${os}"
}

function octopus::util::get_arch() {
  local arch
  if go env GOARCH >/dev/null 2>&1; then
    arch=$(go env GOARCH)
    if [[ "${arch}" == "arm" ]]; then
      arch="${arch}v$(go env GOARM)"
    fi
  else
    arch=$(uname -m)
  fi

  case ${arch} in
  armv5*) arch="armv5" ;;
  armv6*) arch="armv6" ;;
  armv7*)
    if [[ "${1:-}" == "--full-name" ]]; then
      arch="armv7"
    else
      arch="arm"
    fi
    ;;
  aarch64) arch="arm64" ;;
  x86) arch="386" ;;
  i686) arch="386" ;;
  i386) arch="386" ;;
  x86_64) arch="amd64" ;;
  esac

  echo -n "${arch}"
}

function octopus::util::get_random_port_start() {
  local offset="${1:-1}"
  if [[ ${offset} -le 0 ]]; then
    offset=1
  fi

  while true; do
    random_port=$((RANDOM % 10000 + 50000))
    for ((i = 0; i < offset; i++)); do
      if nc -z 127.0.0.1 $((random_port + i)); then
        random_port=0
        break
      fi
    done

    if [[ ${random_port} -ne 0 ]]; then
      echo -n "${random_port}"
      break
    fi
  done
}


function octopus::docker::validate() {
  if [[ -n "$(command -v docker)" ]]; then
    return 0
  fi

  octopus::log::error "no docker available"
  return 1
}

function octopus::kubectl::validate() {
  if [[ -n "$(command -v kubectl)" ]]; then
    return 0
  fi

  octopus::log::error "no kubectl available"
  return 1
}

octopus::cluster_k3d::spinup