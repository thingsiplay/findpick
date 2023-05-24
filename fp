#!/bin/env bash

# Abort on unbound variable, also known as "set -o nounset".
set -u 

# Default settings.  These are active until the corresponding commandline
# options overwrites them.  Lookup in the below show_help section to see their
# purpose and which option belongs to what variable.

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
opt_ignorecase=false
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
findpick v0.2
EOF
}

show_help_notes () {
cat << EOF

[1]  -p will add several "-preview" related options to the -m command.  This is
a feature of "fzf".  Don't use this option when -m is set to any other program.

[2]  -r -b -o are related.  -r runs selection as a command if it's an
executable, otherwise opens file with xdg-open; and waits for finish.  -b will
modify -r to become a background process and detach from terminal.  -o will
write output from executed -r to specified file.  If multiple files run, then
all of them write to same file by appending.  -b will activate -r option too.

[3]  -m can be any shell command or program with arguments.  It should read
newline separated list from stdin and output selected file to stdout.  Current
default command:

    "${opt_menucmd}"

[4]  -d will default to '1' for listing current working directory or starting
point.  If anything is given at FILES, then this will default to '0' if not
explicitly set.  This option controls how many levels deep of subfolders 'find'
should traverse and list files from.

[5]  -t to list files with matching types only.  List can be any combination of
supported flags: b=block, c=character special, d=directory, p=named pipe,
f=regular file, l=symbolic link, s=socket, x=executable (directories are also
executable).  Comma for separation is optiona, such as "-t fx" is equivalent to
"-t f,x".

[6]  -e is a regular expression and used to filter out files like -f option.
But this regex will match whole known body of path including folder parts, not
just name of file.  Known path depends on what is given at commandline.  If
path consists of "./file", then regex cannot match starting at root "/" in
example.  The regex type set for "find" command with "-regextype" is
"posix-extended".

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
  ${pspac} [-o FILE] [-m CMD] [-d NUM] [-t TYPE] [-f PATT] [-e PATT] [-c DIR]
  ${pspac} [--] [FILES...]

General purpose file picker combining "find" command with a fuzzy finder.

positional arguments:
  FILES         path to list files and folders
 
options:
  -h            help: print this help and exit
  -H            notes: print this help, additional notes and exit
  -V            version: print name and version and exit
  -s            stdin: read each line as FILES in addition to positionals
  -a            all: do not hide dotfiles starting with "." in basename
  -l            symlinks: resolve symlinks, expand and test for existing target
  -x            xdev: stay on one filesystem and skip other mounted devices
  -k            kinpath: output relative path from starting point to selection
  -n            name: output basename of file without folder parts
  -p            preview: show box with extra infos in "fzf" menu  [1]
  -i            ignorecase: modifies -f and -e options to be case-insensitive
  -r            run: selection as executable or open with default program  [2]
  -b            background: runs like -r but as a nohup background process  [2]
  -o FILE       output: pipe standard stream from -r or -b process to file  [2]
  -m CMD        menu: command for selection, "fzf", "rofi -dmenu", "head"  [3]
  -d NUM        maxdepth: number of subfolder levels to dig into  [4]
  -t TYPE       type: limit to type of file, d=dir, f=file, e=executable  [5]
  -f PATT       filter: show only files which shell pattern matches basename
  -e PATT       extended: posix-extended regex match at entire known path  [6]
  -c DIR        change: directory of starting point to search files from
  --            stop: parsing options and interpret everything after as FILES

Important: Any option should be listed before positional arguments at FILES.

error code:
  0             success: selected path is printed to stdout
  1             failure: aborted, file not found or any other error

examples:
  \$ ${pname} -l
  \$ ${pname} -d0 -ap -t f -- .vim*
  \$ ${pname} -d2 -rb -c ~/bin -m 'rofi -dmenu'

Copyright © 2023 Tuncay D. <https://github.com/thingsiplay/findpick>'
EOF
}

