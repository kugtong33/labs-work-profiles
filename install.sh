#!/usr/bin/env bash
set -euo pipefail
umask 077
src=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
prefix="${XDG_DATA_HOME:-$HOME/.local/share}/work-profiles"
config="${WORK_PROFILE_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/work-profile}"
while (($#)); do
    case "$1" in
        --prefix|--config-dir)
            (($# >= 2)) || { printf 'Missing value for %s\n' "$1" >&2; exit 2; }
            case "$1" in --prefix) prefix=$2 ;; --config-dir) config=$2 ;; esac
            shift 2 ;;
        -h|--help)
            printf 'Usage: ./install.sh [--prefix ABSOLUTE_PATH] [--config-dir ABSOLUTE_PATH]\nDoes not edit shell startup files or overwrite profile settings.\n'; exit 0 ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
[[ $prefix == /* && $config == /* ]] || { printf 'Paths must be absolute.\n' >&2; exit 2; }
[[ $prefix != "$src" && $prefix != "$config" ]] || { printf 'Install, source, and config directories must differ.\n' >&2; exit 2; }
command -v git >/dev/null || { printf 'git is required.\n' >&2; exit 1; }
mkdir -p -- "$prefix/components.d" "$prefix/bin" "$config/profiles/default/gh" "$config/components.d"
install -m 600 "$src/init.bash" "$prefix/init.bash"
for file in "$src"/components.d/*.bash; do install -m 600 "$file" "$prefix/components.d/"; done
install -m 700 "$src/bin/client" "$prefix/bin/client"
for tool in ssh scp sftp; do ln -sfn client "$prefix/bin/$tool"; done
for file in config.bash gitconfig secrets.env; do
    target="$config/profiles/default/$file"
    if [[ ! -e $target && ! -L $target ]]; then
        install -m 600 "$src/examples/default/$file" "$target"
    fi
done
printf 'Installed to %s\nConfiguration: %s\n\nAdd to ~/.bashrc (replace any previous work-profile source line):\n' "$prefix" "$config"
printf 'export WORK_PROFILE_HOME=%q\nsource %q\n' "$config" "$prefix/init.bash"
printf '\nSee README.md for Git identity, GitHub authentication, and additional profiles.\n'
