# Per-shell work profiles. Source this file; do not execute it.
if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 2))); then
    printf 'work-profiles requires Bash 4.2 or newer.\n' >&2
    return 1
fi
WORK_PROFILE_LIB=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
WORK_PROFILE_HOME="${WORK_PROFILE_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/work-profile}"
declare -ga _work_profile_components=()
# Keep ownership across re-sourcing, including assignments removed from disk.
declare -ga _work_profile_managed_env

# Components must register every environment variable they own.
work_profile_manage_env() {
    local name existing found
    for name in "$@"; do
        [[ $name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ && $name != WORK_PROFILE_MANAGED_ENV ]] || return 2
        found=false
        for existing in "${_work_profile_managed_env[@]}"; do
            [[ $existing != "$name" ]] || {
                found=true
                break
            }
        done
        $found || _work_profile_managed_env+=("$name")
    done
    # Only names cross process boundaries, never credential values.
    printf -v WORK_PROFILE_MANAGED_ENV '%s ' "${_work_profile_managed_env[@]}"
    export WORK_PROFILE_MANAGED_ENV
    return 0
}

_work_profile_restore_managed_env() {
    local inherited_name
    local -a inherited_names=()
    IFS=' ' read -r -a inherited_names <<<"${WORK_PROFILE_MANAGED_ENV:-}"
    for inherited_name in "${inherited_names[@]}"; do
        work_profile_manage_env "$inherited_name" || return
    done
}
_work_profile_restore_managed_env || return

# Secrets files use one NAME=value or export NAME=value assignment per line.
_work_profile_scan_env() {
    local line
    [[ -r $1 ]] || return 0
    while IFS= read -r line || [[ -n $line ]]; do
        if [[ $line =~ ^[[:space:]]*(export[[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*)= ]]; then
            work_profile_manage_env "${BASH_REMATCH[2]}" || return
        fi
    done <"$1"
}

_work_profile_switch() {
    local name=$1 component file
    local dir="$WORK_PROFILE_HOME/profiles/$1"
    [[ $name =~ ^[a-zA-Z0-9][a-zA-Z0-9_-]*$ && -d $dir ]] || {
        printf 'Unknown work profile: %s\n' "$name" >&2
        return 2
    }
    for file in "$dir/config.bash" "$dir/secrets.env"; do
        [[ ! -e $file ]] || { bash -n "$file" || return; }
    done
    # Parse includes before clearing credentials or changing the active profile.
    if [[ -e $dir/gitconfig || -L $dir/gitconfig ]]; then
        git config --includes --file "$dir/gitconfig" --list >/dev/null || return
    fi
    # Scan all profiles, including on startup, to clear inherited credentials.
    for file in "$WORK_PROFILE_HOME"/profiles/*/secrets.env; do
        _work_profile_scan_env "$file" || return
    done
    # An inherited WORK_PROFILE does not mean hooks ran in this shell.
    if [[ ${_work_profile_initialized:-} == true ]]; then
        for component in "${_work_profile_components[@]}"; do
            if declare -F "work_profile_${component}_deactivate" >/dev/null; then
                "work_profile_${component}_deactivate" || return
            fi
        done
    fi
    for name in "${_work_profile_managed_env[@]}"; do unset "$name"; done
    # Reset profile settings before loading the selected profile.
    unset WP_SSH_CONFIG
    export WORK_PROFILE="$1"
    WORK_PROFILE_DIR=$dir
    [[ ! -r $dir/config.bash ]] || source "$dir/config.bash" || return
    for component in "${_work_profile_components[@]}"; do
        "work_profile_${component}_activate" || {
            printf 'Failed to activate component %s for %s\n' "$component" "$WORK_PROFILE" >&2
            return 1
        }
    done
    _work_profile_initialized=true
}

work-profile() {
    case "${1:-}" in
    '') printf 'Work profile: %s\n' "$WORK_PROFILE" ;;
    list | --list)
        local dir
        for dir in "$WORK_PROFILE_HOME"/profiles/*; do
            [[ ! -d $dir ]] || printf '%s\n' "${dir##*/}"
        done
        ;;
    help | -h | --help)
        printf 'Usage: work-profile [NAME|list]\nProfiles apply to this shell and its child processes.\n'
        ;;
    *) _work_profile_switch "$1" && printf 'Work profile: %s\n' "$WORK_PROFILE" ;;
    esac
}

# Backward-compatible command: now switches all components together.
ssh-profile() { work-profile "$@"; }

_work_profile_component_files=()
for _work_profile_file in "$WORK_PROFILE_LIB"/components.d/*.bash; do
    [[ -e $_work_profile_file || -L $_work_profile_file ]] || continue
    _work_profile_component_files+=("$_work_profile_file")
done
# Built-in filenames are reserved; existing installations may still have copies.
for _work_profile_file in "$WORK_PROFILE_HOME"/components.d/*.bash; do
    [[ -e $_work_profile_file || -L $_work_profile_file ]] || continue
    [[ ! -e $WORK_PROFILE_LIB/components.d/${_work_profile_file##*/} ]] || continue
    _work_profile_component_files+=("$_work_profile_file")
done
# Preflight the entire set before executing any component. Keep source at the
# top level so declarations in trusted extensions retain their original scope.
for _work_profile_file in "${_work_profile_component_files[@]}"; do
    if [[ ! -f $_work_profile_file || ! -r $_work_profile_file ]]; then
        printf 'Cannot read component: %s\n' "$_work_profile_file" >&2
        unset _work_profile_file _work_profile_component_files
        return 1
    fi
    bash -n "$_work_profile_file" || {
        unset _work_profile_file _work_profile_component_files
        return 1
    }
done
for _work_profile_file in "${_work_profile_component_files[@]}"; do
    if source "$_work_profile_file"; then
        :
    else
        _work_profile_status=$?
        printf 'Failed to load component %s (status %s)\n' "$_work_profile_file" "$_work_profile_status" >&2
        unset _work_profile_file _work_profile_component_files
        return "$_work_profile_status"
    fi
done
unset _work_profile_file _work_profile_component_files _work_profile_status
case ":$PATH:" in
*":$WORK_PROFILE_LIB/bin:"*) ;;
*) export PATH="$WORK_PROFILE_LIB/bin:$PATH" ;;
esac
_work_profile_complete() {
    local dir
    COMPREPLY=()
    for dir in "$WORK_PROFILE_HOME"/profiles/*; do
        [[ -d $dir && ${dir##*/} == "${COMP_WORDS[COMP_CWORD]}"* ]] && COMPREPLY+=("${dir##*/}")
    done
    return 0
}
complete -F _work_profile_complete work-profile ssh-profile

# New terminals always start in default, even when launched from an Opexa shell.
_work_profile_switch default
