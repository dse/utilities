# utilities

Oh, just some utility programs I wrote.

## Wrapper Utilities

### findd

Wrapper around `find`.

Used by `grepp`, which see below.

Excludes binary files.

Excludes generated files from source code that is typically also in
the project.  When refactoring or troubleshooting, you usually only
want to grep the source code.

Accepts all GNU find options, and the following additional options:

- `--verbose` --- print commands to stderr before running them.

- `--dry-run` --- print commands to stderr but do not run them.

### grepp

Wrapper around `grep`.

Excludes binary and generated files, like `findd`, which see above.

Automatically specifies `-r` if there are no filename arguments,
allowing you to just say:

    grepp <string>

Accepts all GNU grep options, and the following additional options:

- `--min-depth=LEVEL` --- run `findd` with `-mindepth`.

- `--max-depth=LEVEL` --- run `findd` with `-maxdepth`.

- `--no-excludes`

- `--css-class=CLASSNAME` --- print lines containing an HTML tag with
  a `class` attribute specifying the `CLASSNAME`.

- `--non-ascii` --- print lines matching `[^\x00-\x7f]`.  You might
  use this to find unescaped non-ASCII-safe ISO Latin 1 or UTF-8.

- `--non-ascii-printable` --- print lines matching `[^[:print:]\r\t]`.
  You might use this to find errant control characters.

- `--verbose` --- print commands to stderr before running them.

- `--dry-run` --- print commands to stderr but do not run them.

`grepp` is rather simplistic.  This is fine because I can wrap my head
around it.  If you want something more complex:

- [https://beyondgrep.com/](`ack-grep`)

- [https://geoff.greer.fm/ag/](`ag`, the Silver Searcher)

- [https://github.com/BurntSushi/ripgrep](`ripgrep`)

- [https://sift-tool.org/](`sift`)

- [https://github.com/monochromegane/the_platinum_searcher](`pt`, the Platinum Searcher)

- Other tools listed in:

  - <https://beyondgrep.com/more-tools/>
  - <https://github.com/BurntSushi/ripgrep#quick-examples-comparing-tools>

- `git grep`

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
