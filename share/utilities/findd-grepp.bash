# -*- mode: sh; sh-shell: bash -*-

exclude_from_array () {
    local -n __array="$1"; shift
    local -a __result
    local element
    for element in "${__array[@]}" ; do
        for exclude in "$@" ; do
            if [[ "${element}" == "${exclude}" ]] ; then
                break
            fi
            __result+=("${element}")
        done
    done
    __array=("${__result[@]}")
}

find='find'
grep='grep'
if [[ "$OSTYPE" = "darwin"* ]] && command -v ggrep >/dev/null 2>/dev/null ; then
    # shellcheck disable=SC2034
    grep='ggrep'
fi
if [[ "$OSTYPE" = "darwin"* ]] && command -v gfind >/dev/null 2>/dev/null ; then
    # shellcheck disable=SC2034
    find='gfind'
fi

grepp_exclude_binary_files=0
# 0 for findd by default
# 1 for grepp by default

declare -a directory_excludes
declare -a directory_excludes_binary
declare -a file_excludes
declare -a file_excludes_binary

directory_excludes_binary=(
    zip-cache
)

directory_excludes=(
    'vendor'
    'node_modules'

    # version control
    '.git'
    '.svn'

    # others from emacs grep.el
    'SCCS'
    'RCS'
    'CVS'
    'MCVS'
    '.src'
    '.hg'
    '.bzr'
    '_MTN'
    '_darcs'
    '{arch}'
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

    # Dalvik
    '*.dex'

    # Java
    '*.class'

    # Misc.
    '*.bin'
    '*.lbin'
    '*.flat'

    # Others from emacs grep.el.  I'm assuming these are binary
    # formats.
    '*.ln'
    '*.blg'
    '*.bbl'
    '*.elc'
    '*.lof'
    '*.glo'
    '*.idx'
    '*.lot'
    '*.fmt'
    '*.tfm'
    '*.fas'
    '*.lib'
    '*.mem'
    '*.x86f'
    '*.sparcf'
    '*.dfsl'
    '*.pfsl'
    '*.d64fsl'
    '*.p64fsl'
    '*.lx64fsl'
    '*.lx32fsl'
    '*.dx64fsl'
    '*.dx32fsl'
    '*.fx64fsl'
    '*.fx32fsl'
    '*.sx64fsl'
    '*.sx32fsl'
    '*.wx64fsl'
    '*.wx32fsl'
    '*.fasl'
    '*.ufsl'
    '*.fsl'
    '*.dxl'
    '*.lo'
    '*.la'
    '*.gmo'
    '*.mo'
    '*.toc'
    '*.aux'
    '*.cp'
    '*.fn'
    '*.ky'
    '*.pg'
    '*.tp'
    '*.vr'
    '*.cps'
    '*.fns'
    '*.kys'
    '*.pgs'
    '*.tps'
    '*.vrs'
    '*.pyc'
    '*.pyo'
)

