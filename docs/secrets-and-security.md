# Secrets and security

[Documentation index](README.md)

## Secret files

Secrets are plaintext files belonging to each profile, not an encrypted vault.
Use **one `export NAME=value` assignment per line**. Assigned names from all
profiles are tracked and unset before each switch, including inherited credentials
when a new shell loads the runtime.

Do not use multiline assignments, computed variable names, functions, or shell
side effects in secrets files. Do not assign manager control variables such as
`WORK_PROFILE`, `WORK_PROFILE_HOME`, `WORK_PROFILE_MANAGED_ENV`, or `PATH` there.
Reselect a profile after changing its files. Do not commit real credentials.

Managed variable names are retained across re-sourcing and exported to child
shells in `WORK_PROFILE_MANAGED_ENV`; values are not duplicated in that registry.
This lets initialization clear previously managed credentials even after their
assignments or profile directory have been removed. Do not edit or unset this
internal registry. A shell that never inherited the registry can only discover
variable names from the profile files still present on disk.

Keep directories private (`700`) and secrets private (`600`). Installer-created
files use a restrictive umask; protect files you add yourself too.

## Scope and limitations

This is configuration/environment separation, **not a security sandbox**:

- Profiles affect the current shell and processes started from it. Other terminals
  are unchanged. New shells reset to `default` when their startup loads the runtime;
  programs and shells that do not load it retain their inherited environment.
- Actual exported secret values pass to child processes as normal environment
  variables. Already-running processes retain the environment they started with.
  Unsetting a variable does not revoke a token or securely erase memory.
- Explicit command options, absolute SSH paths, shared SSH agents, OS keychains,
  Git credential stores, and application caches can bypass separation. A separate
  `GH_CONFIG_DIR` is not a separate OS credential vault; environment tokens are
  the most direct way to select GitHub credentials for a profile.
- AWS CLI named profiles, Kubernetes on-disk contexts, and other service state
  are not automatically switched. Their variables in `secrets.env` are switched;
  add [components](extensions.md) to manage any further configuration.
- Hooks and profile files are trusted Bash code, not sandboxed. Syntax is checked
  for profile files before switching, but hook execution is not transactional.
  A failing hook may leave a partially activated environment. Fix the problem and
  select a known-good profile, or open a new terminal.
- Missing or unreadable secrets files are currently skipped. There is no automatic
  credential rotation, expiration, or vault integration.
- The runtime targets ordinary interactive Bash. Strict-shell modes such as
  `set -u` are not a supported execution environment.
