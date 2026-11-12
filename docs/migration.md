# Existing SSH/Opexa setup

[Documentation index](README.md)

Existing `default` and `opexa` directories under `~/.config/work-profile` are
preserved. An Opexa `secrets.env` symlink to `~/.secrets` continues to work. For a
fresh migration, [create the profile](configuration.md#add-a-company-profile)
first, using your desired profile name, then link its credentials:

```bash
# Only if this destination does not already exist:
ln -s "$HOME/.secrets" "$WORK_PROFILE_HOME/profiles/opexa/secrets.env"
```

All existing `.secrets` credentials then belong to Opexa only. Never source that
file unconditionally in `~/.bashrc`. Replace the old startup source line with the
installer's new entry point; the old runtime and SSH wrappers can remain on disk.
Legacy copies of built-in component filenames are ignored by the new runtime.

See [startup instructions](installation.md#install) and
[secret-file rules](secrets-and-security.md#secret-files).
