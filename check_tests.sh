#!/bin/env bash

# You can supply the path to the findpick program that is then tested against
# the test cases.
if [[ "${#}" -eq 0 ]]
then
    path_to_fp="./fp"
else
    path_to_fp="${1}"
fi

results () {
    local path="${1}"
    local name=${path##*/test_}
    name=${name%.sh}
    local error_code="${2}"
    local message="${3}"

    printf '\nTest:\t%s\n' "${name}"
    if [[ "${error_code}" -eq 0 ]]
    then
        printf '\tStatus: Pass\n'
        return 0
    else
        printf '\tStatus: Fail\n'
        printf '\tPath: %s\n' "${path}"
        printf '\tError Code: %s\n' "${error_code}"
        printf '\tMessage: %s\n' "${message}"
        exit "${error_code}"
    fi
}

original_path_to_fp="${path_to_fp}"
path_to_fp="${path_to_fp/#~/${HOME}}"
if [[ "${path_to_fp}" =~ / ]]
then
    path_to_fp="$(realpath -e -- "${path_to_fp}")"
else
    path_to_fp="$(command -v -- "${path_to_fp}")"
fi
if [[ "${?}" -ne 0 ]]
then
    printf 'ERROR! findpick path not found\n"%s"\n' "${original_path_to_fp}"
    exit 1
else
    printf '"%s"\n' "${path_to_fp}"
fi

tests_dir="$(realpath -e -- "$(dirname "$0")/tests")"
cd -- "${tests_dir}" || exit 1

for file in "${tests_dir}/test_"*".sh"
do
    message=$(bash -- "${file}" "${path_to_fp}")
    results "${file}" "${?}" "${message}"
done

exit 0
