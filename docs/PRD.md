# Product Requirements Document (PRD)
## Antigravity CLI on Android via Termux

Status: Experimental | Version: 0.2 | Review date: 2026-10-27

## 1. Summary

Build a one-shot installer and diagnostic toolkit for attempting to run Google's Antigravity CLI on ARM64 Android. Prefer the official native Termux-compatible route before considering Linux userlands.

The upstream Antigravity CLI changelog states that prebuilt native Android binaries were added in version 1.2.15. Therefore, the project's default path is to run Google's official installer in native Termux and validate the result with the real CLI. Debian/PRoot is not the default: it shares Android's kernel and cannot remove syscall restrictions.

## 2. Problem

The earlier prototype installed the Linux CLI inside Debian PRoot. This adds an extra userspace and still shares the Android kernel; it also cannot fix Android-specific syscall behavior. An install script may exit successfully while the resulting binary still fails to start. The project must test the actual CLI and never report success based only on downloads or extraction.

## 3. Goals

- Offer one guided native-Termux installation entry point.
- Check native Termux environment and ARM64 architecture before changing anything.
- Use official Google distribution endpoints and keep the upstream source visible.
- Require a successful CLI smoke test before reporting setup success.
- Make help and diagnostics read-only; do not create logs or mutate the device for help.
- Use persistent, useful logs for actual install attempts.
- Fail clearly on upstream, runtime, authentication or unsupported-device issues.
- Avoid root requirements, binary patching and collecting credentials.
- Keep GUI/desktop support out of the default flow.

## 4. Non-goals

- Guarantee every Snapdragon model or Android/kernel build works.
- Claim Google supports all Android or Termux configurations.
- Guarantee the desktop IDE, Adreno acceleration, keyring integration, browser handoff or a complete authenticated session.
- Modify or patch Google's binary without a reproducible, maintained compatibility implementation.
- Collect Google credentials or bypass account controls.
- Install/remove Debian or delete user projects in the default mode.

## 5. User stories

- As an Android user, I run one command from native Termux and receive clear progress/failure messages.
- As a user, I can inspect help and run diagnostics without making changes.
- As a user, I can tell the difference between installation success and an actual executable smoke test.
- As a user, I can share sanitized diagnostics without exposing tokens or private projects.
- As a user, I am not asked to install Debian or GUI packages unless those become separately implemented, tested features.

## 6. Functional requirements

### P0 — Native installer
- Accept --help, --yes, --native and --doctor.
- Reject unknown options before creating logs or changing files.
- Verify Termux package prefix and ARM64 host before installation.
- Ask for consent before package changes and executing the downloaded installer; --yes skips this confirmation.
- Update Termux package metadata and install only required host dependencies.
- Download the official installer over HTTPS to a temporary file before execution.
- Refuse an empty or obviously non-shell response.
- Clean up temporary installer files on success, failure and interruption.
- Do not silently invoke a PRoot route or disable sandboxing.

### P0 — Correct validation
- Locate the installed CLI in the upstream documented path or PATH.
- Run agy --version and require a zero exit status.
- If the smoke test fails, return nonzero and do not print a success message.
- State explicitly that the smoke test does not validate authentication, model access, workspace tools or a full session.
- Record the install output in a local log without collecting environment dumps or credentials.

### P1 — Diagnostics
- Report Android version/API, Termux version, architecture, page size, storage and CLI location/version.
- Do not upload reports.
- Suggest including device model, OS build, Termux source, exact failing command and sanitized output in issue reports.

### P1 — Robustness
- Preflight sufficient storage and network.
- Add an install lock and stale-lock handling.
- Add tests for failure exit codes and mocked installer behavior.
- Keep the installer idempotent and safe to re-run.
- Verify current official install script behavior with real-device tests across supported Termux installations.

### P2 — Optional routes
- Only add Debian/PRoot mode if it solves a demonstrated use case that is not served by the native CLI and has its own tests.
- Only add desktop GUI/Termux:X11 after official artifact metadata and runtime behavior are verified.
- Do not promise hardware acceleration without device-specific evidence.

## 7. Non-functional requirements

Security: HTTPS downloads, shell quoting, no eval, no credentials capture, no silent sandbox weakening.
Reliability: nonzero failure exit codes, cleanup traps, readable diagnostics, no false success.
Transparency: describe all external code execution and side effects.
Maintainability: small functions, ShellCheck and CI tests.
Portability: native Termux ARM64 for the first milestone.

## 8. Success criteria

1. Help/unknown-argument paths produce no filesystem changes.
2. Non-Termux and non-ARM64 environments fail before package changes.
3. Installer executes only an official script fetched over HTTPS.
4. A nonzero agy --version result causes overall installer failure.
5. CI shell syntax, smoke tests and ShellCheck pass.
6. At least one real ARM64 Android device successfully installs, starts, authenticates and performs a simple test task before the project labels the path device-verified.
7. Tests are repeated on more than one Android/kernel version before claiming broad support.

## 9. Risks

| Risk | Mitigation |
|---|---|
| Upstream installer does not select native Android build | Fail at smoke test; confirm actual install script and artifact on device |
| Android syscall/kernel incompatibility | Preserve logs, report exact error, do not patch binaries silently |
| Auth/browser flow unsupported | Document as unverified until test |
| User storage is low | Add storage preflight and clear estimate |
| Upstream installer changes behavior | Review current source and regression-test before releases |
| Installer fails but appears successful | Require zero-exit CLI smoke test |
| Secret disclosure in diagnostics | Report only selected fields; never dump environment |

## 10. Release status language

Use Experimental until end-to-end device tests pass. Device-tested must identify the tested device/build and scenarios. Never claim "100% works on all Android phones."
