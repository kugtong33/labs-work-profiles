# lab-work-profiles

## Overview

Switch **SSH, Git identity/configuration, GitHub authentication, and service
credentials** together in one Bash terminal.

Profiles affect the current shell and processes started from it; other terminals
are unchanged. Shells that load the runtime start in `default`.
This is configuration separation, not a security sandbox or encrypted secrets vault.

## Installation

Requires **Bash 4.2+**, Git, OpenSSH, and standard Unix utilities. Install
[GitHub CLI](https://cli.github.com/) for GitHub authentication. No root access is
required; macOS's bundled Bash 3 is unsupported.

From your cloned repository:

```bash
bash install.sh
```

Add the startup lines printed by the installer to `~/.bashrc`, after your other
`PATH` setup. With default paths:

```bash
export WORK_PROFILE_HOME="$HOME/.config/work-profile"
source "$HOME/.local/share/work-profiles/init.bash"
```

Replace any previous work-profile startup line, remove unconditional
`source ~/.secrets` lines, and open a new terminal. The installer preserves existing
profile settings and does not edit your startup files or authenticate accounts.

See [installation options](docs/installation.md) and
[profile setup](docs/configuration.md) to configure your identities and credentials.

## Usage

```bash
work-profile             # Show the active profile
work-profile list        # List available profiles
work-profile company     # Switch to a configured profile
work-profile default     # Return to default
work-profile help        # Show command help
```

Create and configure `company` before selecting it. `ssh-profile` remains a
compatibility alias, and Bash completion is included.

For details, see the [documentation index](docs/README.md):
[configuration](docs/configuration.md),
[secrets and security](docs/secrets-and-security.md),
[extensions](docs/extensions.md), [migration](docs/migration.md), and
[development](docs/development.md).
