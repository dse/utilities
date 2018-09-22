# -*- mode: sh; sh-shell: bash -*-

declare -a directory_excludes
declare -a file_excludes

directory_excludes=(
    vendor
    node_modules
    .git
    .svn
)

file_excludes=(
    # backups
    '*~'
    '#*#'
    '.*~'
    '.#*#'

    # images
    '*.gif'
    '*.jpg'
    '*.jpeg'
    '*.png'
    '*.webp'

    # fonts
    '*.ttf'
    '*.otf'
    '*.ttc'
    '*.woff'
    '*.eot'

    # archives
    '*.zip'
    '*.jar'
    '*.sym'

    # compressed files
    '*.gz'

    # minified/map files
    '*.min'
    '*.min.*'
    '*.css.map'
    '*.js.map'
    '*.min.map'
    'composer.lock'

    # executables and libraries
    '*.exe'
    '*.a'
    '*.o'
    '*.so'
    '*.dll'
    '*.dylib'

    # Legacy Microsoft Office
    '*.doc'
    '*.ppt'
    '*.xls'
)

declare -a find_directory_excludes
declare -a find_file_excludes

set_find_excludes () {
    find_directory_excludes=()
    find_file_excludes=()
    for exclude in "${directory_excludes[@]}" ; do
        if (( ${#find_directory_excludes[@]} )) ; then
            find_directory_excludes+=("-o")
        fi
        find_directory_excludes+=("-iname" "${exclude}")
    done
    for exclude in "${file_excludes[@]}" ; do
        if (( ${#find_file_excludes[@]} )) ; then
            find_file_excludes+=("-o")
        fi
        find_file_excludes+=("-iname" "${exclude}")
    done
}

declare -a grep_directory_excludes
declare -a grep_file_excludes

set_grep_excludes () {
    grep_directory_excludes=()
    grep_file_excludes=()
    for exclude in "${directory_excludes[@]}" ; do
        grep_directory_excludes+=("--exclude-dir=${exclude}")
    done
    for exclude in "${file_excludes[@]}" ; do
        grep_file_excludes+=("--exclude=${exclude}")
    done
}
