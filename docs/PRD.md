# Product Requirements Document (PRD)
## Project: Antigravity on Android via Termux

- **Status:** Draft — experimental compatibility project
- **Version:** 0.1
- **Date:** 2026-10-27

## 1. Summary
Build a one-shot installer and diagnostic toolkit that helps users attempt to run Google's Antigravity developer tooling on ARM64 Android phones using Termux. Prefer official Google-distributed Linux ARM64 artifacts. Do not claim Android is officially supported.

First milestone is **CLI-first**: install and test the official Antigravity CLI (`agy`) inside Debian ARM64 launched through Termux/`proot-distro`. A separate, optional desktop GUI path may be researched later via Termux:X11.

## 2. Problem
Android users do not have a native Antigravity Android package. Termux and Debian PRoot provide a possible Linux user-space route, but do not replace the Android kernel or guarantee compatibility with desktop Linux assumptions about memory layout, keyrings, system services, sandboxing, browsers or graphics.

## 3. Goals
- Provide a single entry point after Termux prerequisites are installed.
- Detect Termux, architecture, free storage, network, distro state and required commands before changing the system.
- Set up or reuse Debian ARM64 using `proot-distro`.
- Install runtime dependencies and official Google Antigravity components where available.
- Make steps idempotent and safely resumable.
- Produce helpful logs and redacted diagnostics.
- Never require root or bootloader unlocking.
- Offer safe cleanup instructions without deleting user projects.

## 4. Non-goals
- Claiming Google officially supports Android/Termux/PRoot.
- Bypassing licensing, authentication or usage limits.
- Guaranteeing every Snapdragon device works or Adreno acceleration functions.
- Silently disabling application security or enabling privileged execution.
- Collecting or storing Google credentials.
- Using unofficial repackaged binaries by default.

## 5. Users and use cases
Primary users have an ARM64 Android phone and want a guided installation attempt from Termux. Advanced users need reproducible diagnostics for library, auth, memory-map, allocator or display failures.

User stories:
- Run one command and get a guided setup.
- See the plan before installation.
- Retry after failure without resetting Debian.
- Export a redacted diagnostic report.
- Choose CLI-only mode without installing GUI packages.

## 6. Functional requirements
### P0 — Installer foundation
- Provide an installer with strict error handling and clear stages.
- Verify Termux host and ARM64 before changes.
- Show a plan and confirm before substantial changes; non-destructive `--yes` may be supported.
- Use a lock, stable log path and cleanup traps.
- Check storage and network before downloading.
- Use HTTPS; verify signatures/checksums when upstream publishes them. Never invent checksums.
- Do not delete or reset an existing distro automatically.
- Never enable `--no-sandbox` by default.

### P0 — Debian runtime
- Install/reuse Debian through `proot-distro`.
- Keep Termux host packages separate from Debian APT packages.
- Verify `dpkg --print-architecture` is `arm64`.
- Make setup idempotent and report exact failure stage.

### P0 — Official CLI
- Use Google's documented CLI installation source and verify the URL at implementation/release time.
- Check whether `agy` exists before installing.
- Smoke-test version/help where supported; installation success alone is not a launch test.
- Keep authentication inside Google's official interactive flow; never request pasted OAuth tokens.
- Diagnose runtime failures without automatically changing memory settings or patching binaries.

### P1 — Diagnostics
- Report Android/Termux, architecture, Debian release, page size, disk/memory estimates, library state and CLI version.
- Offer a local diagnostic report with secrets redacted.
- Explain likely next actions for missing libraries, browser/keyring auth failure, `TCMalloc`/`MmapAligned` errors and X11 problems.

### P1 — GUI experiment
- Optional Termux:X11; CLI-only must not require a display.
- Download only an official ARM64 desktop artifact after checking current official metadata.
- Verify architecture and archive layout.
- Treat GPU acceleration as best-effort.
- Use software-rendering fallback only as troubleshooting, and never lower sandbox security automatically.

### P2 — Release quality
- Shell syntax/lint tests, mocked installer tests and CI.
- Document actual device/Android combinations tested.
- Provide versioned releases and project-installer checksums.

## 7. Non-functional requirements
Security: HTTPS-only, safe shell quoting, no `eval`, no credential capture, no silent sandbox weakening.
Reliability: resumable stages, atomic state, helpful errors.
Transparency: list external downloads and commands.
Maintainability: small shell functions and ShellCheck-compatible code.
Portability: Termux host with Debian ARM64 container.

## 8. Success criteria
1. Clean Termux ARM64 can install/reuse Debian without deleting user data.
2. Installer either completes official CLI install and smoke test or reports a precise reproducible failure.
3. Re-run after interruption is safe.
4. Automated shell tests pass.
5. At least one real device is tested end-to-end before calling any path verified.
6. Docs state compatibility limits clearly.

## 9. Risks
| Risk | Mitigation |
|---|---|
| Android kernel/VA-layout incompatibility | Capture diagnostics; report upstream incompatibility; don't claim success |
| Changed upstream artifacts | Use current official metadata and available integrity checks |
| GUI/system-service incompatibility | CLI-first; GUI optional |
| Storage/RAM limits | Preflight checks |
| Sandbox differences in PRoot | Never disable sandbox silently |
| Installer supply-chain risk | Prefer official endpoints, show source, inspect script where feasible |
| Accidental user-data loss | Never reset/remove a distro implicitly |

## 10. Open questions
- Does the current official CLI build run on current Android kernels under PRoot?
- Can its authentication/keyring path work within Debian PRoot?
- What real-device minimum storage/RAM is sensible?
- Which GUI archives and Termux:X11 combinations can be verified?

## 11. Status language
Use **Experimental** until real-device tests pass. **Device-tested** must name the device/build and test performed. Never claim “works on all Snapdragon phones” without strong evidence.
