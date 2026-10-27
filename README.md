# Antigravity for Termux

An experimental project exploring whether Google's Antigravity CLI—and optionally its Linux desktop UI—can run on ARM64 Android phones using Termux and Debian PRoot.

**Unofficial and experimental.** Google does not list Android/Termux PRoot as a supported environment. Snapdragon/ARM64 hardware does not guarantee compatibility. CLI is the first priority; desktop GUI and Adreno acceleration are optional research tasks.

## One-shot installer (CLI-first alpha)

Run these commands in the **Termux app itself**, not inside a Debian shell:

```bash
pkg update
pkg install -y git
git clone https://github.com/7020227649/antigravity.git
cd antigravity
bash install.sh
```

Review the script before running it. It installs/reuses Debian via `proot-distro`, installs baseline tools, and then invokes Google's documented CLI installer inside Debian. It asks for confirmation; `--yes` skips that prompt but does not enable destructive resets.

Options:
- `bash install.sh --help`
- `bash install.sh --doctor`
- `bash install.sh --cli-only`
- `bash install.sh --yes`

The `--gui` option is reserved and intentionally exits with a message; GUI mode is not implemented yet.

## Current limitations
- Google does not list Android/Termux PRoot as a supported environment.
- PRoot shares the Android kernel; memory layout, allocator, browser authentication, keyring, missing system services and graphics can fail.
- The script checks for Debian before installing and never resets an existing distro.
- The installer does not request root, collect credentials or automatically disable sandboxing.
- CLI installation and a version/help smoke test do not guarantee an authenticated coding session.
- Adreno hardware acceleration is not promised.

## Development
Read [PRD](docs/PRD.md), [Module Contract](docs/MC.md) and [Plan](docs/PLAN.md).
Run basic static tests with:

```bash
bash tests/smoke.sh
```

## Diagnostic reports
Include device/chipset, Android build, Termux version/source, `uname -m`, Debian architecture/release, `getconf PAGE_SIZE`, available storage and sanitized error output. Never post tokens, cookies or secret-bearing OAuth callback URLs.
