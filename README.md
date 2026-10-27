# Standalone Antigravity IDE for Termux

This project aims to run Google's **standalone Antigravity IDE desktop GUI** on an ARM64 Android phone using Termux, Debian ARM64 under PRoot, and the official Termux:X11 display server.

This is an experimental community compatibility project. It is not an Android port, and Google does not list Android/Termux/PRoot as a supported desktop platform. The official standalone Linux IDE requires glibc and libstdc++ versions documented on Google's download page. Termux:X11 supplies an Android X server and must be installed both as an Android APK and as a Termux package.

## One-shot install

1. Install Termux from [official Termux releases](https://github.com/termux/termux-app/releases) or [F-Droid](https://f-droid.org/packages/com.termux/), then open it.
2. Paste these commands into Termux:

~~~bash
pkg update
pkg install -y git
git clone https://github.com/7020227649/antigravity.git
cd antigravity
bash install.sh
~~~

The installer asks before changing packages. If Termux:X11's Android app is missing, it downloads the official universal debug APK and opens Android's package installer. Approve the Android prompt, return to Termux, and press Enter. Android's install-unknown-apps permission may need to be enabled for Termux.

The installer resolves the current Linux ARM64 **Antigravity IDE (Standalone)** archive from Google's official download page, falling back to the official page's JavaScript metadata when the link is not present in its HTML. It does not install the newer Antigravity App or the terminal-only CLI. It installs or reuses Debian without resetting existing containers, checks the downloaded archive, verifies the executable is AArch64, and writes launch helpers.

Google sign-in commonly opens an external browser. The installer adds a Debian `xdg-open` bridge that routes HTTP(S) links to Android's default browser through Termux. If Debian already has a custom `/usr/local/bin/xdg-open`, the installer preserves it; browser sign-in then may need manual configuration. The full browser callback still requires real-device verification.

## Usage

Launch the original GUI:

~~~bash
antigravity
~~~

Stop the Antigravity GUI without shutting down Termux:X11:

~~~bash
antigravity-stop
~~~

Install/update without automatically opening the GUI:

~~~bash
bash install.sh --no-launch
~~~

Read-only diagnostics:

~~~bash
bash install.sh --doctor
~~~

## Troubleshooting

- **Termux:X11 does not open:** confirm the Termux:X11 Android app and the Termux package from the official X11 repository are both installed. Check the X11 log in $HOME/.cache/antigravity-termux/logs/x11.log.
- **Blank window or GPU error:** try the command antigravity --software-rendering. Adreno acceleration is not guaranteed; software rendering may be slower.
- **Chromium sandbox initialization error:** first inspect the error log. Only for trusted workspaces, an explicit antigravity --no-sandbox retry is available. This lowers Chromium's isolation and must not be enabled silently.
- **Missing libraries:** rerun bash install.sh; review the install log in $HOME/.cache/antigravity-termux/logs/.
- **Not enough storage:** several GB are required for Debian, GUI libraries, and the app archive. Six GB free is recommended.

Inside the Debian GUI, the host Termux home is available at /mnt/termux-home so you can open projects from the phone's Termux home. Files are modified with the permissions of the Termux Android app user.

## What is verified?

GitHub Actions verifies shell syntax, command-line behavior, extraction of the standalone IDE URL from a representative download-page fixture, and fallback selection of the official JavaScript bundle. That does **not** prove the GUI starts on every Android phone. Before calling a device supported, a real-device test must confirm the window opens, authentication completes, and a simple agent task succeeds.

GPU acceleration, auto-update behavior, audio and Chromium sandbox compatibility vary by Android build. Google does not officially support this environment.

## Project docs

- [Product requirements](docs/PRD.md)
- [Module contract and architecture](docs/MC.md)
- [Implementation plan](docs/PLAN.md)
- [Technical review](docs/REVIEW.md)
- [Official Antigravity download](https://antigravity.google/download)
- [Official Termux:X11 setup](https://github.com/termux/termux-x11)
