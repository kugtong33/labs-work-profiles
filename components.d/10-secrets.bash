_work_profile_components+=(secrets)
work_profile_secrets_activate() {
    [[ -r $WORK_PROFILE_DIR/secrets.env ]] || return 0
    source "$WORK_PROFILE_DIR/secrets.env"
}
