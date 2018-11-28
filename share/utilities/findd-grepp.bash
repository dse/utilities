# -*- mode: sh; sh-shell: bash -*-

grepp_exclude_binary_files=0
# 0 for findd by default
# 1 for grepp by default

declare -a directory_excludes
declare -a file_excludes
declare -a file_excludes_binary

directory_excludes=(
    vendor
    node_modules
    .git
    .svn
)

file_excludes_binary=(
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

    # Media
    '*.mov'
    '*.m4a'
    '*.qt'
    '*.wma'
    '*.mp3'
    '*.m4r'
    '*.flv'
    '*.wmv'
    '*.swf'
)

file_excludes=(
    # backups
    '*~'
    '#*#'
    '.*~'
    '.#*#'

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
)

declare -a user_directory_excludes
declare -a user_directory_includes
declare -a user_file_excludes
declare -a user_file_includes

user_directory_excludes=()
user_directory_includes=()
user_file_excludes=()
user_file_includes=()

add_user_exclude () {
    local i
    for i ; do
        i="${i,,}"              # lowercase
        user_directory_excludes+=("$i")
        user_file_excludes+=("$i")
    done
}

add_user_include () {
    local i
    for i ; do
        i="${i,,}"              # lowercase
        user_directory_includes+=("$i")
        user_file_includes+=("$i")
    done
}

#------------------------------------------------------------------------------

declare -a find_directory_excludes

set_find_directory_excludes () {
    find_directory_excludes=()
    for exclude in "${directory_excludes[@]}" "${user_directory_excludes[@]}" ; do
        if (( ${#find_directory_excludes[@]} )) ; then
            find_directory_excludes+=("-o")
        fi
        find_directory_excludes+=("-iname" "${exclude}")
    done
}

declare -a find_file_excludes

set_find_file_excludes () {
    find_file_excludes=()
    for exclude in "${file_excludes[@]}" "${user_file_excludes[@]}" ; do
        if (( ${#find_file_excludes[@]} )) ; then
            find_file_excludes+=("-o")
        fi
        find_file_excludes+=("-iname" "${exclude}")
    done
    if (( grepp_exclude_binary_files )) ; then
        for exclude in "${file_excludes_binary[@]}" ; do
            if (( ${#find_file_excludes[@]} )) ; then
                find_file_excludes+=("-o")
            fi
            find_file_excludes+=("-iname" "${exclude}")
        done
    fi
}

set_find_excludes () {
    set_find_directory_excludes
    set_find_file_excludes
}

declare -a grep_directory_excludes

set_grep_directory_excludes () {
    grep_directory_excludes=()
    for exclude in "${directory_excludes[@]}" "${user_directory_excludes[@]}" ; do
        grep_directory_excludes+=("--exclude-dir=${exclude}")
    done
}

declare -a grep_file_excludes

set_grep_file_excludes () {
    grep_file_excludes=()
    for exclude in "${file_excludes[@]}" "${user_file_excludes[@]}" ; do
        grep_file_excludes+=("--exclude=${exclude}")
    done
    if (( grepp_exclude_binary_files )) ; then
        for exclude in "${file_excludes_binary[@]}" ; do
            grep_file_excludes+=("--exclude=${exclude}")
        done
    fi
}

set_grep_excludes () {
    set_grep_directory_excludes
    set_grep_file_excludes
}
