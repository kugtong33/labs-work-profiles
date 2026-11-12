# Installation and maintenance

[Documentation index](README.md)

## Requirements

- Linux or another Unix-like system with **Bash 4.2+**, Git, OpenSSH, and standard
  utilities (`install`, `mkdir`, `ln`). macOS's bundled Bash 3 is unsupported;
  install a newer Bash first.
- [GitHub CLI (`gh`)](https://cli.github.com/) for GitHub API access and Git HTTPS
  credentials. The switcher itself does not call GitHub over the network.
- No root access required. Bash is supported; not Zsh, Fish, or `sh`.

## Install

From the cloned repository, run:

```bash
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

Continue with [profile configuration](configuration.md).

## Custom paths

Use absolute paths:

```bash
bash install.sh --prefix "$HOME/.local/share/work-profiles" \
  --config-dir "$HOME/.config/work-profile"
```

Defaults honor `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, and `WORK_PROFILE_HOME`. Use
the exact startup lines printed by the installer for your chosen paths.

## Update or uninstall

To update, run `bash install.sh` again with the same paths, then open a new terminal.
To uninstall, remove the source/export lines from `~/.bashrc`, open a fresh terminal,
and remove the installed runtime directory. Keep the configuration directory until
you have backed up any credentials you still need. The installer does not remove
old installations or secrets.
