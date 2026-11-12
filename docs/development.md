# Development and tests

[Documentation index](README.md)

## Test dependencies and commands

Install **bats-core 1.13.0** for the regression suite. `make test` uses the existing
local harness copy when available, otherwise `bats` on PATH; override with
`make test BATS=/absolute/path/to/bats`. CI installs the pinned test dependency
in a separate setup step; tests themselves do not download dependencies.

From the repository root:

```bash
make check
make test
```

Without make, run both suites:

```bash
bash tests/test.bash
bats --formatter tap --jobs 1 tests/regressions.bats
```

## Test coverage and isolation

Tests use an isolated temporary home, fake tokens, and `ssh -G` (no connections).
They cover installation/reinstallation, custom paths containing spaces, identity
switching, credential cleanup, child-shell isolation, extension hooks, SSH routing,
and invalid profiles. They never read your real credentials.

`tests/regressions.bats` additionally covers removed/deleted profile credentials,
reinitialization and child-shell cleanup, included Git identities, malformed Git
includes rejected before switching, and component load/syntax failures. Bats tests
use clean child environments, private temporary directories, C locale, UTC, and
serial execution. The original integration script remains part of `make test`.

## Repository layout

- `init.bash`: profile manager, environment cleanup, and completion.
- `components.d/`: built-in service components.
- `bin/client`: SSH/SCP/SFTP wrapper implementation.
- `examples/`: placeholder profile configuration, never real credentials.
- `tests/`: integration and Bats regression suites.
- `.github/workflows/test.yml`: syntax and test checks in CI.
- `docs/`: detailed project documentation.
