_work_profile_components+=(git)
work_profile_manage_env GIT_CONFIG_GLOBAL GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
work_profile_git_activate() {
    export GIT_CONFIG_GLOBAL="$WORK_PROFILE_DIR/gitconfig"
    # Also override repository-local identities, matching the old ssh-profile.
    local name email status
    if name=$(git config --includes --file "$GIT_CONFIG_GLOBAL" --get user.name); then
        :
    else
        status=$?
        [[ $status == 1 ]] || return "$status"
        name=''
    fi
    if email=$(git config --includes --file "$GIT_CONFIG_GLOBAL" --get user.email); then
        :
    else
        status=$?
        [[ $status == 1 ]] || return "$status"
        email=''
    fi
    if [[ -n $name ]]; then
        export GIT_AUTHOR_NAME="$name" GIT_COMMITTER_NAME="$name"
    fi
    if [[ -n $email ]]; then
        export GIT_AUTHOR_EMAIL="$email" GIT_COMMITTER_EMAIL="$email"
    fi
    return 0
}
