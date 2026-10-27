# Implementation Plan
## Antigravity for Termux — one-shot installer
Version: 0.1 | Date: 2026-10-27
Strategy: CLI-first; GUI experimental and optional.

## Milestone 0 — Foundation
- [x] Inspect repository and preserve default branch.
- [x] Create `feat/termux-one-shot-installer`.
- [ ] PRD, MC and plan committed.
- [ ] README project status updated.
- [ ] License chosen by repository owner.

Acceptance: docs consistently describe experimental/unofficial support.

## Milestone 1 — Installer skeleton
- [ ] Add `install.sh`.
- [ ] Parse `--help`, `--yes`, `--cli-only`, `--gui`, `--doctor`.
- [ ] Logging, error handler, lock and cleanup trap.
- [ ] Check Termux, ARM64, storage and network.
- [ ] Confirm before package/distro changes.
- [ ] No data deletion or silent distro reset.
Acceptance: syntax/lint pass; help and unsupported host change nothing.

## Milestone 2 — Debian ARM64
- [ ] Install `proot-distro` when absent.
- [ ] Install Debian only if absent; safely reuse it otherwise.
- [ ] Verify architecture equals `arm64`.
- [ ] Install baseline dependencies inside Debian only.
- [ ] Add resumable stages and non-secret state.
- [ ] Add documented Debian entry wrapper.
Acceptance: clean/repeated run preserves user data.

## Milestone 3 — Official CLI
- [ ] Confirm current official URL/architecture support.
- [ ] Fetch installer to a temp file for inspection where feasible.
- [ ] Install official CLI and locate `agy`.
- [ ] Smoke test version/help.
- [ ] Document interactive login and keyring/browser constraints.
- [ ] Detect allocator/memory-map crashes and stop with diagnostics.
Acceptance: CLI smoke test or precise incompatibility report; installation alone is not success.

## Milestone 4 — Doctor
- [ ] Diagnostic mode and safe report export.
- [ ] Common failure mapping.
- [ ] Issue report template.
Acceptance: no environment dumps, tokens, project sources or credentials.

## Milestone 5 — GUI experiment
- [ ] Verify official ARM64 desktop metadata at runtime.
- [ ] Install Termux:X11 only on request.
- [ ] Inspect archive architecture and paths.
- [ ] Add launch helper and DISPLAY guidance.
- [ ] Try sandboxed launch first.
- [ ] Optional software-render troubleshooting.
- [ ] Document Adreno acceleration as unverified unless tested.
Acceptance: GUI optional and cannot break CLI setup.

## Milestone 6 — Quality/release
- [ ] ShellCheck and syntax CI.
- [ ] Mock tests for help, unsupported host, missing command, existing Debian, installer failure.
- [ ] Test at least one Snapdragon device.
- [ ] Record device, Android, Termux, storage, memory, Debian and result.
- [ ] Alpha tag after tests pass.
- [ ] Publish checksums for project releases when applicable.

## Priority
1. Reproducible CLI setup.
2. Diagnostics and recovery.
3. Automated tests.
4. GUI/graphics experiments.
5. Device support matrix.

## Test matrix
| Test | Environment | Expected |
|---|---|---|
| Help | Any shell | Shows options; no changes |
| Non-Termux | Desktop shell | Actionable error before mutation |
| Clean ARM64 Termux | No Debian | Installs Debian and checks architecture |
| Existing Debian | User projects exist | Reuse; never reset |
| Offline | No network | Fails early with stage |
| Interrupted | Some stages complete | Safe retry |
| Runtime incompatible | Android PRoot | Diagnostic error, no false success |
| GUI not selected | Any | No X11 or desktop downloads |

## Definition of done for v0.1
- One-shot command implemented and effects documented.
- CLI-only is default.
- Safe reruns, redacted logs and diagnostics exist.
- CI passes.
- Real-device status documented. If upstream CLI fails on Android/kernel, say so clearly.
