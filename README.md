# Findpick

General purpose file picker combining "find" command with a fuzzy finder.

- Author: Tuncay D.
- Source: https://github.com/thingsiplay/findpick
- License: [MIT License](LICENSE)

# Introduction

Output absolute fullpath of selected file. A frontend script to list files by
[find](https://www.man7.org/linux/man-pages/man1/find.1.html) command, generate
an interactive menu with [fzf](https://github.com/junegunn/fzf),
[rofi](https://github.com/davatorium/rofi) or other alike tools and choose an
entry. Intended use case is similar to file picker dialogs in desktop
environments, but with a search bar instead navigating through filesystem.
While `fzf` has first class support, other menu builder or filters can be used
instead too. 

## Why?

This program started out rather simple as an alias. My goal was to combine the
search with a fuzzy finder menu and extend the output to an absolute path. The
many options and complex nature of `find` and the other commands made it hard
to remember how everything worked. To make things easier with simple flags, I
needed to create a separate script. And here we are.

# Requirements

Required GNU/Linux utilities, depending on what commandline options are enabled:

```
bash find touch rm cat sed sort ls file readlink realpath nohup xdg-open
```

In example [nohup](https://www.man7.org/linux/man-pages/man1/nohup.1.html) or
[xdg-open](https://linux.die.net/man/1/xdg-open) won't be needed, if the option
`-r` isn't set at all. So these programs aren't hard requirements, rather soft
requirements the moment they are called.

Optional program used for menu generation by default with `-m` command:

```
fzf
```

# Installation

Download the project directly from Github:

```
$ git clone https://github.com/thingsiplay/findpick
$ cd findpick
```
    
Now make the main program `fp` executable and put the file into a folder in the
`$PATH` for easy access. Or run the script `suggested_install.sh` to automate
the installation process:

```
$ bash suggested_install.sh
```

## Packages

Depending on your OS, some of the tools might be not installed on your system.
After downloading and installing the main program from Github, you still need
the required utilities to run the script. Here is a list of commands for
various Linux distributions, to get the most basic packages with the required
tools installed:

### Arch

```
$ sudo pacman -S bash coreutils base-devel xdg-utils fzf
```

# Usage
  
```
usage: fp [OPTIONS] [FILES...]
```

## How to use commandline options

Bash's internal function
[getopts](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/html_node/Bourne-Shell-Builtins.html#index-getopts)
is used to parse options. (Note: Not to be confused with the standalone program
`getopt`, which is a totally different parser and not part of Bash.)

Due to parser restrictions in Bash, there are only short form of OPTIONS like
`-h`. Long form such as `--help` are not supported. OPTIONS in general start
with a single dash `-` followed by a letter. They are either standalones like
`-h` or with an additional argument such as `-c DIR`. OPTIONS can be combined
too; in example `-p -t x -c bin` is equivalent to `-ptx -cbin`.

FILES are positional arguments, meaning one or more paths to files and folders.
These aren't OPTIONS and therefore don't start with a dash `-`. FILES must be
given after any OPTIONS in the commandline, otherwise the option parser gets
confused. Use double dash `--` to stop parsing OPTIONS and indicate that
everything after the double dash is a file or folder.

If no FILES is given, then either the content of current working directory or
the one set by `-c DIR` is listed. However if any FILES is given, then only
those explicitly given files are listed and not their subfolders. Use wildcards
or set the `-d` option manually to traverse any level of subfolders.

Use `fp -h` to list all options and their brief description.

## Examples

### Default

List all files and folders in current working directory, which don't start with
a dot:

```
$ fp
```

### All

List all files and folders, including dot files starting with a "." in name:

```
$ fp -a
```

### Directories

List only directories and show a preview box in `fzf` for every file. Note, the
option `-p` only works with `fzf`:

```
$ fp -p -td
```

### Vim dotfiles

Resolve symlinks to their target and check if the target file exists. List all
files (including dot files) in current working directy which start with ".vim",
without going into folders and reading their content:

```
$ fp -al -- .vim*
```
    
### Rofi
    
Search and list files up to 3 levels deep in folder structure. And use an
alternate menu system `rofi` instead of `fzf`:

```
$ fp -d3 -m 'rofi -dmenu' 
```

### Filter

Change current working directory to home directory "~". Filter out all files
which do not start with letter "b" or "p" using [shell
pattern](https://www.gnu.org/software/findutils/manual/html_node/find_html/Shell-Pattern-Matching.html)
syntax, similar to how it works in Bash. Only the basename part after last
slash "/" of the path is compared. The filter is case-sensitive at default, but
in this case option `-i` is set to make it case-insensitive.

```
$ fp -c ~ -i -f '[bp]*'
```

### Regex

Similar to prior example, but with [posix-extended regular
expression](https://www.gnu.org/software/findutils/manual/html_node/find_html/posix_002dextended-regular-expression-syntax.html)
instead.

A regex filter with `-e PATTERN` compares entire known path with all directory
parts, not only at basename. However this highly depends on what part of the
path is known at start time. Any commandline input receiving relative paths
will also be seen as incomplete path for the regex filter. That means if
program is invoked like `fp ~/Downloads/*`, then at start time the regex filter
can "see" entire absolute path and match starting from root "/". But if
commandline was invoked like `fp Downloads/*`, then the resulting paths are
relative and the regex filter cannot match on other parts than filename.

For demonstration purposes the next example is composed to mimic the output
from previous example and match on basename part only.

```
$ fp -c ~ -i -e '.*/[bp][^/]*$'
```

### Randomizer

The interactive menu is replaced by a randomizer, which shuffles all found
files and output them together. Then the program ends, but its output is piped
into a different program `head` to read the first entry.

```
$ fp -d3 -m 'sort -R' | head -n1
```

### Stdin

Standard input stream can be read with `-s`. Each newline separated file is
equivalent to FILES from commandline arguments. In this example `grep` is
configured to output filenames and paths only. The resulting list is piped to
`fp`, which then any symlink is is expanded, due to `-l` option.

```
grep --no-messages --files-with-matches -im1 -F 'LICENSE' -- ~/bin/* | fp -spl

```

### Run

Option `-tfx` lists executable files only. Run the selected entry as a command
if it's an executable, or open the file with it's associated default
application. `-b` is here similar to `-r`, but executes the process in the
background without waiting. The output of the command is written to specified
file, otherwise will be output to stdout.

```
$ fp -c ~/bin -tfx -bo '~/output.txt'
```

Running commands and programs with `-r` or `-b` can be problematic in some
situations, such as if the selected script or program waits for an input. Or
if it does some unusual things. So be careful. BTW multiple selections can
be executed as well and even output to same file. In such a case temporary
files are written and deleted before combining into output file.

### No Menu

You can also defeat the purpose of this program and just not use a menu at all.
Output every path without selection by disabling the menu with `-M` or giving
an empty value with `-m ''` (note the space between `m` and the quotes `''`).
Be careful combining this with execution options such as `-r` and `-b`, as
potentially thousands of programs could run at the same time.

```
$ fp -M *
```
