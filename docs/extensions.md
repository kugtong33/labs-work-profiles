# Extend with another service

[Documentation index](README.md)

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

Read the [security limitations](secrets-and-security.md) before adding hooks.
