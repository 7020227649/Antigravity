# Module Contract (MC) and Architecture
## Standalone Antigravity IDE GUI on Termux

Status: GUI-first architecture | Version: 0.3 | Date: 2026-10-27

## 1. Architecture

The standalone IDE's official Linux ARM64 build runs in a Debian ARM64 PRoot userspace. Termux:X11 provides the Android display surface. The installer and launcher run in the native Termux shell.

    Android / Termux
      -> install.sh
         -> host preflight + consent + lock/logs
         -> termux-x11-nightly package
         -> official Termux:X11 APK approval when required
         -> official Google download page metadata
         -> Debian ARM64 install/reuse
         -> GUI libraries
         -> official Antigravity archive validation
         -> user-owned app bundle
         -> launch-gui.sh
              -> start X11 + open Android activity
              -> wait for :1 display
              -> login Debian as unprivileged antigravity user
              -> bind Termux home at /mnt/termux-home
              -> launch the original app executable

PRoot shares the Android kernel. This architecture provides glibc userspace; it does not provide a separate Linux kernel or guarantee compatibility.

## 2. Modules

### install.sh
Responsibilities: parse flags before mutations, validate host/architecture, show consent, set lock/logging, install Termux and Debian packages, resolve official artifact metadata, validate/extract the archive, install launch helpers, optionally start GUI.

Arguments: --help, --yes, --no-launch, --doctor.
Exit codes: 0 for help/doctor or completed installation path; 1 for failed installation/launch; 2 for invalid arguments or unsupported host.

Invariants:
- No implicit Debian reset.
- No unsafe no-sandbox default.
- No unverified artifact URL fallback.
- No success message when artifact/architecture validation fails.
- Existing unmanaged application directory is never overwritten.

### lib/app-metadata.sh
Exposes:
- extract_antigravity_ide_url HTML_FILE
- extract_antigravity_ide_version URL

Accepts only an official Google CDN path for the Linux ARM64 standalone Antigravity IDE archive. Does not match x64 or the separate Antigravity App archive. Missing matches are errors, not guesses.

### launch-gui.sh
Checks the installed app, Termux:X11 APK and command, starts display :1 if needed, waits at most 30 seconds, optionally appends software-rendering flags, then executes the official app inside Debian as user antigravity with shared temporary directory and a bind mount of the Termux home.

Default flags do not disable Chromium sandboxing. Arguments provided by the user are forwarded to the official app except the project-specific --software-rendering flag.

### stop-gui.sh
Sends a termination signal to the app process only. Does not stop the X11 server, because the user may be running other X11 applications.

### Debian bootstrap
Installs dependencies inside Debian APT only. Trixie/newer transitional package names (t64) are selected separately. Verifies Debian architecture is arm64, creates an unprivileged user, validates the archive, checks its main ELF machine type, and installs via a staging directory. Installs a managed `xdg-open` bridge only when no user-defined `/usr/local/bin/xdg-open` exists; the bridge routes HTTP(S) links to Android's browser through Termux.

### lib/resolve-download.py
Parses official download-page HTML to find the same-origin JavaScript bundle URL when Google does not expose the IDE archive directly in the initial HTML. The shell downloads that bundle over HTTPS; the shell metadata parser extracts only the official Linux ARM64 standalone IDE URL. The helper does not download data itself.

### lib/xdg-open-termux.sh
A Debian-side wrapper installed at `/usr/local/bin/xdg-open` when safe. It forwards HTTP(S) links to `TERMUX_PREFIX/bin/termux-open-url` and delegates other URL types to `/usr/bin/xdg-open`. The launcher passes `TERMUX_PREFIX`; OAuth callback behavior must be verified on a physical device.

### CI tests
Static tests validate Bash syntax, help/invalid argument behavior and extraction of the correct standalone IDE URL from an HTML fixture. They do not simulate Android package installation, actual X11 display startup, or GUI rendering.

## 3. External sources

- Official Antigravity download page: https://antigravity.google/download
- Official Antigravity IDE download page: https://antigravity.google/download
- Official Antigravity getting started: https://antigravity.google/docs/getting-started
- Official Termux:X11 README: https://github.com/termux/termux-x11
- Official proot-distro README: https://github.com/termux/proot-distro

## 4. Paths and ownership

- Debian app: /home/antigravity/.local/share/antigravity-ide
- Debian user's workspace mount: /mnt/termux-home
- Termux state/helpers: $HOME/.local/share/antigravity-termux
- Termux logs: $HOME/.cache/antigravity-termux/logs

The installed app directory is marked as managed by this project. Updates use a staging directory and replace only this marked directory. User settings and workspaces are outside the managed app directory.

## 5. Security

- HTTPS-only downloads and HTTPS redirects.
- Archive path checks before extraction.
- ELF architecture validation before activation.
- GUI runs as unprivileged Debian user.
- No automatic --no-sandbox; explicit flag only when the user accepts reduced isolation.
- No credential collection or telemetry added by this project.
