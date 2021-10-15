# utilities

Oh, just some utility programs I wrote.

## Wrapper Utilities

### findd and grepp

Replaced by [fe, the](https://github.com/dse/fe) quick and dirty
[iron searcher](https://github.com/dse/fe).

### tidyy

Wrapper around `tidy`.

Hides certain classes of errors I personally do not care about.

An example of using GNU Bash 4's `corpoc` builtin to filter stderr and
send the results of that filtering back to stderr.

## Perl Related Utilities

### perlallmod

Lists every module you can possibly install, by finding all `.pm`
files in each directory in `@INC`.

Usage:

    perlallmod
    perlallmod -I<directory>

### perlinc

Lists every directory in `@INC`.

Usage:

    perlinc [<modulename> ...]

If no modulenames are specified, this program just prints the default
list of directories.

If one or more modulenames are specified, this program loads those
modules then prints `@INC`.  You would use this for any modules that
added additional directories to `@INC` or whose dependencies do so.

### perlinchash

Print every loaded module and its path.  Include dependencies of every
loaded module.

This just pretty-prints `%INC` after all the modules specified by the
command line arguments are loaded.

Usage:

    perlinchash [<modulename> ...]

If no modulenames are specified, this program will just print the
paths to `warnings` and `strict`.  `:-)`

### perlmodpath

Prints the path to every specified module.

Usage:

    perlmodpath [<modulename> ...]
