# Implementation Plan
## Antigravity for Termux — one-shot installer

- **Version:** 0.1
- **Date:** 2026-10-27
- **Strategy:** CLI-first baseline; GUI remains experimental and optional.

## Milestone 0 — Repository foundation
- [x] Inspect repository and preserve default branch.
- [x] Create `feat/termux-one-shot-installer`.
- [x] Write PRD, MC and implementation plan.
- [ ] Update README with current status and limitations.
- [ ] Decide license with repository owner before adding one.

Acceptance: docs agree about the experimental support status.

## Milestone 1 — Installer skeleton
- [ ] Add `install.sh`.
- [ ] Parse `--help`, `--yes`, `--cli-only`, `--gui`, `--doctor`.
- [ ] Logging, error handler, lock and cleanup trap.
- [ ] Check Termux, ARM64, storage and network.
- [ ] Confirm before package/distro changes.
- [ ] No data deletion or silent distro reset.

Acceptance: syntax/lint pass; help and unsupported-host paths make no changes.

## Milestone 2 — Debian ARM64
- [ ] Install `proot-distro` if absent.
- [ ] Install Debian only if absent; safely reuse it otherwise.
- [ ] Verify `dpkg --print-architecture` equals `arm64`.
- [ ] Install baseline dependencies inside Debian only.
- [ ] Add resumable stages and non-secret state.
- [ ] Add a documented wrapper to enter Debian.

Acceptance: a clean and repeated run preserves existing projects and reports stages correctly.

## Milestone 3 — Official CLI
- [ ] Confirm current official URL and architecture availability.
- [ ] Fetch installer to a temporary file for inspection where feasible.
- [ ] Install official CLI and locate `agy`.
- [ ] Smoke-test version/help.
- [ ] Document interactive Google login and keyring/browser constraints.
- [ ] Detect allocator/memory-map crashes and stop with diagnostics.

Acceptance: working CLI smoke test or precise known-incompatibility report. Installation alone is not runtime success.

## Milestone 4 — Doctor
- [ ] Add doctor mode.
- [ ] Export safe, redacted diagnostics.
- [ ] Document common errors and next actions.
- [ ] Add an issue template.

Acceptance: no environment dumps, tokens, project sources or credentials appear in diagnostics.

## Milestone 5 — GUI experiment
- [ ] Confirm official ARM64 desktop artifact metadata at runtime.
- [ ] Install Termux:X11 only on request.
- [ ] Inspect archive layout and architecture.
- [ ] Add launch helper and DISPLAY guidance.
- [ ] Try sandboxed launch first; never add `--no-sandbox` silently.
- [ ] Add optional software-rendering troubleshooting after baseline.
- [ ] Document that Adreno acceleration is unverified unless tested.

Acceptance: GUI is optional and cannot break CLI setup.

## Milestone 6 — Quality and release
- [ ] ShellCheck and shell syntax CI.
- [ ] Mock tests: help, unsupported host, missing command, existing Debian, installer failure.
- [ ] Test on at least one real Snapdragon/ARM64 device.
- [ ] Record device, Android, Termux, storage, memory, Debian version and results.
- [ ] Tag alpha after tests pass.
- [ ] Publish checksums for project releases where applicable.

## Priority
1. Reproducible CLI setup.
2. Diagnostics and safe recovery.
3. Automated shell tests.
4. GUI/graphics experiments.
5. Device support matrix.

## Test matrix
| Test | Setup | Expected result |
|---|---|---|
| Help | Any host | Shows options; makes no changes |
| Unsupported host | Non-Termux | Clear error before mutation |
| Clean ARM64 Termux | No Debian | Creates Debian and verifies architecture |
| Existing Debian | Contains user projects | Reuses; never resets |
| Offline | No network | Fails early with clear stage |
| Partial installation | Prior stage failed | Safely resumes |
| Runtime incompatible | Android PRoot | Fails with diagnostics, no false success |
| GUI not selected | Any | No X11 or desktop downloads |

## Definition of done for v0.1
- One-shot command is implemented and documents effects.
- CLI-only is the default.
- Safe reruns, redacted logs and error handling are implemented.
- CI passes.
- Real-device status is published. If the upstream CLI fails due to Android/kernel incompatibility, the release states it plainly.
