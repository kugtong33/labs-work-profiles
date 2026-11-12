# Profile configuration

[Documentation index](README.md)

## Configure your default Git identity

```bash
git config --file "$WORK_PROFILE_HOME/profiles/default/gitconfig" user.name 'Your Name'
git config --file "$WORK_PROFILE_HOME/profiles/default/gitconfig" user.email 'you@example.com'
work-profile default
```

Each profile selects its own global Git configuration using `GIT_CONFIG_GLOBAL`.
The existing `~/.gitconfig` is not modified and is not automatically included.
Copy any shared settings you need into each profile, or use a Git `[include]`.
Name/email, including values from Git `[include]` files, are also exported as Git
author/committer variables, overriding repository-local identities. Other
repository-local Git settings retain their normal precedence. An unconfigured
profile leaves identity resolution to Git.

## Configure GitHub access

Either edit the profile's private `secrets.env` using your editor:

```bash
${EDITOR:-vi} "$WORK_PROFILE_HOME/profiles/default/secrets.env"
```

Add `export GH_TOKEN='your-token'`, save, and run `work-profile default` again.
Never paste a real token into a shell command or commit it to this repository.
See [secret-file rules and security limits](secrets-and-security.md).

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

## Add a company profile

Run from the repository root:

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
`gh/` directory to create a new account. `ssh-profile` switches the entire work
profile as a compatibility alias; Bash completion is included.

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
