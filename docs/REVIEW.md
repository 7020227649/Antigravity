# Repository Review — 2026-10-27

## Summary

The earlier prototype was not ready to describe as reliable. It installed the Linux CLI inside Debian PRoot, used a very small test suite, and could warn when the CLI smoke test failed yet still exit through the success path. No physical Android test had been performed.

The repository has now been changed to prefer the native Termux route. The upstream Antigravity CLI changelog states that prebuilt native Android binaries were added in v1.2.15. This is a more appropriate baseline than assuming the Linux ARM64 binary is equivalent on Android. It is still an experimental integration until the official installer is confirmed to select a native artifact and a real device completes the test.

## Findings fixed in this review

1. **Wrong default execution environment:** changed from Debian PRoot to native Termux. PRoot shares Android's kernel and cannot bypass kernel syscall restrictions.
2. **False-success path:** install success now requires the actual agy --version command to exit zero.
3. **Help/preflight side effects:** command-line options are parsed before logging directories are created. Help and invalid-option paths are tested for no writes.
4. **Insufficient smoke test:** expanded coverage from syntax-only to argument/preflight behavior, and made CI execute the test script.
5. **Unsupported flags looked plausible:** --proot and --gui explicitly fail instead of silently implying the feature works.
6. **Unclear support status:** docs distinguish installed, process-start smoke-tested, authenticated and end-to-end device-verified.

## Remaining blockers

- No real Android device is attached to this review environment; native Termux install, Google login and actual agent execution remain unverified.
- The upstream installer behavior must be checked on the actual Termux build; a shell download and a filename do not prove the correct Android artifact was selected.
- Storage preflight, install locking, stale-lock recovery and mocked failure-path tests are still future hardening tasks.
- The project cannot honestly promise 100% support for all Snapdragon/Android combinations.

## References

- Official CLI changelog: https://github.com/google-antigravity/antigravity-cli/blob/main/CHANGELOG.md
- Official installation guide: https://antigravity.google/docs/cli/install/
- Official Termux app: https://github.com/termux/termux-app
- Official PRoot-Distro docs: https://github.com/termux/proot-distro
