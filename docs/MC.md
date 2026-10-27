# Module Contract (MC) and Architecture
## Antigravity CLI on Termux

Status: Design updated for native Android path | Version: 0.2 | Date: 2026-10-27

MC means Module Contract: module responsibilities, interfaces, invariants and failure behavior.

## 1. Architecture

The primary path is native Termux on ARM64 Android. The official Antigravity CLI changelog says prebuilt native Android binaries were added in version 1.2.15. This is a better starting point than Debian PRoot, but the install script still must be smoke-tested on the target phone.

    Android / Termux
      -> install.sh
         -> preflight (Termux prefix, ARM64, permissions)
         -> confirm and initialize log
         -> Termux package metadata + curl/CA certificates
         -> fetch official Google installer over HTTPS
         -> run official installer in native Termux
         -> locate agy
         -> require agy --version to exit 0
         -> summary and log path

The standard Google installation documentation does not guarantee all Android/Termux configurations. The project therefore treats this as an experimental compatibility route, not a guaranteed platform.

## 2. Module contract

### install.sh
Inputs: --help, --yes, --native, --doctor; --proot and --gui intentionally reject for this release.
Responsibilities: parse options before mutation, validate native Termux/ARM64, obtain consent, maintain log, install host prerequisites, fetch/run official installer, validate CLI, return accurate exit status.
Invariants: no root, no implicit PRoot reset, no automatic sandbox disabling, no credentials collection, no success message when smoke test fails.
Exit codes: 0 only for help/doctor or successful install+smoke test; 1 install/runtime failure; 2 invalid arguments or unsupported environment.

### Host preflight
Validate Termux package prefix and pkg executable. Detect aarch64/arm64. Reject execution inside a standard Debian/PRoot shell or unsupported architecture before package changes.

### Upstream installer stage
Download https://antigravity.google/cli/install.sh over HTTPS with TLS verification to a temporary file. Ensure it is nonempty and begins with a shell shebang. Execute after the explicit confirmation. Do not modify the downloaded code, and do not treat this lightweight check as a cryptographic signature.

### CLI validation
Expected documented path is ~/.local/bin/agy or a command on PATH. Call agy --version and require exit status zero. This validates that the process starts and reports a version, but not authentication or agent execution.

### Diagnostics
Print selected Android/Termux fields, page size, storage and CLI path/version. Never dump env, tokens, cookies, keyring contents, home directory listings or project source. Nothing is uploaded.

### Future PRoot / GUI
Do not implement as a flag that appears to work but does not. Any PRoot mode needs its own runtime diagnosis and end-to-end tests. Any GUI mode needs official artifact verification, display configuration and specific GPU claims backed by tests.

## 3. Source and integrity policy

- Official installer: https://antigravity.google/cli/install.sh
- Official CLI docs: https://antigravity.google/docs/cli/install/
- Official CLI changelog: https://github.com/google-antigravity/antigravity-cli/blob/main/CHANGELOG.md
- Termux dependencies from configured Termux repositories.
- Fetch official scripts to disk for review/debugging instead of piping directly into a shell.
- HTTPS + a shell shebang check is not a digital signature. Use upstream checksums/signatures if published; never invent one.
- Do not install unofficial patched/repacked binaries as default.

## 4. Logs and state

Logs are stored below $HOME/.cache/antigravity-termux/logs, with a home-directory fallback. Logs contain command output from the install attempt. Avoid shell environment dumps and don't include secrets in bug reports. Temporary downloaded scripts must be removed on exit.

## 5. Failure categories

HOST_NOT_TERMUX, UNSUPPORTED_ARCH, PACKAGE_MANAGER_FAILED, NETWORK_OR_TLS, UPSTREAM_INSTALL_FAILED, CLI_NOT_FOUND, CLI_RUNTIME_INCOMPATIBLE, AUTHENTICATION_REQUIRED, STORAGE_LOW.

## 6. Safety requirements

- Run as the regular Termux app user.
- Do not write to system paths outside the Termux app prefix and the user's home.
- Do not remove existing projects or Linux containers.
- Do not disable application sandboxing.
- Keep Google authentication inside the official CLI flow.
- Never report installation success unless the CLI smoke test passes.
