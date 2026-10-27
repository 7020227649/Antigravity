# Product Requirements Document (PRD)
## Project: Antigravity on Android via Termux
Status: Draft / experimental | Version: 0.1 | Date: 2026-10-27

## 1. Summary
Build a one-shot installer and diagnostic toolkit that helps users attempt to run Google's Antigravity developer tooling on ARM64 Android phones using Termux. Prefer official Google-distributed Linux ARM64 artifacts. Do not claim Android is officially supported.

The first milestone is CLI-first: install and test the official Antigravity CLI (`agy`) inside Debian ARM64 launched through Termux/`proot-distro`. An optional desktop GUI path may be researched later via Termux:X11.

## 2. Problem
Android users do not have a native Antigravity Android package. Termux and Debian PRoot offer a possible Linux user-space route, but do not replace the Android kernel or guarantee compatibility with desktop Linux assumptions about memory layout, keyrings, system services, sandboxing, browsers or graphics.

## 3. Goals
- Provide one guided entry point after Termux prerequisites are installed.
- Detect Termux, architecture, free storage, network, distro state and required commands before changing the system.
- Set up or reuse Debian ARM64 using `proot-distro`.
- Install dependencies and official Google Antigravity components when available.
- Make steps idempotent and safely resumable.
- Produce useful logs and redacted diagnostics.
- Avoid root or bootloader unlocking requirements.
- Offer cleanup instructions that do not delete user projects.

## 4. Non-goals
- Claim Android/Termux/PRoot is officially supported by Google.
- Bypass licensing, authentication or usage limits.
- Guarantee every Snapdragon device or Adreno acceleration works.
- Silently disable application security or enable privileged execution.
- Collect/store Google credentials.
- Use unofficial repackaged binaries by default.

## 5. Users and stories
Primary users have ARM64 Android and want a guided attempt through Termux. Advanced users need reproducible diagnostics for library, auth, memory-map, allocator or display failures.
- Run one command and get a guided setup.
- See the plan before installing.
- Retry after failure without resetting Debian.
- Export redacted diagnostics.
- Choose CLI-only without GUI packages.

## 6. Functional requirements
### P0 — Installer
- Strict error handling and clear stages.
- Verify Termux host and ARM64 before changes.
- Show the plan and confirm before substantial changes; `--yes` may skip confirmation only for non-destructive setup.
- Use a lock, stable log path and cleanup traps.
- Check storage and network early.
- HTTPS sources; verify upstream signatures/checksums if published. Never invent hashes.
- Never delete or reset a distro automatically.
- Never enable `--no-sandbox` by default.

### P0 — Debian
- Install/reuse Debian through `proot-distro`.
- Keep host packages separate from Debian APT packages.
- Verify `dpkg --print-architecture` is `arm64`.
- Make setup idempotent and report failures by stage.

### P0 — Official CLI
- Use Google's documented CLI installation source and verify URL at implementation/release time.
- Detect an existing `agy`.
- Smoke-test version/help where supported; download success is not runtime success.
- Keep authentication in Google's official interactive flow. Never request pasted OAuth tokens.
- Diagnose runtime failures without changing memory settings or patching binaries automatically.

### P1 — Diagnostics
Report Android/Termux, architecture, Debian release, page size, storage, selected library presence and CLI version. Offer a redacted text report. Explain likely next steps for missing libraries, auth/keyring failure, `TCMalloc`/`MmapAligned` errors and X11 problems.

### P1 — GUI experiment
Optional Termux:X11; CLI does not require display support. Only use official ARM64 desktop artifacts after checking current upstream metadata. Verify architecture and archive layout. GPU acceleration is best-effort. Software rendering is troubleshooting only; never lower sandbox security automatically.

### P2 — Release quality
Shell syntax/lint, mocked installer tests and CI. Document tested devices. Versioned releases and project-installer checksums.

## 7. Non-functional requirements
Security: HTTPS, safe quoting, no `eval`, no credential capture, no silent sandbox weakening.
Reliability: safe retries, atomic state, actionable errors.
Transparency: show external sources and side effects.
Maintainability: small ShellCheck-friendly modules.
Portability: Termux host + Debian ARM64 container.

## 8. Success criteria
1. Clean ARM64 Termux can install/reuse Debian without deleting user data.
2. Installer completes official CLI install and smoke test, or reports a precise reproducible failure.
3. Re-runs after interruption are safe.
4. Automated shell tests pass.
5. At least one real device is tested before a path is called verified.
6. Limitations are explicit.

## 9. Risks
| Risk | Mitigation |
|---|---|
| Android kernel/VA-layout incompatibility | Diagnostics, report upstream issue, no false success |
| Upstream artifacts change | Use official metadata and available integrity checks |
| GUI/system services fail | CLI-first and GUI optional |
| RAM/storage limits | Preflight |
| PRoot sandbox differences | Never silently disable app sandbox |
| Supply-chain risk | Official endpoints, inspect sources where feasible |
| User-data loss | Never reset/remove distro implicitly |

## 10. Open questions
Does the current CLI run on Android kernels under PRoot? Can auth/keyring work? What real-device minimums are sensible? Which GUI paths can be verified?

## 11. Status language
Use **Experimental** until real-device tests pass. **Device-tested** names the device/build and tests. Never claim “works on all Snapdragon phones” without evidence.
