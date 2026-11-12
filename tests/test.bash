#!/usr/bin/env bash
set -euo pipefail

if [[ ${1:-} != --inner ]]; then
    repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/work-profiles-test.XXXXXXXX")
    trap 'rm -rf -- "$tmp"' EXIT
    mkdir -p "$tmp/home"
    env -i HOME="$tmp/home" PATH="$PATH" TEST_REPO="$repo" TEST_TMP="$tmp" \
        bash "$repo/tests/test.bash" --inner
    exit
fi

prefix="$TEST_TMP/runtime with spaces"
config="$HOME/.config/work-profile"
printf 'startup sentinel\n' > "$HOME/.bashrc"
bash "$TEST_REPO/install.sh" --prefix "$prefix" > /dev/null
[[ $(cat "$HOME/.bashrc") == 'startup sentinel' ]]
[[ -x $prefix/bin/ssh && -x $prefix/bin/scp && -x $prefix/bin/sftp ]]
[[ ! -e $config/profiles/company ]]

git config --file "$config/profiles/default/gitconfig" user.name 'Personal Tester'
git config --file "$config/profiles/default/gitconfig" user.email personal@example.test
printf 'export GH_TOKEN=personal-test-token\n' > "$config/profiles/default/secrets.env"
cp -R "$TEST_REPO/examples/company" "$config/profiles/company"
mkdir -p "$config/profiles/company/gh"
git config --file "$config/profiles/company/gitconfig" user.name 'Company Tester'
git config --file "$config/profiles/company/gitconfig" user.email company@example.test
printf 'export GITHUB_TOKEN=company-test-token\nexport COMPANY_ONLY=company-value\n' > "$config/profiles/company/secrets.env"

cat > "$config/components.d/50-example.bash" <<'HOOK'
_work_profile_components+=(example)
work_profile_manage_env EXAMPLE_DIR
work_profile_example_activate() { export EXAMPLE_DIR="$WORK_PROFILE_DIR/example"; }
work_profile_example_deactivate() { [[ $EXAMPLE_DIR == "$WORK_PROFILE_DIR/example" ]]; }
HOOK

# Reinstalling must preserve secrets, identities, and extension hooks.
bash "$TEST_REPO/install.sh" --prefix "$prefix" > /dev/null
[[ $(git config --file "$config/profiles/default/gitconfig" user.email) == personal@example.test ]]
[[ $(cat "$config/profiles/default/secrets.env") == 'export GH_TOKEN=personal-test-token' ]]
[[ -f $config/components.d/50-example.bash ]]

# The runtime is designed for ordinary Bash, not nounset shells.
set +u
source "$prefix/init.bash"
[[ $WORK_PROFILE == default && $SSH_PROFILE == default && $GH_TOKEN == personal-test-token ]]
[[ $(git var GIT_AUTHOR_IDENT) == 'Personal Tester <personal@example.test>'* ]]
[[ $GH_CONFIG_DIR == "$config/profiles/default/gh" ]]
work-profile company > /dev/null
[[ $WORK_PROFILE == company && $GH_TOKEN == company-test-token && $COMPANY_ONLY == company-value ]]
[[ $(git var GIT_AUTHOR_IDENT) == 'Company Tester <company@example.test>'* ]]
[[ $EXAMPLE_DIR == "$config/profiles/company/example" ]]
[[ $WORK_PROFILE_SSH_CONFIG == "$HOME/.ssh.company/config" ]]

# A child starts default without changing its parent's company profile.
bash --noprofile --norc -c 'source "$1/init.bash"; [[ $WORK_PROFILE == default && $GH_TOKEN == personal-test-token && ! -v COMPANY_ONLY && ! -v GITHUB_TOKEN ]]' _ "$prefix"
[[ $WORK_PROFILE == company && $GH_TOKEN == company-test-token ]]
ssh-profile default > /dev/null
[[ ! -v COMPANY_ONLY && ! -v GITHUB_TOKEN && $GH_TOKEN == personal-test-token ]]
[[ $(work-profile list) == $'company\ndefault' ]]
if work-profile ../invalid > /dev/null 2>&1; then exit 1; fi
[[ $WORK_PROFILE == default ]]

# Syntax errors are rejected before the previous environment changes.
printf 'if broken\n' > "$config/profiles/company/secrets.env"
if work-profile company > /dev/null 2>&1; then exit 1; fi
[[ $WORK_PROFILE == default && $GH_TOKEN == personal-test-token ]]
printf 'export GITHUB_TOKEN=company-test-token\nexport COMPANY_ONLY=company-value\n' > "$config/profiles/company/secrets.env"
count=${#_work_profile_managed_env[@]}
for ((i=0; i<5; i++)); do work-profile company >/dev/null; work-profile default >/dev/null; done
[[ ${#_work_profile_managed_env[@]} == "$count" ]]

# Validate wrapper routing without making SSH connections.
mkdir -p "$HOME/.ssh" "$HOME/.ssh.company"
printf 'Host profile-test\n    HostName personal.example.test\n' > "$HOME/.ssh/config"
printf 'Host profile-test\n    HostName company.example.test\n' > "$HOME/.ssh.company/config"
# OpenSSH's default home lookup uses passwd, not HOME. Use explicit test configs.
[[ -z $WORK_PROFILE_SSH_CONFIG ]]
printf '%s\n' 'WP_SSH_CONFIG="$HOME/.ssh/config"' > "$config/profiles/default/config.bash"
work-profile default >/dev/null
[[ $(ssh -G profile-test 2>/dev/null | grep '^hostname ') == 'hostname personal.example.test' ]]
work-profile company >/dev/null
[[ $(ssh -G profile-test 2>/dev/null | grep '^hostname ') == 'hostname company.example.test' ]]
[[ $(git config --global --get-all credential.https://github.com.helper | tail -1) == '!gh auth git-credential' ]]

# The installer supports custom configuration locations, too.
bash "$TEST_REPO/install.sh" --prefix "$TEST_TMP/other runtime" --config-dir "$TEST_TMP/other config" > /dev/null
[[ -f $TEST_TMP/other\ config/profiles/default/gitconfig ]]
printf 'PASS: install/reinstall, profile switching, identities, secrets, child shells, hooks, SSH routing, and custom paths\n'
