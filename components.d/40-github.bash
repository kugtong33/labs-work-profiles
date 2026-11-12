_work_profile_components+=(github)
work_profile_manage_env GH_CONFIG_DIR GH_TOKEN GITHUB_TOKEN GITHUB_PERSONAL_ACCESS_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN GH_HOST
work_profile_github_activate() {
    export GH_CONFIG_DIR="$WORK_PROFILE_DIR/gh"
    # Prefer GH_TOKEN; accept either of the other common variable names.
    if [[ -z ${GH_TOKEN:-} ]]; then
        if [[ -n ${GITHUB_TOKEN:-} ]]; then
            export GH_TOKEN="$GITHUB_TOKEN"
        elif [[ -n ${GITHUB_PERSONAL_ACCESS_TOKEN:-} ]]; then
            export GH_TOKEN="$GITHUB_PERSONAL_ACCESS_TOKEN"
        fi
    fi
}