# OPTIND needs to be reset only, if getopts was called before. The reset here
# is just out of good habit.
OPTIND=1
# After parsing commandline options, the global opt_ variables are updated.
# Anyrhing remaining in "$@" is not an option and can be used otherwise (such
# as positional arguments).
while getopts ':HhVsalxknpirbo:m:d:t:f:e:c:' OPTION 
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
        c)  opt_changedir="${OPTARG}" ;;
        ?)  continue ;;
        *)  show_help >&2
            exit 1
            ;;
    esac
done
# Discard the options and sentinel --
shift "$((OPTIND-1))"

# Read each line into an array used as files.
declare -a stdin=()
if [[ "${opt_stdin}" = 'true' ]] 
then
    mapfile -t stdin
fi

# Expand leading tilde to current users home. And don't allow empty start
# directory.
if test -z "${opt_changedir}"
then
    opt_changedir="."
else
    opt_changedir="${opt_changedir/#\~/${HOME}}"
fi

# Normally this "opt_output" path variable is empty.  Either it is set directly
# or is set automatically when options "-b" or "-r" are set.
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
        # Delete file for fresh start.  However later when multiple programs
        # run, each of their output will be saved to same file by redirecting
        # ">>" to append.  'touch' to check for permission.
        touch -- "${opt_output}" || exit 1 && rm -- "${opt_output}"
fi

# Current working directory is changed, so files are searched starting from
# this position.
cd "${opt_changedir}" || exit 1

# Used with 'find' command.  '-L' follows symbolic links and check destination
# for existence.  '-P' never follow links (default behaviour).
if [ "${opt_symlinks}" = 'true' ] 
then
    symlinks='-L'
else
    symlinks='-P'
fi

# Do not descend into directories of other filesystems for 'find' command.
# '-mount' and '-xdev' options from 'find' have the same effect.
if [ "${opt_xdev}" = 'true' ] 
then
    xdev='-xdev'
else
    xdev=''
fi

# Show or hide hidden dot files.  This pattern is used with '-name' option at
# 'find' command.
if [[ "${opt_all}" = 'true' ]] 
then
    all_pattern='*'
else
    all_pattern='[^.]*'
fi

# Set case-sensitivity mode for regex or shell pattern at options '-e' and
# '-f'.
if [[ "${opt_ignorecase}" = 'true' ]] 
then
    filter_mode='-iname'
    extended_mode='-iregex'
else
    filter_mode='-name'
    extended_mode='-regex'
fi

# Filters all files out which does not match on 'find' command.  Used together
# with 'filter_mode'.
if [[ "${opt_filter}" = '' ]] 
then
    filter_pattern='*'
else
    filter_pattern="${opt_filter}"
fi

# Filters all files out which does not match on 'find' command.  Used together
# with 'extended_mode'.
if [[ "${opt_extended}" = '' ]] 
then
    extended_pattern='.*'
else
    extended_pattern="${opt_extended}"
fi

# Default value for depth when no files are given is '1', so the starting point
# will be listed.  If any files or folders are given at positional arguments,
# then don't list folders content, just list the explicitly given names from
# commandline.
if [[ "${opt_maxdepth}" = '' ]]
then
    if [[ "${#}" -eq 0 ]]
    then
        opt_maxdepth=1
    else
        opt_maxdepth=0
    fi
fi

# Following block will update the script option and set a new variable.  These
# are used with find to limit listing to certain filetypes.
x_type=""
if ! [[ "${opt_type}" = '' ]] 
then
    opt_type="${opt_type//,/}"
    # List of allowed flags (minus the comma, which was just removed prior and
    # will be added later).
    if ! [[ ${opt_type} =~ ^[bcdpflsx]+$ ]] 
    then
        exit 1
    elif [[ ${opt_type} =~ x ]] 
    then
        # The flag 'x' in the find option '-type' is not supported and requires
        # a completley different option instead.  So it will be removed from
        # list of flags and the other appropriate option is set instead.
        opt_type="${opt_type/x/}"
        x_type='-executable'
    else
        x_type=''
    fi

    # Any remaining character is a valid flag for '-type' or '-xtype' option at
    # find command.
    if ! [[ "${opt_type}" = '' ]] 
    then
        # These options for 'find' command requires a comma for each flag.
        # This converts something like 'fx' into 'f,x' in example.
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

