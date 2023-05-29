#!/bin/env bash

fp="${1}"

case_c_vs_args () {
    by_args_list=$("${fp}" -Mn /usr/bin/*)
    by_c_dir=$("${fp}" -Mn -c /usr/bin)

    if ! [[ "${by_args_list}" = "${by_c_dir}" ]]
    then
        echo "${FUNCNAME[0]}"
        echo "Folder listing does not match files given directly from shell."
        return 1
    fi
    return 0
}

case_c_vs_args          || exit ${?}

exit 0
