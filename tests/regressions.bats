#!/usr/bin/env bats
# Fixture variables are assigned in setup; child scripts expand their own env.
# shellcheck disable=SC2016

setup() {
    : "${BATS_TEST_DIRNAME:?}" "${BATS_TEST_TMPDIR:?}"
    export TEST_REPO
    TEST_REPO=$(cd -- "$BATS_TEST_DIRNAME/.." && pwd -P)
    export TEST_HOME="$BATS_TEST_TMPDIR/home"
    export TEST_RUNTIME="$BATS_TEST_TMPDIR/runtime with spaces"
    export TEST_CONFIG="$TEST_HOME/.config/work-profile"
    mkdir -p "$TEST_HOME"
    clean_bash "$TEST_REPO/install.sh" --prefix "$TEST_RUNTIME" >/dev/null
    mkdir -p "$TEST_CONFIG/profiles/company"
    cp "$TEST_REPO/examples/default/gitconfig" "$TEST_CONFIG/profiles/company/gitconfig"
    printf 'export REVIEW_SERVICE_TOKEN=fake-token\n' >"$TEST_CONFIG/profiles/company/secrets.env"
}

clean_bash() {
    env -i HOME="$TEST_HOME" PATH=/usr/local/bin:/usr/bin:/bin \
        TMPDIR="$BATS_TEST_TMPDIR" LC_ALL=C LANG=C TZ=UTC \
        GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
        TEST_REPO="$TEST_REPO" TEST_RUNTIME="$TEST_RUNTIME" TEST_CONFIG="$TEST_CONFIG" \
        bash --noprofile --norc "$@"
}

@test "re-sourcing clears credentials whose assignments were removed" {
    run clean_bash -c '
        source "$TEST_RUNTIME/init.bash" || exit
        work-profile company >/dev/null || exit
        printf "# assignment removed\n" > "$TEST_CONFIG/profiles/company/secrets.env"
        source "$TEST_RUNTIME/init.bash" || exit
        [[ $WORK_PROFILE == default && ! -v REVIEW_SERVICE_TOKEN ]]
    '
    [ "$status" -eq 0 ]
}

@test "child initialization clears removed credential assignments" {
    run clean_bash -c '
        source "$TEST_RUNTIME/init.bash" || exit
        work-profile company >/dev/null || exit
        printf "# assignment removed\n" > "$TEST_CONFIG/profiles/company/secrets.env"
        bash --noprofile --norc -c '\''
            source "$TEST_RUNTIME/init.bash" || exit
            [[ $WORK_PROFILE == default && ! -v REVIEW_SERVICE_TOKEN ]]
        '\''
    '
    [ "$status" -eq 0 ]
}

@test "child initialization clears credentials from a deleted profile" {
    run clean_bash -c '
        source "$TEST_RUNTIME/init.bash" || exit
        work-profile company >/dev/null || exit
        rm -rf -- "$TEST_CONFIG/profiles/company"
        bash --noprofile --norc -c '\''
            source "$TEST_RUNTIME/init.bash" || exit
            [[ $WORK_PROFILE == default && ! -v REVIEW_SERVICE_TOKEN ]]
        '\''
    '
    [ "$status" -eq 0 ]
}

@test "ownership survives repeated initialization without clearing unrelated env" {
    run clean_bash -c '
        export UNRELATED_SETTING=keep
        source "$TEST_RUNTIME/init.bash" || exit
        work-profile company >/dev/null || exit
        count=${#_work_profile_managed_env[@]}
        source "$TEST_RUNTIME/init.bash" || exit
        source "$TEST_RUNTIME/init.bash" || exit
        [[ ${#_work_profile_managed_env[@]} == "$count" && $UNRELATED_SETTING == keep ]] || exit 1
        [[ $WORK_PROFILE_MANAGED_ENV == *REVIEW_SERVICE_TOKEN* && $WORK_PROFILE_MANAGED_ENV != *fake-token* ]]
    '
    [ "$status" -eq 0 ]
}

@test "included Git identity overrides repository-local identity" {
    run clean_bash -c '
        profile="$TEST_CONFIG/profiles/company"
        printf "[user]\n name = Profile User\n email = profile@example.test\n" > "$profile/identity.gitconfig"
        printf "[include]\n path = identity.gitconfig\n" > "$profile/gitconfig"
        mkdir "$HOME/repository"
        git -C "$HOME/repository" init -q || exit
        git -C "$HOME/repository" config user.name "Other User" || exit
        git -C "$HOME/repository" config user.email other@example.test || exit
        source "$TEST_RUNTIME/init.bash" || exit
        work-profile company >/dev/null || exit
        [[ $GIT_AUTHOR_NAME == "Profile User" && $GIT_COMMITTER_NAME == "Profile User" ]] || exit 1
        [[ $GIT_AUTHOR_EMAIL == profile@example.test && $GIT_COMMITTER_EMAIL == profile@example.test ]] || exit 1
        [[ $(git -C "$HOME/repository" var GIT_AUTHOR_IDENT) == "Profile User <profile@example.test> "* ]]
    '
    [ "$status" -eq 0 ]
}

@test "malformed included Git config is rejected before changing active state" {
    run clean_bash -c '
        source "$TEST_RUNTIME/init.bash" || exit
        old_config=$GIT_CONFIG_GLOBAL
        printf "[include]\n path = broken.gitconfig\n" > "$TEST_CONFIG/profiles/company/gitconfig"
        printf "[broken\n" > "$TEST_CONFIG/profiles/company/broken.gitconfig"
        work-profile company >/dev/null 2>&1
        result=$?
        [[ $result != 0 && $WORK_PROFILE == default && $GIT_CONFIG_GLOBAL == "$old_config" ]]
    '
    [ "$status" -eq 0 ]
}

@test "an unconfigured Git identity remains supported" {
    run clean_bash -c '
        source "$TEST_RUNTIME/init.bash" || exit
        [[ $WORK_PROFILE == default && ! -v GIT_AUTHOR_NAME && ! -v GIT_AUTHOR_EMAIL ]]
    '
    [ "$status" -eq 0 ]
}

@test "custom component load failure propagates its status" {
    printf 'return 42\n' >"$TEST_CONFIG/components.d/50-failing.bash"
    run clean_bash -c 'source "$TEST_RUNTIME/init.bash"'
    [ "$status" -eq 42 ]
    [[ $output == *50-failing.bash* ]]
}

@test "built-in component load failure propagates its status" {
    printf 'return 23\n' >"$TEST_RUNTIME/components.d/20-ssh.bash"
    run clean_bash -c 'source "$TEST_RUNTIME/init.bash"'
    [ "$status" -eq 23 ]
    [[ $output == *20-ssh.bash* ]]
}

@test "all component syntax is checked before any component executes" {
    printf 'printf loaded >"$HOME/component-loaded"\n' >"$TEST_CONFIG/components.d/50-sentinel.bash"
    printf 'if broken\n' >"$TEST_CONFIG/components.d/60-broken.bash"
    run clean_bash -c 'source "$TEST_RUNTIME/init.bash"'
    [ "$status" -ne 0 ]
    [ ! -e "$TEST_HOME/component-loaded" ]
}
