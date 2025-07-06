#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
shopt -s lastpipe

main () {
    if (( $# != 1 )) ; then
        echo "$0: incorrect number of arguments" >&2
        exit 1
    fi

    source="$(realpath "${1}")"
    if [[ -d "${source}" ]] ; then
        source_dir="${source}"
    elif [[ -f "${source}" ]] ; then
        source_dir="$(dirname "${source}")"
    else
        echo "$0: ${source}: neither directory nor regular file" >&2
        exit 1
    fi

    if git_root="$(git -C "${source_dir}" rev-parse --show-toplevel 2>&-)" ; then
        source_dir="$(realpath "${git_root}/..")"
    else
        source_dir="$(realpath "${source_dir}/..")"
    fi

    sum="$(echo "${source}" | sha1sum | awk '{print $1}')"
    target="${source_dir}/.gdiff/${sum}"
    mkdir -p "$(dirname "${target}")"
    rm -f -r "${target}" || true
    if [[ -f "${source}" ]] ; then
        ln "${source}" "${target}"
    elif [[ -d "${source}" ]] ; then
        mkdir -p "${target}"
        idx=$(( ${#source} + 1 ))
        find "${source}" \
             -xdev \
             "${exclude_dirs[@]}" \
             "${exclude_files[@]}" \
            | while read source_filename ; do
            if [[ "${source}" = "${source_filename}" ]] ; then
                continue
            fi
            rel="${source_filename:${idx}}"
            target_filename="${target}/${rel}"
            rm -f -r "${target_filename}" || true
            if [[ -d "${source_filename}" ]] ; then
                mkdir -p "${target_filename}"
            elif [[ -f "${source_filename}" ]] ; then
                ln "${source_filename}" "${target_filename}"
            fi
        done
    fi
    echo "${target}"
}

declare -a exclude_dirs=()
declare -a exclude_files=()

exclude_dirs () {
    local i
    for i ; do
        exclude_dirs+=( \! \( -type d -name "$i" -prune \) )
    done
}

exclude_files () {
    local i
    for i ; do
        exclude_files+=( \! \( -type d -name "$i" -prune \) )
    done
}

exclude_dirs .git
exclude_dirs node_modules
exclude_dirs '*.tmp'
exclude_dirs '.gidff'

exclude_dirs '*~'
exclude_dirs '#*#'
exclude_dirs '.*~'
exclude_dirs '.#*'
exclude_dirs '*.tmp'

main "$@"