# Only positive numbers are allowed.
if ! [[ ${opt_maxdepth} =~ ^[0-9]+$ ]]
then
    exit 1
fi

# Generate a newline separated and sorted list of files.  Strip out needless
# front "./" and last slash for directories.  Do not quote the free standing
# variables such as 'opt_type'.
files="$(find "${symlinks}" \
                -O3 \
                "${@}" "${stdin[@]}" \
                -readable \
                -nowarn \
                -maxdepth "${opt_maxdepth}" \
                ${xdev} \
                ${opt_type} \
                ${x_type} \
                -name "${all_pattern}" \
                "${filter_mode}" "${filter_pattern}" \
                -regextype posix-extended \
                "${extended_mode}" "${extended_pattern}" \
                -print \
                2>/dev/null)"

if ! [[ "${files}" =~ \\w ]] 
then
    files=$(printf '%s' "${files}" \
               | sed 's+^./++' \
               | sed 's+/$++' \
               | sort)
else
    exit 1
fi

# Show a menu or pick a file otherwise from the list of files generated
# previously.  The preview functionality for 'fzf' is added only, if option
# '-p' from commandline is in effect.  The preview will show path, filetype and
# content of any text file too.
selected=""
if [[ "${opt_preview}" = 'true' ]] 
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

# If nothing was fround with prior command 'find' or nothing is selected in the
# menu, then an empty selection should be treated as error.
if [ "${selected}" = '' ] 
then
    exit 1
fi

# Usually the user selection consists of single entry.  But it is possible to
# have multiple selections.  Therefore each of the newline separated entries
# must be handled individually.  Any error of the commands should exit script
# immadiately.
while IFS= read -r path
do
    if [[ "${opt_symlinks}" = 'true' ]] 
    then
        path=$(readlink --canonicalize-existing --no-newline --quiet \
               -- "${path}")
        if [ "${path}" = '' ] 
        then
            exit 1
        fi
    fi

    if [[ "${opt_name}" = 'true' ]] 
    then
        # Output filename without directory part.
        printf '%s\n' "${path##*/}" \
            || exit 1
    elif [[ "${opt_kinpath}" = 'true' ]] 
    then
        # Calculate relative path from defined start directory until selection.
        change=$(readlink --canonicalize-existing --no-newline --quiet \
                   -- "${opt_changedir}")
        realpath --relative-to="${change}" --no-symlinks --quiet -- "${path}" \
            || exit 1
    elif [[ "${opt_symlinks}" = 'false' ]] 
    then
        # Output fullpath as fallback if no symlinks are checked.
        realpath --canonicalize-missing --no-symlinks --quiet -- "${path}" \
            || exit 1
    else
        # Just output path, as it is extended to an absolute path by 'readlink'
        # command, because 'opt_symlinks' is active at this point.
        printf '%s\n' "${path}" \
            || exit 1
    fi

    # Depending on the file type, either open with default application or
    # execute the selection as a command.  As a background process, nohup will
    # detach it from the current terminal and write output to a file instead.
    # Don't create a new file each time output is written, as multiple
    # applications can be selected with script.
    if [[ "${opt_run}" = 'true' ]]
    then
        # Executable file.
        if [[ -f "${path}" && -x "${path}" ]]
        then
            if [[ "${opt_background}" = 'true' ]]
            then
                nohup "${path}" &> "${opt_output}" &
            elif ! [ "${opt_output}" = '/dev/null' ]
            then
                "${path}" &>> "${opt_output}"
            else
                "${path}"
            fi
        # Any other filetype.
        else
            if [[ "${opt_background}" = 'true' ]]
            then
                nohup xdg-open "${path}" &> "${opt_output}" &
            elif ! [ "${opt_output}" = '/dev/null' ]
            then
                xdg-open "${path}" &>> "${opt_output}"
            else
                xdg-open "${path}"
            fi
        fi
    fi
done <<< "${selected}"
