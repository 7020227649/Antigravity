# Module Contract (MC) and Architecture
## Antigravity for Termux
Status: Initial design | Version: 0.1 | Date: 2026-10-27

Here MC means **Module Contract**: responsibilities, interfaces, invariants and failure behavior.

## 1. Architecture
Two separated environments:
1. **Termux host (Android):** checks platform, installs host packages, launches PRoot, keeps logs.
2. **Debian ARM64 under PRoot:** installs Linux dependencies and runs official Antigravity tooling.

PRoot is not a full VM; it shares Android's kernel. Linux ARM64 binaries may fail if they depend on unsupported kernel behavior, privileged services, specific memory layouts or desktop integration.

```text
Android / Termux
  └─ install.sh
      ├─ preflight (architecture, commands, storage, network)
      ├─ Termux packages
      ├─ install/reuse Debian ARM64
      ├─ Debian bootstrap
      │    ├─ baseline APT dependencies
      │    ├─ official Google CLI installer
      │    └─ smoke test + diagnostics
      ├─ optional Termux:X11 / desktop (future)
      └─ summary, logs and recovery
```

## 2. Planned layout
- `install.sh`: single Termux entry point.
- `lib/common.sh`: logging, errors, host checks, helpers.
- `lib/host.sh`: Termux packages and Debian/PRoot setup.
- `lib/debian.sh`: Debian dependencies and CLI installation.
- `lib/doctor.sh`: diagnostics and redaction.
- `scripts/doctor.sh`: optional standalone check.
- `docs/PRD.md`, `docs/MC.md`, `docs/PLAN.md`: requirements, contracts and plan.
- `tests/`: syntax and mocked behavior tests.
- `README.md`: scope, quick start, limitations and safety.

## 3. Module contracts
### `install.sh`
Planned flags: `--help`, `--yes`, `--cli-only`, `--gui`, `--doctor`.
Parse options, validate host, show plan, acquire lock, orchestrate stages and report log path. Must not run as root, delete files, silently reset Debian, disable sandbox or collect credentials.
Exit codes: 0 success, 1 general failure, 2 invalid input/unsupported environment.

### Host preflight
Input: Android/Termux properties, command availability, architecture and available storage. Output: validated environment report. Stop before changes on unsupported host.

### Debian manager
Install/reuse Debian via `proot-distro`. Never remove/reset an existing distro automatically.

### Debian bootstrap
Install packages inside Debian only. Verify `dpkg --print-architecture` is `arm64`.

### Official CLI installer
Use Google's documented official endpoint. Output installed `agy` or actionable failure. A failed smoke test is not success. Authentication stays in Google's flow. Prefer fetching and inspecting installer source before execution where feasible.

### Diagnostic reporter
Produce concise terminal/local report. Never dump environment variables, tokens, keyring content, home listings or project source.

### GUI experiment
Only on explicit user request. GUI dependencies cannot block CLI path. No sandbox weakening by default. Never promise Adreno acceleration without testing.

## 4. Source policy
- CLI installer endpoint documented by Google: `https://antigravity.google/cli/install.sh`; verify at implementation/release time.
- Use official Google metadata/pages for desktop archives; don't pin an object-storage URL indefinitely.
- Termux packages from official Termux repositories, Debian packages from APT.
- Verify checksums/signatures if upstream publishes them; never fabricate hashes.
- No unofficial repacks by default.

## 5. State/logging
Use a project-specific Termux cache/state directory where possible. Store only schema version, completed stages, timestamps and distro state. No secrets. Use atomic writes.

## 6. Failure taxonomy
`HOST_NOT_TERMUX`, `UNSUPPORTED_ARCH`, `MISSING_DEPENDENCY`, `INSUFFICIENT_STORAGE`, `NETWORK_OR_TLS`, `DISTRO_INSTALL_FAILED`, `APT_FAILED`, `UPSTREAM_INSTALL_FAILED`, `CLI_NOT_FOUND`, `CLI_RUNTIME_INCOMPATIBLE`, `AUTHENTICATION_REQUIRED`, `DISPLAY_UNAVAILABLE`, `GUI_UNSUPPORTED`.

Logs include stage and exit status, never secrets.

## 7. Safety
HTTPS sources, quote variables, no root requirement, no implicit removal, never default to `--no-sandbox`, show upstream installer source, no credential persistence.
