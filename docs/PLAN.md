# Implementation Plan
## Standalone Antigravity IDE GUI on Android

Version: 0.3 | Date: 2026-10-27
Product focus: standalone Antigravity IDE GUI, not CLI-only.

## Milestone 0 — Direction
- [x] Inspect official standalone IDE Linux ARM64 availability.
- [x] Confirm Termux:X11 needs both Android APK and companion package.
- [x] Replace CLI-only project objective with GUI-first objective.
- [x] Replace the CLI-only installer with GUI install/launch path on main.

## Milestone 1 — Installer core
- [x] Parse options/help before file mutations.
- [x] Verify native Termux and ARM64.
- [x] Install Termux:X11 package and request Android APK approval when missing.
- [x] Resolve the current official standalone IDE ARM64 link from Google's download page or its JavaScript bundle.
- [x] Install/reuse Debian without reset.
- [x] Install GUI libraries according to Debian codename.
- [x] Validate gzip/tar contents and AArch64 ELF.
- [x] Use a staging directory and marked managed app path.
- [x] Create unprivileged GUI user and launcher commands.
- [x] Add optional Android browser handoff for external HTTP(S) links while preserving an existing user-defined xdg-open wrapper.
- [x] Keep --no-sandbox opt-in.
- [ ] Confirm on-device behavior of the official standalone IDE URL parser and archive layout.

## Milestone 2 — Display and launch
- [x] Start Termux:X11 and open its Android activity.
- [x] Wait for display readiness with a timeout.
- [x] Share the Termux home into Debian at /mnt/termux-home.
- [x] Add software-rendering troubleshooting and stop command.
- [ ] Verify the PRoot login option combinations on actual Termux release.
- [ ] Confirm IDE GUI window opens and is touch-usable.
- [ ] Confirm sandbox behavior; document only evidence-based advice.

## Milestone 3 — Quality
- [x] Shell syntax and metadata fixture tests, including JavaScript-bundle fallback and browser handoff wrapper.
- [x] ShellCheck CI.
- [ ] Add mocked tests for archive extraction, Debian package failure and X11 timeout.
- [ ] Confirm GitHub Actions latest run is green after current commit.
- [ ] Test reinstallation and recovery from interrupted download.

## Milestone 4 — Device validation
- [ ] Test on one Snapdragon ARM64 phone with 8 GB RAM and at least 6 GB free storage (recommended target, not official minimum).
- [ ] Record exact phone model, Android version/API, kernel/page size and Termux source.
- [ ] Confirm app launches to original GUI.
- [ ] Complete Google authentication.
- [ ] Open a disposable project under /mnt/termux-home and run a small non-destructive task.
- [ ] Test software-rendering fallback.
- [ ] Test a second Android/kernel generation before broad compatibility claims.

## Definition of done

Static CI passes and a documented real-device test completes GUI launch, Google login and a simple task. If app launch fails on a device, record the exact logs and do not label that device supported. No universal "100% works" statement is allowed.
