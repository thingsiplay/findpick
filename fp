#!/bin/env bash

# Abort on unbound variable, also known as "set -o nounset".
set -u 

# Default settings.  These are active until the corresponding commandline
# options overwrites them.  Lookup in the below show_help section to see their
# purpose and which option belongs to what variable.
#
# 'opt_menucmd' Must be a program reading stdin as list and output to stdout.
opt_menucmd='fzf --reverse --multi --cycle --scheme=path'
# Empty 'opt_changedir' defaults to current working dir.
opt_changedir=''

# Below default settings shouldn't be touched by the end user.
# Empty 'opt_maxdepth' is automatic detection.
opt_maxdepth=''
opt_type=''
opt_filter=''
opt_extended=''
opt_grep=''
opt_ignorecase=false
opt_nomenu=false
opt_stdin=false
opt_all=false
opt_symlinks=false
opt_xdev=false
opt_kinpath=false
opt_name=false
opt_preview=false
opt_run=false
opt_background=false
# Empty 'opt_output' defaults to '/dev/null' if run options are enabled.
opt_output=''

show_version () {
cat << EOF
findpick v0.4
EOF
}

show_help_notes () {
cat << EOF

[1]  -p will add several "-preview" related options to the -m command.  This is
a feature of "fzf".  Don't use this option when -m is set to any other program.

[2]  -r -b -o are related.  -r runs selection as a command if it's an
executable, otherwise opens file with xdg-open; and waits to finish.  -b runs
too, but instead as a background process detached from terminal and does not
wait.  -o will write output of process into specifid file in realtime.  If
multiple processes run, then each output is written at once with a delay after
process finishes.

[3]  -m can be any shell command or program with arguments.  It should read
newline separated list from stdin and output selected file to stdout. An empty
menu command as '-m ""' or option -M as a shortcut will just output everything
without user interaction.  Current default command:

    "${opt_menucmd}"

[4]  -g search and limit results to files, whose content matches the pattern.
Pattern is an 'extended-regexp' regular expression for standalone grep command
(also known as "grep -E").  As a side-effect all directories and binary files
are excluded; only text files are processed and listed.  Symbolic links are not
resolved for this particular search, even if option -l is in effect.
Case-sensitivity is affected by and can be turned off with option -i.

[5]  -d will default to '1' for listing current working directory or starting
point.  If anything is given at FILES, then this will default to '0' if not
explicitly set.  This option controls how many levels deep of subfolders 'find'
should traverse and list files from.

[6]  -t to list files with matching types only.  List can be any combination of
supported flags: b=block, c=character special, d=directory, p=named pipe,
f=regular file, l=symbolic link, s=socket, x=executable (directories are also
executable), t=text file (uses grep to determine format).  Comma for separation
is optional, such as "-t fx" is equivalent to "-t f,x".

[7]  -e a "posix-extended" regular expression to filter out files similar to
-f.  But regex matches whole known path body, including it's folder parts with
slashes too.  Known path depends on what was given as input.  If path consists
of "./file", then regex cannot match root "/", but it would at "/bin/grep".

EOF
}

