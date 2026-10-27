# Technical Review — Standalone Antigravity IDE GUI target
Date: 2026-10-27

## Important product correction

The previous main branch had drifted to the Antigravity CLI. That did not satisfy the user's requirement for the original GUI. The product target is now the official standalone Antigravity IDE desktop GUI for Linux ARM64.

## Research findings

- Google's current download page distinguishes Antigravity App, Antigravity CLI, and standalone Antigravity IDE. The standalone IDE download uses the official Linux ARM64 archive named `Antigravity%20IDE.tar.gz`; its extracted launcher is `antigravity-ide` in the `Antigravity IDE` directory.
- Google's Linux standalone IDE requirements list glibc >= 2.28 and libstdc++ >= 3.4.25.
- Termux runs Android/Bionic, so the chosen initial route is a Debian ARM64 userspace plus Termux:X11 rather than assuming a Linux ELF can run directly in Termux.
- Termux:X11 requires its Android APK as well as the companion package from x11-repo. Its documented use with PRoot requires sharing the temporary directory so the X11 socket is visible.

## Changes made on main

- Replaced CLI-first installer with GUI-first setup.
- Resolve the current official standalone IDE ARM64 archive from Google's download page, with a fallback to the official same-origin JavaScript bundle when the HTML omits the link; no guessed old URL fallback.
- Install/reuse Debian without reset and install GUI dependencies by Debian release.
- Validate archive gzip/tar integrity, reject obvious absolute/parent-traversal paths, verify the app executable is AArch64, and stage updates before replacing the managed directory.
- Create an unprivileged Debian user and expose the Termux home through /mnt/termux-home.
- Start Termux:X11 with a timeout and log paths.
- Do not add --no-sandbox by default; require an explicit user retry if an error supports that diagnosis.
- Add a managed xdg-open bridge to route external HTTP(S) links to the Android browser for potential Google sign-in.
- Replace the CLI mock test with shell/metadata fixture tests and CI lint.

## Remaining risks / not yet verified

- This environment cannot run the installer on a physical Snapdragon phone.
- The official download page HTML or JavaScript bundle could change; the installer fails closed if the standalone IDE URL pattern cannot be resolved.
- The exact official archive layout and required dependencies are checked during install, but not verified in a real Android PRoot run.
- Chromium sandbox behavior, GPU acceleration, login/browser handoff, window behavior, app updates, and memory stability require real-device testing.
- GUI launch is not guaranteed on all Snapdragon/Adreno devices. Adreno presence does not by itself guarantee that X11/Electron hardware acceleration is available.

## References

- Google Antigravity download: https://antigravity.google/download
- Google getting started: https://antigravity.google/docs/getting-started
- Termux:X11: https://github.com/termux/termux-x11
- proot-distro: https://github.com/termux/proot-distro
- Community GUI reference implementation (reviewed, not copied wholesale): https://github.com/kuromi04/termux-antigravity