file_excludes=(
    # backups
    '*~'
    '#*#'
    '.*~'
    '.#*'

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
        remove_from_excludes "$i"
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

remove_from_excludes () {
    for i ; do
        exclude_from_array user_directory_excludes "$i"
        exclude_from_array user_file_excludes      "$i"
        exclude_from_array directory_excludes      "$i"
        exclude_from_array file_excludes           "$i"
        exclude_from_array file_excludes_binary    "$i"
    done
}

#------------------------------------------------------------------------------

declare -a find_directory_excludes

_add_find_directory_excludes () {
    local exclude
    for exclude ; do
        if (( ${#find_directory_excludes[@]} )) ; then
            find_directory_excludes+=("-o")
        fi
        find_directory_excludes+=("-iname" "${exclude}")
    done
}

set_find_directory_excludes () {
    find_directory_excludes=()
    _add_find_directory_excludes "${directory_excludes[@]}" \
                                 "${user_directory_excludes[@]}"
    if (( grepp_exclude_binary_files )) ; then
        _add_find_directory_excludes "${directory_excludes_binary[@]}"
    fi
}

declare -a find_file_excludes

_add_find_file_excludes () {
    local exclude
    for exclude ; do
        if (( ${#find_file_excludes[@]} )) ; then
            find_file_excludes+=("-o")
        fi
        find_file_excludes+=("-iname" "${exclude}")
    done
}

set_find_file_excludes () {
    find_file_excludes=()
    _add_find_file_excludes "${file_excludes[@]}" \
                            "${user_file_excludes[@]}"
    if (( grepp_exclude_binary_files )) ; then
        _add_find_file_excludes "${file_excludes_binary[@]}"
    fi
}

set_find_excludes () {
    set_find_directory_excludes
    set_find_file_excludes
}

declare -a grep_directory_excludes

_add_grep_directory_excludes () {
    local lc uc
    local exclude
    for exclude ; do
        lc="${exclude,,}"
        uc="${exclude^^}"
        grep_directory_excludes+=("--exclude-dir=${lc}")
        grep_directory_excludes+=("--exclude-dir=${uc}")
        if [[ "${exclude}" != "${lc}" ]] && [[ "${exclude}" != "${uc}" ]] ; then
            grep_directory_excludes+=("--exclude-dir=${exclude}")
        fi
    done
}

set_grep_directory_excludes () {
    grep_directory_excludes=()
    _add_grep_directory_excludes "${directory_excludes[@]}" \
                                 "${user_directory_excludes[@]}"
    if (( grepp_exclude_binary_files )) ; then
        _add_grep_directory_excludes "${directory_excludes_binary[@]}"
    fi
}

declare -a grep_file_excludes

_add_grep_file_excludes () {
    local lc uc
    local exclude
    for exclude ; do
        lc="${exclude,,}"
        uc="${exclude^^}"
        grep_file_excludes+=("--exclude=${lc}")
        grep_file_excludes+=("--exclude=${uc}")
        if [[ "${exclude}" != "${lc}" ]] && [[ "${exclude}" != "${uc}" ]] ; then
            grep_file_excludes+=("--exclude=${exclude}")
        fi
    done
}

set_grep_file_excludes () {
    grep_file_excludes=()
    _add_grep_file_excludes "${file_excludes[@]}" "${user_file_excludes[@]}"
    if (( grepp_exclude_binary_files )) ; then
        _add_grep_file_excludes "${file_excludes_binary[@]}"
    fi
}

set_grep_excludes () {
    set_grep_directory_excludes
    set_grep_file_excludes
}

#------------------------------------------------------------------------------

declare -a diff_excludes
declare -a git_diff_excludes

set_diff_excludes () {
    diff_excludes=()
    for exclude in "${file_excludes[@]}" "${user_file_excludes[@]}" ; do
        lc="${exclude,,}"
        uc="${exclude^^}"
        diff_excludes+=("--exclude=${lc}")
        diff_excludes+=("--exclude=${uc}")
        git_diff_excludes+=(":(exclude,icase)${lc}")
        if [[ "${exclude}" != "${lc}" ]] && [[ "${exclude}" != "${uc}" ]] ; then
            diff_excludes+=("--exclude=${exclude}")
        fi
    done
    if (( grepp_exclude_binary_files )) ; then
        for exclude in "${file_excludes_binary[@]}" ; do
            lc="${exclude,,}"
            uc="${exclude^^}"
            diff_excludes+=("--exclude=${lc}")
            diff_excludes+=("--exclude=${uc}")
            git_diff_excludes+=(":(exclude,icase)${lc}")
            if [[ "${exclude}" != "${lc}" ]] && [[ "${exclude}" != "${uc}" ]] ; then
                diff_excludes+=("--exclude=${exclude}")
            fi
        done
    fi
    for exclude in "${directory_excludes[@]}" "${user_directory_excludes[@]}" ; do
        lc="${exclude,,}"
        uc="${exclude^^}"
        diff_excludes+=("--exclude=${lc}")
        diff_excludes+=("--exclude=${uc}")
        git_diff_excludes+=(":(exclude,icase)${lc}")
        if [[ "${exclude}" != "${lc}" ]] && [[ "${exclude}" != "${uc}" ]] ; then
            diff_excludes+=("--exclude=${exclude}")
        fi
    done
}

#------------------------------------------------------------------------------

# with indentation for find
echo_command () {
    local i
    local has_indent=0
    local is_find=0
    local indent_string=''
    local last_nl=1
    local this_nl=1
    # shellcheck disable=SC2154
    if (( verbose >= 2 || (dry_run && verbose >= 1 ) )) ; then
        i="$1"; shift
        echo "- ${i@Q}"
        i="$(basename "$i")"
        if [[ "$i" == "find" ]] || [[ "$i" == "gfind" ]] || [[ "$i" == "findd" ]] ; then
            has_indent=1
            is_find=1
        fi
        for i ; do
            this_nl=1
            if (( is_find )) ; then
                case "$i" in
                    "!"|"-iname"|"-name"|"-type"|"-o")
                        this_nl=0
                        ;;
                esac
            fi
            if (( has_indent )) && [[ "$i" == ")" ]] ; then
                indent_string="${indent_string#  }"
            fi
            if (( last_nl )) ; then
                echo -n "[  ${indent_string}]"
            fi
            if (( this_nl )) ; then
                printf "%q\n" "$i"
            else
                printf "%q " "$i"
            fi
            if (( has_indent )) && [[ "$i" == "(" ]] ; then
                indent_string="${indent_string}  "
            fi
            last_nl="${this_nl}"
        done
    elif (( verbose >= 1 || dry_run )) ; then
        >&2 echo "${@@Q}"
    fi
}
