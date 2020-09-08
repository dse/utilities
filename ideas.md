## Double Space Separated Interchange Format

This format is intended for display to users as well as for computerized processing.

-   A sequence of zero or more double-space-separated fields, terminated by \<cr>\<lf> or \<lf>
-   A sequence of **two or more** spaces is the separator.
-   Last line, if one or more characters, needs not be terminated.
-   Escapes:
    -   Empty string is represented by \<>
    -   A leading or terminating space in a field is represented by \<sp>
    -   Two or more spaces in a field are represented by \<sp>\<sp>...
    -   Backslash is represented by \\
    -   Control characters are escaped as below.

## Control Character Escapes

-   `\x00` through `\xff`
-   `\u0000` through `\uffff`
-   `\x{0}` through `\x{10ffff}`
-   `\u{0}` through `\u{10ffff}`
-   `\"`
-   `` \` ``
-   `\\`
-   `\0`  `\<nul>`
-   `\a`  `\<bel>`
-   `\b`  `\<bs>`
-   `\e`  `\<esc>`
-   `\f`  `\<ff>`
-   `\n`  `\<lf>`
-   `\r`  `\<cr>`
-   `\t`  `\<tab>`  `\<ht>`
-   `\v`  `\<vt>`
-   `\<del>`

$ ls
.
..
.profile
bin
example.md
$ ls -p
name=.;...
name=..
name=.profile
name=bin
name=example.md
$ ls -p|show name,size,type
name.;size=0;type=dir
name=..;size=0;type=dir
name=.profile;size=2013;type=file
name=bin;size=0;type=dir
name=example.md;size=139;type=file
$ ls -p|show name,size,type|table



# escapes:
# \<space> \\ \x{ff} \u{1f4a9} \" \'
# characters that trigger use of quotes and escapes:
#   - U+0000 through U+001F; U+007F
#   - U+0022 QUOTATION MARK
#   - U+0027 APOSTROPHE
#   - U+005C REVERSE SOLIDUS
#   - U+0020 SPACE [quotes]
#   - U+002B SEMICOLON [quotes]
# escape sequences:
#   - \x00 through \x1f; \x7f
#   - \"
#   - \'
#   - \\

# type=file
# type=dir
# type=symlink
# type=block
# type=char
# type=fifo
# type=socket
# type=door (solaris)


$ ls|show name
bin
example.rstink
$ ls|show name,size
bin  0
example.rstink  103
$

total 25
drwxr-xr-x+ 1 501475791 Domain Users    0 Feb 28 15:19 bin
-rw-r--r--  1 501475791 Domain Users  103 Aug 23  2019 example.rstink
drwxr-xr-x+ 1 501475791 Domain Users    0 Jan  7  2019 lib
drwxr-xr-x+ 1 501475791 Domain Users    0 Feb 27 22:10 new-bin
-rw-r--r--  1 501475791 Domain Users 1607 Oct  9  2018 perlcalc.patch
-rw-r--r--  1 501475791 Domain Users 3430 Aug 24  2018 README.md
drwxr-xr-x+ 1 501475791 Domain Users    0 Aug  6  2018 share

```

# meow

# moo
