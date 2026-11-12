_work_profile_components+=(ssh)
work_profile_manage_env SSH_PROFILE WORK_PROFILE_SSH_CONFIG GIT_SSH_COMMAND
work_profile_ssh_activate() {
    export SSH_PROFILE="$WORK_PROFILE"
    export WORK_PROFILE_SSH_CONFIG="${WP_SSH_CONFIG-$HOME/.ssh/config}"
    printf -v GIT_SSH_COMMAND '%q' "$WORK_PROFILE_LIB/bin/ssh"
    export GIT_SSH_COMMAND
}
