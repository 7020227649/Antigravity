# Product Requirements Document (PRD)
## Standalone Antigravity IDE GUI on Android via Termux

Status: Experimental | Version: 0.3 | Date: 2026-10-27

## 1. Objective

Provide a one-shot Termux installer that attempts to launch Google's official Linux ARM64 standalone Antigravity IDE, with its native application window, on Snapdragon/ARM64 Android using Debian PRoot and Termux:X11.

This project is not satisfied by installing only the agy terminal client. The user-visible target is the standalone Antigravity IDE GUI.

## 2. Constraints and research basis

- Google's official download page lists the standalone Antigravity IDE for Linux ARM64 and documents glibc and libstdc++ minimum versions.
- The Linux application is not an Android APK. Termux uses Android's Bionic environment, while the official Linux archive expects a Linux glibc userspace.
- Debian ARM64 under proot-distro provides a standard Linux userspace but shares the Android kernel. It cannot guarantee Electron/Chromium sandbox, memory-map or graphics compatibility.
- Termux:X11 requires both an Android app APK and a companion Termux package, and supports Android 8 or later.
- No real-device end-to-end success is claimed by the current project state.

## 3. Goals

- Make the original GUI the default product path.
- Detect native Termux and ARM64 before changes.
- Install the Termux-side X11 package and open the official Termux:X11 APK installer if the app is missing.
- Resolve the current Linux ARM64 standalone Antigravity IDE URL from Google's official download page instead of relying on a hard-coded old release.
- Safely install/reuse Debian ARM64 without resetting user containers.
- Install GUI runtime libraries using release-appropriate Debian package names.
- Extract the official archive to a project-managed location, validate gzip/tar integrity and AArch64 ELF architecture, and fail safely if validation fails.
- Create an unprivileged Debian user for the GUI.
- Route external HTTP(S) links through the Android browser when possible; preserve an existing user-defined Debian xdg-open wrapper.
- Provide a launcher, stop command, log files, graphics troubleshooting, read-only diagnostics and an Android-browser bridge for external Google sign-in URLs.
- Keep the app sandbox enabled by default; only allow explicit user opt-in to a no-sandbox retry.
- Keep all routine repository changes on the main branch as requested by the owner.

## 4. Non-goals

- Claim universal compatibility with all Snapdragon/Adreno phones or Android versions.
- Claim Google's official support for Android/Termux/PRoot.
- Guarantee hardware acceleration.
- Patch or rewrite Google's application binary by default.
- Disable the Chromium sandbox automatically.
- Delete an existing Debian container or any user's project directory.
- Substitute a web interface or terminal CLI for the original desktop GUI.

## 5. Users and user stories

- An ARM64 Android user can run one installer command in native Termux.
- A user can approve Termux:X11's APK install through Android's normal system UI.
- A user can open Antigravity in a graphical window and select project files located in the shared Termux home.
- A user can inspect logs and retry with software rendering if graphics fail.
- A user gets a nonzero exit and a useful error if the official link, Debian libraries, archive structure, CPU architecture, or X11 display cannot be validated.

## 6. Functional requirements

### P0 — Installer safety
- Parse help/arguments before any file or package changes.
- Verify native Termux, regular app UID and ARM64 architecture.
- Confirm before changes unless --yes is explicitly supplied.
- Require several GB free disk space and warn when below the recommended threshold.
- Use an install lock and logs; clean temporary files on normal exit and errors.
- Use official HTTPS URLs only. Reject non-HTTPS redirects.
- Do not fetch arbitrary GitHub fork binaries, community repacks, or hard-coded obsolete app archives.
- Do not reset Debian or overwrite an unmarked application directory.

### P0 — GUI install
- Install x11-repo, termux-x11-nightly and proot-distro.
- If the Android Termux:X11 package is absent, download the official APK and request approval through Android's package installer.
- Determine the official standalone Antigravity IDE ARM64 download link from the official download page.
- Verify archive format, expected executable, and AArch64 ELF machine type.
- Install/reuse Debian ARM64 and required GTK, audio, graphics, NSS and X11 libraries.
- Create an unprivileged antigravity user.
- Store app bundle in a directory owned by that user to permit app-specific writes/updates.
- Create antigravity and antigravity-stop launch helpers.
- Launch Termux:X11 and wait a bounded time for the display before starting the app.
- Bind host Termux home into Debian under /mnt/termux-home.
- Return failure when the app process exits unsuccessfully; do not equate extraction with launch success.

### P0 — Security
- Default launch must not add --no-sandbox.
- If users explicitly retry with --no-sandbox, warn about reduced Chromium isolation and using only trusted projects.
- Keep the GUI process unprivileged inside Debian.
- Never collect, print or upload Google auth tokens or private source.

### P1 — Diagnostics and resilience
- Read-only doctor mode with Android version/API, architecture, page size, free storage, X11 app/package and Debian presence.
- Persistent install and GUI logs.
- Safe reinstall/update behavior with a marker file and staging directory.
- Tests for help, invalid arguments, URL extraction, wrong architecture/link mismatch, and archive validation.
- CI syntax and ShellCheck checks.

### P2 — Device verification
- Test the full GUI on real devices across Android/kernel versions.
- Verify login, open/modify a disposable project, and complete a simple task.
- Assess software rendering versus Adreno acceleration and record observed behavior.
- Confirm app updater behavior with the selected installation location.

## 7. Success criteria

- Static checks and URL metadata tests pass.
- The official archive resolves and validates at install time.
- X11 becomes ready, the app launches, and the original GUI appears on a documented device.
- Google login completes and a simple non-destructive task succeeds.
- Failure paths do not claim success.
- Documentation records exact tested devices and remaining limitations.

## 8. Risks

| Risk | Mitigation |
|---|---|
| Official download-page HTML changes | Fail closed when the standalone IDE URL cannot be extracted |
| Debian dependency names change | Select packages by Debian codename and log APT output |
| Kernel/memory-map or Chromium sandbox failure | Preserve logs; do not automatically disable sandbox |
| Blank window/GPU failure | Provide an opt-in software rendering flag; don't promise Adreno |
| X11 APK/package mismatch | Use the official universal debug APK and companion package |
| Browser sign-in handoff fails | Bridge xdg-open to Termux's URL opener; verify OAuth callback on device |
| Low RAM/storage | Preflight warnings/failure |
| Existing app directory contains user data | Use a marked project-managed directory and safe staged replacement |
| GUI update behavior | Keep app directory user-owned and test upstream updates |

## 9. Status policy

Use **Experimental** until a physical device completes GUI launch, authentication and a simple task. Never claim "100% works on all Android phones."
