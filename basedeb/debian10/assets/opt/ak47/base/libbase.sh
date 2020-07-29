#!/bin/bash
# shellcheck disable=SC2034

# shellcheck disable=SC1091
source /opt/ak47/base/liblog.sh

CNAK47_PREFIX=/opt/ak47

print_welcome_page() {
    if [ -z "$DISABLE_WELCOME_MESSAGE" ]; then
        if [ -n "$IMAGE_APP_NAME" ]; then
            print_image_welcome_page
        fi
    fi
}

# Prints the welcome page for this  Docker image
print_image_welcome_page() {
    GITHUB_PAGE=https://github.com/cnlubo/cnak47-docker-${IMAGE_APP_NAME}

    log ""
    log "${BOLD}Welcome to the Cnak47 ${IMAGE_APP_NAME} container${RESET}"
    log "Subscribe to project updates by watching ${BOLD}${GITHUB_PAGE}${RESET}"
    log "Submit issues and feature requests at ${BOLD}${GITHUB_PAGE}/issues${RESET}"
    log ""
}

## Copies configuration template to the destination as the specified USER
### Looks up for overrides in ${USERCONF_TEMPLATES_DIR} before using the defaults from ${SYSCONF_TEMPLATES_DIR}
# $1: copy-as user
# $2: source file
# $3: destination location
# $4: mode of destination
install_template() {
    local OWNERSHIP=${1}
    local SRC=${2}
    local DEST=${3}
    local MODE=${4:-0644}

    if [[ -f ${USERCONF_TEMPLATES_DIR}/${SRC} ]]; then
        cp "${USERCONF_TEMPLATES_DIR}"/"${SRC}" "${DEST}"
    elif [[ -f ${SYSCONF_TEMPLATES_DIR}/${SRC} ]]; then
        cp "${SYSCONF_TEMPLATES_DIR}"/"${SRC}" "${DEST}"
    fi
    chmod "${MODE}" "${DEST}"
    chown "${OWNERSHIP}" "${DEST}"
}

# Replace placeholders with values
# $1: file with placeholders to replace
# $x: placeholders to replace
#
update_template() {

    local FILE=${1?missing argument}
    shift

    [[ ! -f ${FILE} ]] && return 1

    local VARIABLES=("$@")
    local USR
    USR=$(stat -c %U ${FILE})
    local tmp_file
    tmp_file=$(mktemp)
    cp -a "${FILE}" ${tmp_file}

    local variable
    for variable in "${VARIABLES[@]}"; do
        # Keep the compatibilty: {{VAR}} => ${VAR}
        sed -ri "s/[{]{2}${variable}[}]{2}/\${$variable}/g" ${tmp_file}
    done

    # Replace placeholders
    (
        export "${VARIABLES[@]}"
        # local IFS=":";
        # sudo -HEu ${USR} envsubst "${VARIABLES[*]/#/$}" < ${tmp_file} > ${FILE}
        local IFS=":"
        gosu ${USR} envsubst "${VARIABLES[*]/#/$}" <${tmp_file} >${FILE}
    )
    rm -f ${tmp_file}
}

#######################################################
# Arguments:
#   $1 - download url
#   $2 - extract dest dir
#   $3 - local file save dir
#   $4 - is extract default :0 extract 1: not extract
#   $5 - download filename
#######################################################
download_and_extract() {

    local src="${1:?src_url is missing}"
    local destdir="${2:?directory is missing}"
    local builddir="${3:?save directory is missing}"
    local is_extract="${4:-0}"
    local filename="${5:-$(basename ${src})}"

    if [[ ! -f ${builddir}/${filename} ]]; then
        info "Downloading ${1}..."
        wget "${src}" -c -O "${builddir}"/"${filename}" --no-check-certificate
    fi
    if [ ! -f "${builddir}"/"${filename}" ]; then
        error "Critical error in download_and_extract() - file download"
        exit 1
    fi
    if [ "$is_extract" -eq 0 ]; then
        info "Extracting ${filename}..."
        mkdir "${destdir}"
        tar xf "${builddir}"/"${filename}" --strip=1 -C "${destdir}" &&
            rm -rf "${builddir:?}"/"${filename}"
    fi
}
