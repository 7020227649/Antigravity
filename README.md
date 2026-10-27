# Antigravity for Termux

An experimental installer for attempting to run Google's Antigravity CLI (agy) on ARM64 Android through Termux.

**Important:** the preferred route is now the native Termux installer, because Google's CLI changelog says prebuilt Android binaries were added in version 1.2.15. The standard docs do not guarantee support for every phone/build, so this project validates the actual installed binary with agy --version rather than assuming the install succeeded. See the [upstream changelog](https://github.com/google-antigravity/antigravity-cli/blob/main/CHANGELOG.md) and [official installation guide](https://antigravity.google/docs/cli/install/).

## One-shot install

Install Termux from an official source such as [F-Droid](https://f-droid.org/packages/com.termux/) or [Termux GitHub releases](https://github.com/termux/termux-app/releases). Open the Termux app, then run:

    pkg update
    pkg install -y git
    git clone https://github.com/7020227649/antigravity.git
    cd antigravity
    bash install.sh

Review install.sh before running it. It downloads the official Google installer over HTTPS, runs it in native Termux (not Debian/PRoot), then requires agy --version to pass. If verification fails, it returns an error and logs the failure instead of claiming success.

Options:

    bash install.sh --help
    bash install.sh --doctor
    bash install.sh --native
    bash install.sh --yes

The --proot and --gui options are deliberately blocked in this release. They are not implemented as working paths; the native Android CLI path is the first priority.

## What this does not guarantee

- Every Snapdragon, Android release or kernel layout works.
- Authentication/browser handoff or a complete coding session will succeed just because agy --version passes.
- A desktop IDE or Adreno GPU acceleration is available.
- Google explicitly supports all Termux/device combinations.

PRoot is not a VM: it shares the Android kernel. A Linux ARM64 executable can still fail due to kernel syscall restrictions even when Debian's userspace is correct.

## Diagnostics

Run bash install.sh --doctor in native Termux. It prints selected device/runtime facts only; it does not upload reports or collect secrets. To report a failure, include the Android version/build, Termux source/version, uname -m, getconf PAGE_SIZE, available storage, exact command and sanitized error output. Never share tokens, cookies, OAuth callback URLs containing secrets, or private source code.

## Development

- [PRD](docs/PRD.md)
- [Module contract](docs/MC.md)
- [Implementation plan](docs/PLAN.md)

Run local checks with bash tests/smoke.sh and bash tests/mock-install.sh. The mock tests simulate upstream success, upstream failure and a failed CLI version check. They validate installer control flow, not real Android/Termux compatibility.
