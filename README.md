# Antigravity for Termux

An experimental project exploring whether Google's Antigravity CLI—and optionally its Linux desktop UI—can run on ARM64 Android phones using Termux and Debian PRoot.

**Unofficial and experimental.** Google does not list Android/Termux PRoot as a supported environment. Snapdragon/ARM64 hardware does not guarantee compatibility. CLI is the first priority; desktop GUI and Adreno acceleration are optional research tasks.

## Current status
This repository is in planning and initial implementation. Read the [PRD](docs/PRD.md), [module contract](docs/MC.md) and [implementation plan](docs/PLAN.md). A successful download is not evidence of a successful launch.

## Intended workflow
The target user experience after implementation is:

```bash
pkg install -y git
git clone https://github.com/7020227649/antigravity.git
cd antigravity
bash install.sh
```

**The complete one-shot installer is not implemented yet in this commit.** Do not treat this command as functional until `install.sh` lands and is tested.

## Planned features
- Termux and ARM64 preflight checks.
- Debian ARM64 setup through `proot-distro`.
- Official Google Antigravity CLI installation attempt.
- Safe retries, logs, recovery guidance and diagnostic mode.
- Optional Termux:X11 desktop experiment after CLI compatibility testing.

## Limitations and safety
- Android and Debian PRoot share the Android kernel. A Linux ARM64 binary may fail due to memory layout, keyring, browser auth, missing system services or graphics.
- Installer will not silently delete an existing Debian environment or project files.
- GUI mode will not promise Adreno GPU acceleration.
- Installer will not disable the app sandbox automatically.
- Prefer official Google distribution endpoints; avoid repackaged binaries by default.

## Report a result
Include phone/chipset, Android build, Termux version/source, `uname -m`, `dpkg --print-architecture`, Debian release, `getconf PAGE_SIZE`, available storage, exact command and sanitized error. Never submit tokens, cookies, secret-bearing OAuth callback URLs or private source files.

See [docs/PLAN.md](docs/PLAN.md) for milestones.
