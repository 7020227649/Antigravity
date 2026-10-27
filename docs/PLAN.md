# Implementation Plan
## Antigravity CLI on Android via Termux

Version: 0.2 | Date: 2026-10-27
Direction: native Termux first; Debian PRoot and GUI are not active install modes.

## Milestone 0 — Repository foundation
- [x] PRD, module contract and plan exist.
- [x] README explains the project and limitations.
- [x] Feature prototype reviewed against latest upstream changelog.
- [x] Main branch updated with native-first route and more truthful smoke test behavior.

## Milestone 1 — Native installer hardening
- [x] Parse help/options before creating files.
- [x] Check native Termux environment and ARM64.
- [x] Download official installer to a temporary file over HTTPS.
- [x] Require agy --version to return zero before success.
- [x] Make unknown option/help paths read-only.
- [ ] Add install lock and robust stale-lock recovery.
- [ ] Add storage preflight and network retry tests.
- [ ] Confirm upstream install script selects a native Android build in real Termux.

Acceptance: static CI passes; install errors return nonzero and never print success.

## Milestone 2 — CI and mock testing
- [x] Bash syntax checks.
- [x] Smoke tests for help, unknown option and non-Termux doctor path.
- [x] ShellCheck workflow.
- [ ] Add mocked pkg/curl/upstream-installer tests for success and failure paths.
- [ ] Confirm CI has green status on main.

Acceptance: deterministic automated tests run without network or device access.

## Milestone 3 — Physical-device validation
- [ ] Test on a clean Termux install on Snapdragon ARM64.
- [ ] Capture Android version/build, Termux source/version, page size, CLI version and result.
- [ ] Confirm agy --version succeeds.
- [ ] Complete Google login in the supported browser flow.
- [ ] Run a trivial, non-destructive test task in a disposable directory.
- [ ] Test another Android/kernel release before claiming broad support.
- [ ] Document precise failure modes and recovery commands.

Acceptance: reproducible end-to-end task on the named devices. This is the only milestone that can validate actual phone behavior.

## Milestone 4 — Optional PRoot path (not prioritized)
- [ ] Only revisit if there is a clear reason to support the Linux ARM64 binary separately.
- [ ] Confirm kernel syscall behavior and CLI compatibility.
- [ ] Never reset an existing distro or claim PRoot isolates Android kernel issues.

## Milestone 5 — Desktop GUI research
- [ ] Verify current official desktop Linux ARM64 artifact metadata.
- [ ] Implement Termux:X11 only with a documented test device.
- [ ] Test display, window lifecycle, sandbox and rendering.
- [ ] Never promise Adreno acceleration without evidence.

## Test matrix

| Test | Expected |
|---|---|
| --help | Prints options with no filesystem changes |
| Unknown option | Exit 2 before filesystem changes |
| Non-Termux shell | Exit nonzero before package changes |
| Non-ARM64 Termux | Exit nonzero before package changes |
| Official download fails | Nonzero, log includes stage |
| Official script fails | Nonzero, no success message |
| agy missing after installer | Nonzero |
| agy --version fails | Nonzero, no success message |
| agy --version passes | Installer may report success but clearly says auth/session untested |
| Real device agent task | Required before device-verified status |

## Definition of done

- CI and mock tests pass.
- Native official installer path is confirmed on at least one actual Android phone.
- A complete auth + simple agent task passes on that phone.
- Documentation states tested configurations and remaining unsupported scenarios.
