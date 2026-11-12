# lab-work-profiles

Switch your work context in one Bash terminal: **SSH, Git identity/configuration,
GitHub CLI/API authentication, and service credentials**. Add components for
future services without changing the switcher.

```bash
work-profile company
work-profile default
work-profile list
```

Profiles affect the current shell and processes started from it. Other terminals
are unchanged. New shells always start on `default`, including shells launched
from a company-profile terminal. `ssh-profile` is a compatibility alias that
switches the entire work profile.

## Requirements

- Linux or another Unix-like system with **Bash 4.2+**, Git, OpenSSH, and standard
  utilities (`install`, `mkdir`, `ln`). macOS's bundled Bash 3 is unsupported;
  install a newer Bash first.
- [GitHub CLI (`gh`)](https://cli.github.com/) for GitHub API access and Git HTTPS
  credentials. The switcher itself does not call GitHub over the network.
- No root access required. Bash is the supported shell; not Zsh, Fish, or `sh`.

## Installation

Clone this repository, then run:

```bash
cd lab-work-profiles
bash install.sh
```

The installer prints two lines to add to `~/.bashrc`. With default locations:

```bash
export WORK_PROFILE_HOME="$HOME/.config/work-profile"
source "$HOME/.local/share/work-profiles/init.bash"
```

Add them after your other `PATH` setup, then open a new terminal or source those
two lines in your current terminal. **Replace any previous `ssh-profile.bash` or
`work-profile/init.bash` source line** rather than loading both systems. Remove
unconditional `source ~/.secrets` lines; profile secrets must not load globally.

The installer does not edit shell startup files, copy your credentials, create
SSH keys, or authenticate accounts. It creates a blank `default` profile and
preserves existing profile settings, secrets, and extension hooks on reinstall.
Installed runtime files are updated. Existing terminals use the old loaded code
until you source the new entry point or reopen them.

Custom paths are supported (use absolute paths):

```bash
bash install.sh --prefix "$HOME/.local/share/work-profiles" \
  --config-dir "$HOME/.config/work-profile"
```

Defaults honor `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `WORK_PROFILE_HOME`. Use
the exact startup lines printed by the installer for your chosen paths.

## Setup

### 1. Configure your default Git identity

```bash
git config --file "$WORK_PROFILE_HOME/profiles/default/gitconfig" user.name 'Your Name'
git config --file "$WORK_PROFILE_HOME/profiles/default/gitconfig" user.email 'you@example.com'
work-profile default
```

Each profile selects its own global Git configuration using `GIT_CONFIG_GLOBAL`.
The existing `~/.gitconfig` is not modified and is not automatically included.
Copy any shared settings you need into each profile, or use a Git `[include]`.
Name/email, including values from Git `[include]` files, are also exported as Git
author/committer variables, overriding repository-local identities.
Other repository-local Git settings retain their
normal precedence. An unconfigured profile leaves identity resolution to Git.

### 2. Configure GitHub access

Either edit the profile's private `secrets.env` using your editor:

```bash
${EDITOR:-vi} "$WORK_PROFILE_HOME/profiles/default/secrets.env"
```

Add `export GH_TOKEN='your-token'`, save, and run `work-profile default` again.
Never paste a real token into a shell command or commit it to this repository.

Or log in interactively after selecting the profile:

```bash
work-profile default
gh auth login
```

Each profile sets a separate `GH_CONFIG_DIR`. Environment tokens override stored
CLI logins. Supported token aliases are `GH_TOKEN` (preferred), `GITHUB_TOKEN`, and
`GITHUB_PERSONAL_ACCESS_TOKEN`. The example Git configs use `gh auth git-credential`
for GitHub HTTPS; Git SSH remotes use the profile's SSH configuration instead.

Verify the account without displaying its token:

```bash
gh api user --jq .login
git var GIT_AUTHOR_IDENT
```

### 3. Add a company profile

Run from this repository:

```bash
mkdir -p "$WORK_PROFILE_HOME/profiles/company/gh"
cp examples/company/config.bash examples/company/gitconfig examples/company/secrets.env \
  "$WORK_PROFILE_HOME/profiles/company/"
chmod 700 "$WORK_PROFILE_HOME/profiles/company" "$WORK_PROFILE_HOME/profiles/company/gh"
chmod 600 "$WORK_PROFILE_HOME/profiles/company/"{config.bash,gitconfig,secrets.env}
```

Edit those three files before selecting the profile. Set the Git name/email,
company credentials, and the path to an existing SSH config:

```bash
# profiles/company/config.bash
WP_SSH_CONFIG="$HOME/.ssh.company/config"
```

An empty `WP_SSH_CONFIG` uses normal OpenSSH config discovery. A nonempty value
passes `-F` to `ssh`, `scp`, and `sftp`, and Git SSH operations use the same wrapper.
The referenced configuration must specify its own identity paths as appropriate;
changing `-F` does not relocate OpenSSH's default key search directory.

```bash
work-profile company
```

Profiles are discovered from directories; no registry needs editing. Names must
start with a letter or number and contain only letters, numbers, `_`, or `-`.
`list` and `help` are reserved command names. Do not copy an authenticated profile's
`gh/` directory to create a new account.

## Configuration layout

```text
~/.config/work-profile/
├── components.d/             # additional trusted component hooks
└── profiles/
    ├── default/
    │   ├── config.bash       # trusted Bash settings
    │   ├── gitconfig         # profile-specific global Git config
    │   ├── secrets.env       # exported service credentials
    │   └── gh/               # GitHub CLI configuration
    └── company/
        └── ...
```

Secrets use **one `export NAME=value` assignment per line**. Assigned names from
all profiles are tracked and unset before each switch, including inherited
credentials on shell startup. Do not use multiline assignments, computed variable
names, functions, or shell side effects in secrets files. Do not assign manager
control variables such as `WORK_PROFILE`, `WORK_PROFILE_HOME`,
`WORK_PROFILE_MANAGED_ENV`, or `PATH` there.
Reselect a profile after changing its files. Bash completion is included.

Managed variable names are retained across re-sourcing and exported to child
shells in `WORK_PROFILE_MANAGED_ENV`; values are not duplicated in that registry.
This lets initialization clear previously managed credentials even after their
assignments or profile directory have been removed. Do not edit or unset this
internal registry. A shell that never inherited the registry can only discover
variable names from the profile files still present on disk.

Keep directories private (`700`) and secrets private (`600`). Installer-created
files use a restrictive umask; protect files you add yourself too.

### Existing SSH/Opexa setup

Existing `default` and `opexa` directories under `~/.config/work-profile` are
preserved. An Opexa `secrets.env` symlink to `~/.secrets` continues to work. For a
fresh migration, create the profile first, then link its credentials:

```bash
# Only if this destination does not already exist:
ln -s "$HOME/.secrets" "$WORK_PROFILE_HOME/profiles/opexa/secrets.env"
```

All existing `.secrets` credentials then belong to Opexa only. Never source that
file unconditionally in `~/.bashrc`. Replace the old startup source line with the
installer's new entry point; the old runtime and SSH wrappers can remain on disk.
Legacy copies of built-in component filenames are ignored by the new runtime.

## Extend with another service

Create `~/.config/work-profile/components.d/50-example.bash`:

```bash
_work_profile_components+=(example)
work_profile_manage_env EXAMPLE_CONFIG_DIR

work_profile_example_activate() {
    export EXAMPLE_CONFIG_DIR="$WORK_PROFILE_DIR/example"
}

# Optional: called before switching away from the current profile.
work_profile_example_deactivate() { :; }
```

Source the installed `init.bash` again or start a new terminal to load new hooks.
Built-in components load first, in filename order, then custom components in
filename order. The built-in filenames (`10-secrets.bash`, `20-ssh.bash`,
`30-git.bash`, `40-github.bash`) are reserved, not override points.
All selected component files are syntax-checked before any executes. An unreadable,
invalid, or unsuccessfully loaded component makes initialization fail rather than
silently selecting `default`. Runtime load failures can still leave definitions
from earlier components; fix the error before retrying initialization.

Hooks can read `WORK_PROFILE`, `WORK_PROFILE_DIR`, and settings from the profile's
`config.bash`. Register every variable the hook owns with `work_profile_manage_env`
so it is cleared before the next activation, including optional per-profile
settings that might otherwise leak. Keep hooks idempotent and avoid changing
machine-wide state. Activation hooks must return zero on success.

## Scope and security

This is configuration/environment separation, **not a security sandbox**:

- Already-running processes retain the environment they started with.
- Explicit command options, absolute SSH paths, shared SSH agents, OS keychains,
  Git credential stores, and application caches can bypass separation. A separate
  `GH_CONFIG_DIR` is not a separate OS credential vault; environment tokens are
  the most direct way to select GitHub credentials for a profile.
- AWS CLI named profiles, Kubernetes on-disk contexts, and other service state
  are not automatically switched. Their variables in `secrets.env` are switched;
  add components to manage any further configuration.
- Hooks and profile files are trusted Bash code, not sandboxed. Syntax is checked
  for profile files before switching, but hook execution is not transactional.
  A failing hook may leave a partially activated environment. Fix the problem and
  select a known-good profile, or open a new terminal.
- The runtime targets ordinary interactive Bash. Strict-shell modes such as
  `set -u` are not a supported execution environment.

## Development and tests

Install **bats-core 1.13.0** for the regression suite. `make test` uses `bats` on
PATH, or the existing local harness copy when available; override with
`make test BATS=/absolute/path/to/bats`. CI installs the pinned test dependency
in a separate setup step; tests themselves do not download dependencies.

```bash
make check
make test
# Or, without make:
bash tests/test.bash
```

Tests use an isolated temporary home, fake tokens, and `ssh -G` (no connections).
They cover installation/reinstallation, custom paths containing spaces, identity
switching, credential cleanup, child-shell isolation, extension hooks, SSH routing,
and invalid profiles. They never read your real credentials.
`tests/regressions.bats` additionally covers removed/deleted profile credentials,
reinitialization and child-shell cleanup, included Git identities, malformed Git
includes rejected before switching, and component load/syntax failures. Bats tests
use clean child environments, private temporary directories, C locale, UTC, and
serial execution. The original integration script remains part of `make test`.

Repository layout: `init.bash` is the manager, `components.d/` contains built-ins,
`bin/client` implements SSH wrappers, and `examples/` contains placeholders only.

## Update or uninstall

To update, run `bash install.sh` again with the same paths, then open a new terminal.
To uninstall, remove the source/export lines from `~/.bashrc`, open a fresh terminal,
and remove the installed runtime directory. Keep the configuration directory until
you have backed up any credentials you still need. The installer does not remove
old installations or secrets.