show_help () {
    local pname
    local pspac
    pname="${0##*/}"
    pspac="$(printf '%s' "${pname}" | sed 's/./ /g')"

cat << EOF
usage:
  ${pname} [OPTIONS] [FILES...]

  ${pname} [-h | -H | -V] [-s] [-a] [-l] [-x] [-k | -n] [-p] [-i] [-r] [-b]
  ${pspac} [-M] [-g PATT]
  ${pspac} [-o FILE] [-m CMD] [-d NUM] [-t TYPE] [-f PATT] [-e PATT] [-c DIR]
  ${pspac} [--] [FILES...]

General purpose file picker combining "find" command with a fuzzy finder.

positional arguments:
  FILES         path to list files and folders
 
options:
  -h            help: print this help and exit
  -H            notes: print this help, additional notes and exit
  -V            version: print name, version and exit
  -s            stdin: read each line from stdin stream as a FILES path
  -a            all: do not hide dotfiles starting with "." in basename
  -l            symlinks: resolve symlinks, expand and test for existing target
  -x            xdev: stay on one filesystem and skip other mounted devices
  -k            kinpath: output relative path from starting point to selection
  -n            name: output basename of file without folder parts
  -p            preview: show box with extra infos in "fzf" menu  [1]
  -i            ignorecase: modifies -f, -e and -g to be case-insensitive
  -r            run: selection as executable or open with default program  [2]
  -b            background: runs like -r but as a nohup background process  [2]
  -o FILE       output: pipe standard stream from -r or -b process to file  [2]
  -m CMD        menu: command for selection, "fzf", "rofi -dmenu", "head"  [3]
  -M            nomenu: disable menu command -m and output everything [3]
  -g PATT       grep: extended-regexp filter to match text file content [4]
  -d NUM        maxdepth: number of subfolder levels to dig into  [5]
  -t TYPE       type: limit to d=dir, f=file, t=text, e=executable  [6]
  -f PATT       filter: show only files which shell pattern matches basename
  -e PATT       extended: posix-extended regex match at entire known path  [7]
  -c DIR        change: directory of starting point to search files from
  --            stop: parsing options and interpret everything after as FILES

Important: Any option should be listed before positional arguments at FILES.

error code:
  0             success: selected path is printed to stdout
  1             failure: aborted, file not found or any other error

examples:
  \$ ${pname} -l
  \$ ${pname} -d0 -ap -t f -- .vim*
  \$ ${pname} -d2 -b -c ~/bin -m 'rofi -dmenu'

Copyright © 2023 Tuncay D. <https://github.com/thingsiplay/findpick>'
EOF
}

# OPTIND needs to be reset only, if getopts was called before. The reset here
# is just out of good habit.
OPTIND=1
# After parsing commandline options, the global opt_ variables are updated.
# Anything remaining in "$@" is not an option and can be used otherwise (such
# as positional arguments).
while getopts ':HhVsalxknpiMrbo:m:d:t:f:e:g:c:' OPTION
do
    case "${OPTION}" in
        H)  show_help
            show_help_notes
            exit 0
            ;;
        h)  show_help
            exit 0
            ;;
        V)  show_version
            exit 0
            ;;
        s)  opt_stdin=true ;;
        a)  opt_all=true ;;
        l)  opt_symlinks=true ;;
        x)  opt_xdev=true ;;
        k)  opt_kinpath=true ;;
        n)  opt_name=true ;;
        p)  opt_preview=true ;;
        i)  opt_ignorecase=true ;;
        M)  opt_nomenu=true ;;
        r)  opt_run=true
            if [ "${opt_output}" == "" ]
            then
                opt_output='/dev/null'
            fi
            ;;
        b)  opt_background=true
            opt_run=true
            if [ "${opt_output}" == "" ]
            then
                opt_output='/dev/null'
            fi
            ;;
        o)  opt_output="${OPTARG}" ;;
        m)  opt_menucmd="${OPTARG}" ;;
        d)  opt_maxdepth="${OPTARG}" ;;
        t)  opt_type="${OPTARG}" ;;
        f)  opt_filter="${OPTARG}" ;;
        e)  opt_extended="${OPTARG}" ;;
        g)  opt_grep="${OPTARG}" ;;
        c)  opt_changedir="${OPTARG}" ;;
        *)  show_help >&2
            exit 1
            ;;
    esac
done
# Discard the options and sentinel --
shift "$((OPTIND-1))"

# Read each line from stdin stream into an array, to be combined with
# positional arguments at later point.
declare -a stdin=()
if [[ "${opt_stdin}" = 'true' ]]
then
    mapfile -t stdin
fi

if test -z "${opt_changedir}"
then
    opt_changedir="."
else
    opt_changedir="${opt_changedir/#\~/${HOME}}"
fi

