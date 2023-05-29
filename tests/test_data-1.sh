#!/bin/env bash

fp="${1}"

case_args () {
    files=$("${fp}" -M "data-1/"*)
    line_count="$(echo "${files}" | wc -l)"

    if ! [[ "${line_count}" = 4 ]]
    then
        echo "${FUNCNAME[0]}"
        echo "Wrong number of files with arguments."
        return "${line_count}"
    fi
    return 0
}

case_args_all () {
    files=$("${fp}" -M -a "data-1/"*)
    line_count="$(echo "${files}" | wc -l)"

    if ! [[ "${line_count}" = 4 ]]
    then
        echo "${FUNCNAME[0]}"
        echo "Wrong number of all files with arguments."
        return "${line_count}"
    fi
    return 0
}

case_c_all () {
    files=$("${fp}" -M -a -c "data-1")
    line_count="$(echo "${files}" | wc -l)"

    if ! [[ "${line_count}" = 6 ]]
    then
        echo "${FUNCNAME[0]}"
        echo "Wrong number of all files with changedir."
        return "${line_count}"
    fi
    return 0
}

case_tfx () {
    files=$("${fp}" -M -tfx -c "data-1")
    line_count="$(echo "${files}" | wc -l)"

    if ! [[ "${line_count}" = 1 ]]
    then
        echo "${FUNCNAME[0]}"
        echo "Wrong number of all executables regular files."
        return "${line_count}"
    fi
    return 0
}

case_tx_all () {
    files=$("${fp}" -M -a -tx -c "data-1")
    line_count="$(echo "${files}" | wc -l)"

    if ! [[ "${line_count}" = 4 ]]
    then
        echo "${FUNCNAME[0]}"
        echo "Wrong number of all executables from all files."
        return "${line_count}"
    fi
    return 0
}

case_leading_dash () {
    files=$("${fp}" -M -c "data-1" -- "-New Empty File")
    line_count="$(echo "${files}" | wc -l)"

    if ! [[ "${line_count}" = 1 ]]
    then
        echo "${FUNCNAME[0]}"
        echo "Filename starting with leading dash '-' not found."
        return "${line_count}"
    fi
    return 0
}

chmod -x "data-1/"*
chmod +x "data-1/folder -with dash"
chmod +x "data-1/hello.sh"
chmod +x "data-1/link to hello"

case_args               || exit ${?}
case_args_all           || exit ${?}
case_c_all              || exit ${?}
case_tfx                || exit ${?}
case_tx_all             || exit ${?}
case_leading_dash       || exit ${?}

exit 0
