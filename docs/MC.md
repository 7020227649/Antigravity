# Module Contract (MC) and Architecture
## Antigravity for Termux

- **Status:** Initial design
- **Version:** 0.1
- **Date:** 2026-10-27

Here MC means **Module Contract**: responsibilities, interfaces, invariants and failure behavior.

## 1. Architecture
Two separated environments:
1. **Termux host (Android):** checks the platform, installs host packages, launches PRoot, keeps logs and presents commands.
2. **Debian ARM64 under PRoot:** installs Linux dependencies and runs the official Antigravity tooling.

PRoot is not a full VM and shares Android's kernel. Linux ARM64 binaries may still fail if they depend on unsupported kernel behavior, privileged services, specific memory layouts or desktop integration.

```text
Android / Termux
  └─ install.sh
      ├─ preflight (architecture, commands, storage, network)
      ├─ Termux packages
      ├─ install/reuse Debian ARM64
      ├─ enter Debian
      │    ├─ baseline APT dependencies
      │    ├─ official Google CLI installer
      │    └─ CLI smoke test + diagnostics
      ├─ optional Termux:X11 + desktop attempt (future)
      └─ summary, logs and recovery guidance
```

## 2. Planned repository layout
- `install.sh`: single entry point in Termux.
- `lib/common.sh`: logging, errors, platform checks and safe helpers.
- `lib/host.sh`: Termux packages and Debian/PRoot setup.
- `lib/debian.sh`: Debian dependencies and CLI installation.
- `lib/doctor.sh`: selected diagnostics and redaction.
- `scripts/doctor.sh`: standalone diagnostic entry point (planned).
- `docs/PRD.md`, `docs/MC.md`, `docs/PLAN.md`: specification, module boundaries and plan.
- `tests/`: syntax checks and mocks.
- `README.md`: scope, quick start, limitations and security notes.

## 3. Module contracts
### `install.sh`
Inputs planned: `--help`, `--yes`, `--cli-only`, `--gui`, `--doctor`.
Responsibilities: parse options, validate host, print plan, acquire lock, orchestrate stages, report log path.
Must not run as root, delete user files, silently reset Debian, disable sandbox or collect credentials.
Exit codes: 0 success, 1 general failure, 2 invalid input/unsupported environment.

### Host preflight
Input: Android/Termux properties, command availability, architecture and available storage.
Output: validated environment report.
Failure: stop before changes and explain requirements.

### Debian manager
Input: `proot-distro` availability and distro list.
Output: installed or safely reused Debian ARM64.
Invariant: never remove/reset an existing distro automatically.

### Debian bootstrap
Input: Debian APT and distro metadata.
Output: runtime packages and tools.
Invariant: APT changes occur inside Debian; architecture must report `arm64`.

### Official CLI installer
Input: documented Google installer endpoint.
Output: installed `agy` or actionable failure.
Invariant: failed smoke test is not success. Auth stays in Google's flow. A future hardened installer should fetch and inspect the script before execution where feasible.

### Diagnostic reporter
Output: concise report and optional local file. Never dump environment variables, tokens, keyring contents, home-directory listings or project source.

### GUI experiment
Input: explicit user selection, Termux:X11, official artifact metadata.
Output: optional launch helper.
Invariant: GUI dependencies do not block CLI-only. No sandbox weakening by default. Never promise Adreno acceleration without testing.

## 4. Source policy
- Official CLI endpoint documented by Google: `https://antigravity.google/cli/install.sh`; verify before each release.
- Use official Google metadata/pages for desktop artifacts; do not hard-code an object-storage link indefinitely.
- Termux packages from Termux repositories, Debian packages from APT.
- Verify checksums/signatures if upstream publishes them; don't fabricate hashes.
- Do not download third-party repacks by default.

## 5. State and logs
Use a project-specific directory under Termux cache/state where possible. Store only schema/version, completed stages, timestamps and distro state. Do not store secrets. Atomic state writes should write to a temporary file and rename.

## 6. Failure codes
- `HOST_NOT_TERMUX`
- `UNSUPPORTED_ARCH`
- `MISSING_DEPENDENCY`
- `INSUFFICIENT_STORAGE`
- `NETWORK_OR_TLS`
- `DISTRO_INSTALL_FAILED`
- `APT_FAILED`
- `UPSTREAM_INSTALL_FAILED`
- `CLI_NOT_FOUND`
- `CLI_RUNTIME_INCOMPATIBLE`
- `AUTHENTICATION_REQUIRED`
- `DISPLAY_UNAVAILABLE`
- `GUI_UNSUPPORTED`

Logs include the stage and exit status but never secrets.

## 7. Safety rules
- HTTPS sources and quoted variables.
- No root requirement.
- No implicit distro removal or data deletion.
- Never default to `--no-sandbox`.
- Show the upstream installer source and request consent.
- No environment dumps or credential persistence.