# Normally this "opt_output" path variable is empty.  Either it is set directly
# or is set automatically when run options '-r' or '-b' are set.
if ! test -z "${opt_output}" && ! [ "${opt_output}" = '/dev/null' ]
then
        opt_output="$(readlink --canonicalize-missing --no-newline --quiet \
                      -- "${opt_output//\~/${HOME}}")"
        # Don't allow any wildcard in output name, to minimize the risk of
        # accidents with later "rm" command.
        if [[ ${opt_output} =~ [][*?] ]]
        then
            exit 1
        fi
        # touch to check permissions.  Delete file for fresh start.
        touch -- "${opt_output}" || exit 1 && rm -- "${opt_output}"
fi

cd "${opt_changedir}" || exit 1

# 'find' option '-L' follows and checks destination of symbolic links, while
# '-P' never follows.
if [ "${opt_symlinks}" = 'true' ]
then
    symlinks='-L'
else
    symlinks='-P'
fi

# 'find' option '-xdev' to not descend into directories of other filesystems.
# '-mount' is a synonym for '-xdev'.
if [ "${opt_xdev}" = 'true' ]
then
    xdev='-xdev'
else
    xdev=''
fi

# 'find' option '-name' to simulate hidden dot files like 'ls' at default.
if [[ "${opt_all}" = 'true' ]]
then
    all_pattern='*'
else
    all_pattern='[^.]*'
fi

# case-sensitivity mode for 'filter_pattern' and 'extended_pattern'.
if [[ "${opt_ignorecase}" = 'true' ]]
then
    filter_mode='-iname'
    extended_mode='-iregex'
else
    filter_mode='-name'
    extended_mode='-regex'
fi

# 'find' option '-name' or '-iname' to filter out files with shell pattern,
# depending on scripts 'filter_mode' variable.
if [[ "${opt_filter}" = '' ]]
then
    filter_pattern='*'
else
    filter_pattern="${opt_filter}"
fi

# 'find' option '-regex' or '-iregex' to filter out files with regular
# expression, depending on scripts 'extended_mode' variable.
if [[ "${opt_extended}" = '' ]]
then
    extended_pattern='.*'
else
    extended_pattern="${opt_extended}"
fi

# 'grep' option to ignore case for '--extended-regexp' pattern matching.
if [[ "${opt_ignorecase}" = 'true' ]]
then
    grep_ignorecase='--ignore-case'
else
    grep_ignorecase='--no-ignore-case'
fi

# 'find' option '-maxdepth' to limit levels of folder structure to access.
# Default is '1' if no positional arguments or stdin is in use.  '0' means
# to list only what is given as input, otherwise '1' is intended to list all
# files of current active start directory.
if [[ "${opt_maxdepth}" = '' ]]
then
    # We could test the stdin part with '${#stdin[@]} -eq 0' instead, like
    # positional arguments.  But then empty input stream such as output from
    # `echo /x=mc2` would default to maxdepth=1, which is not what we want.
    if [[ ${#} -eq 0 ]] && [[ "${opt_stdin}" = 'false' ]]
    then
        opt_maxdepth=1
    else
        opt_maxdepth=0
    fi
fi

# 'find' option '-type' and '-xtype' to list specified filetypes only.
executable_type=""
if ! [[ "${opt_type}" = '' ]]
then
    opt_type="${opt_type//,/}"
    # List of allowed flags (minus the comma, which was just removed prior and
    # will be added later).
    if ! [[ ${opt_type} =~ ^[bcdpflsxt]+$ ]]
    then
        exit 1
    fi

    if [[ ${opt_type} =~ x ]]
    then
        # The flag 'x' in 'find' option '-type' is not supported and requires a
        # completley different option instead.  Remove it from list and set the
        # other appropriate option instead.
        opt_type="${opt_type/x/}"
        executable_type='-executable'
    else
        executable_type=''
    fi

    if [[ ${opt_type} =~ t ]]
    then
        # The flag 't' in 'find' option '-type' is not supported and requires a
        # completley different option instead.  Remove it from list and set the
        # other appropriate option instead.
        opt_type="${opt_type/t/}"
        if [[ "${opt_grep}" = '' ]]
        then
            opt_grep='.'
        fi
    fi

    # Any remaining character is a valid flag for '-type' or '-xtype' option at
    # 'find' command.
    if ! [[ "${opt_type}" = '' ]]
    then
        # These options for 'find' command requires a comma for each flag.
        # This puts a comma between each flag.
        opt_type="$(printf '%s' "${opt_type}" | sed 's/./&,/g')"
        opt_type=${opt_type%,}

        # '-type' option from 'find' does not check target of symbolic link,
        # while '-xtype' follow and resolve to destination.
        if [ "${opt_symlinks}" = 'false' ]
        then
            opt_type='-type '"${opt_type}"
        else
            opt_type='-xtype '"${opt_type}"
        fi
    fi
fi

if ! [[ ${opt_maxdepth} =~ ^[0-9]+$ ]]
then
    exit 1
fi

# Apply search and generate a newline separated and sorted list of files.
# Strip out needless front "./" and last slash for directories.  Do not quote
# the free standing variables such as 'opt_type' in the command chain below,
# but make sure they are valid options and don't interfere with the commandline
# arguments to 'find'.
#
# The positional arguments and stdin array with filenames starting with a dash
# will confuse 'find'.  Therefore any leading filename starting with a "-" is
# a relative path and a "./" can be added safely to it's front.
files="$(find "${symlinks}" \
                -O3 \
                "${@/#-/.\/-}" "${stdin[@]/#-/.\/-}" \
                -readable \
                -nowarn \
                -maxdepth "${opt_maxdepth}" \
                ${xdev} \
                ${opt_type} \
                ${executable_type} \
                -name "${all_pattern}" \
                "${filter_mode}" "${filter_pattern}" \
                -regextype posix-extended \
                "${extended_mode}" "${extended_pattern}" \
                -print \
        2>/dev/null)"

# Quit early if nothing is found.
if [[ "${files}" =~ \\w ]]
then
    exit 1
fi

files=$(printf '%s' "${files}" \
           | sed 's+^./++' \
           | sed 's+/$++' \
           | sort)

if ! [[ "${opt_grep}" = '' ]]
then
    readarray -t array_files <<<"${files}"
    files=$(grep --color=never --no-messages --files-with-matches \
            --directories=skip --binary-files=without-match --max-count=1 \
            ${grep_ignorecase} \
            --extended-regexp "${opt_grep}" \
            -- "${array_files[@]}")
fi

# Now open menu (or any other streaming command set with 'opt_menucmd') with
# all list of files from previous 'find' search as input.  The result should be
# one or more selected files separated by newline.  The preview branch is build
# specifically for 'fzf' command and should not be enabled with any other
# command.
selected=""
if [[ "${opt_menucmd}" = '' ]] || [[ "${opt_nomenu}" = 'true' ]]
then
    selected="${files}"
elif [[ "${opt_preview}" = 'true' ]]
then

    preview_file () {
        local path
        local ftype
        local links

        # Function argument 2 should match scripts option 'opt_symlinks' for
        # consistency.
        links="${2}"

        if [[ "${links}" = 'true' ]]
        then
            path="$(readlink --canonicalize --no-newline --quiet -- "${1}")"
        else
            path="$(realpath --no-symlinks --quiet -- "${1}")"
        fi

        ftype="$(file -b --mime -- "${path}")"
        printf '%s:\n%s\n\n' "${path}" "${ftype}"

        if [[ ${ftype} =~ text/ || ${ftype} =~ charset=us-ascii ]]
        then
            cat --number -- "${path}"
        elif [ "${ftype}" == 'inode/directory; charset=binary' ]
        then
            # C=columns, F=classify
            ls --almost-all --ignore-backups -C -F -- "${path}"
        fi
    }
    export -f preview_file

    selected="$(printf '%s' "${files}" \
                | ${opt_menucmd} \
                  --preview-label="${opt_changedir}" \
                  --preview-window='down:40%,wrap' \
                  --preview="preview_file {} \"${opt_symlinks}\"")"
else
    selected="$(printf '%s' "${files}" | ${opt_menucmd})"
fi

if [ "${selected}" = '' ]
then
    exit 1
fi

# Usually the user selection consists of single entry.  But it is possible to
# have multiple selections.  Therefore each of the newline separated entries
# must be handled individually.  Any error of the commands should exit script
# immadiately.
#
# In case multiple selections are made and options '-r' or '-b' will run
# multiple programs, then the resulting file will be written with delay only
# when the programs finish.  We need 'echo' here, each entry has its own
# newline and 'printf' would result in '0' for one entry.
num_selections=$(echo "${selected}" | wc -l)

while IFS= read -r path
do
    if [[ "${opt_symlinks}" = 'true' ]]
    then
        # /absolute/path/Filename.txt
        path=$(readlink --canonicalize-existing --no-newline --quiet \
               -- "${path}")
        if [ "${path}" = '' ]
        then
            exit 1
        fi
    fi

    if [[ "${opt_name}" = 'true' ]]
    then
        # Filename.txt
        # Do not save the output to 'path' yet, as the potential directory parts
        # of the path are needed.
        printf '%s\n' "${path##*/}" \
               || exit 1
   elif [[ "${opt_kinpath}" = 'true' ]]
    then
        # ../path/Filename.txt
        change=$(readlink --canonicalize-existing --no-newline --quiet \
                          -- "${opt_changedir}")
        path=$(realpath --relative-to="${change}" --no-symlinks --quiet \
                        -- "${path}") \
               || exit 1
    elif [[ "${opt_symlinks}" = 'false' ]]
    then
        # /absolute/path/Filename.txt
        path=$(realpath --canonicalize-missing --no-symlinks --quiet \
                        -- "${path}") \
               || exit 1
    fi

    if [[ "${opt_name}" = 'false' ]]
    then
        # ../path/Filename.txt
        # or
        # /absolute/path/Filename.txt
        printf '%s\n' "${path}" || exit 1
    fi

    # Depending on the file type, either open with default application or
    # execute the selection as a command.  As a background process, nohup will
    # detach it from the current terminal and write output to a file instead.
    # Don't create a new file each time output is written, as multiple
    # applications can be selected with script.
    if [[ "${opt_run}" = 'true' ]]
    then
        if ! [[ "${path}" =~ ^/ ]]
        then
            # /absolute/path/Filename.txt
            path=$(realpath --canonicalize-missing --no-symlinks --quiet \
                            -- "${path}")
        fi
        # Executable file.
        if [[ -f "${path}" && -x "${path}" ]]
        then
            if [[ "${opt_background}" = 'true' ]]
            then
                if [[ ${num_selections} -eq 1 ]]
                then
                    nohup "${path}" &>> "${opt_output}" &
                else
                    tempfile=$(mktemp -p '/dev/shm/')
                    nohup "${path}" &> "${tempfile}" \
                        && cat "${tempfile}" >> "${opt_output}" \
                        && rm -f -- "${tempfile}" &
                fi
            elif ! [ "${opt_output}" = '/dev/null' ]
            then
                if [[ ${num_selections} -eq 1 ]]
                then
                    "${path}" &>> "${opt_output}"
                else
                    tempfile=$(mktemp -p '/dev/shm/')
                    trap "rm -f -- \"${tempfile}\"" EXIT
                    "${path}" &> "${tempfile}" \
                        && cat "${tempfile}" >> "${opt_output}" \
                        && rm -f -- "${tempfile}"
                fi
            else
                "${path}"
            fi
        # Any other filetype.
        else
            if [[ "${opt_background}" = 'true' ]]
            then
                if [[ ${num_selections} -eq 1 ]]
                then
                    nohup xdg-open "${path}" &>> "${opt_output}" &
                else
                    tempfile=$(mktemp -p '/dev/shm/')
                    nohup xdg-open "${path}" &> "${tempfile}" \
                        && cat "${tempfile}" >> "${opt_output}" \
                        && rm -f -- "${tempfile}" &
                fi
            elif ! [ "${opt_output}" = '/dev/null' ]
            then
                if [[ ${num_selections} -eq 1 ]]
                then
                    xdg-open "${path}" &>> "${opt_output}"
                else
                    tempfile=$(mktemp -p '/dev/shm/')
                    trap "rm -f -- \"${tempfile}\"" EXIT
                    xdg-open "${path}" &> "${tempfile}" \
                        && cat "${tempfile}" >> "${opt_output}" \
                        && rm -f -- "${tempfile}"
                fi
            else
                xdg-open "${path}"
            fi
        fi
    fi
done <<< "${selected}"
