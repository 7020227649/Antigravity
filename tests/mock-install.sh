#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PREFIX="$WORK/data/data/com.termux/files/usr"
MOCKBIN="$WORK/mockbin"
SUCCESS_HOME="$WORK/home-success"
FAIL_HOME="$WORK/home-cli-fail"
UPSTREAM_FAIL_HOME="$WORK/home-upstream-fail"
mkdir -p "$PREFIX/bin" "$MOCKBIN" "$SUCCESS_HOME" "$FAIL_HOME" "$UPSTREAM_FAIL_HOME"

cat > "$PREFIX/bin/pkg" <<'PKG'
#!/usr/bin/env bash
printf 'mock pkg %s\n' "$*"
exit 0
PKG
cat > "$MOCKBIN/id" <<'ID'
#!/usr/bin/env bash
if [[ "$1" == "-u" ]]; then echo 10123; else /usr/bin/id "$@"; fi
ID
cat > "$MOCKBIN/uname" <<'UNAME'
#!/usr/bin/env bash
if [[ "$1" == "-m" ]]; then echo aarch64; else /usr/bin/uname "$@"; fi
UNAME
cat > "$MOCKBIN/curl" <<'CURL'
#!/usr/bin/env bash
out=""
while (($#)); do
  if [[ "$1" == "-o" ]]; then
    shift
    out="$1"
  fi
  shift || true
done
[[ -n "$out" ]] || exit 2
cat > "$out" <<'INSTALLER'
#!/usr/bin/env bash
if [[ "${FAKE_UPSTREAM_FAIL:-0}" == "1" ]]; then exit 9; fi
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/agy" <<'AGY'
#!/usr/bin/env bash
if [[ "$1" == "--version" ]]; then
  if [[ "${FAKE_AGY_FAIL:-0}" == "1" ]]; then
    echo "mock runtime error" >&2
    exit 17
  fi
  echo "agy mock 1.0.0"
  exit 0
fi
exit 0
AGY
chmod +x "$HOME/.local/bin/agy"
INSTALLER
exit 0
CURL
chmod +x "$PREFIX/bin/pkg" "$MOCKBIN/id" "$MOCKBIN/uname" "$MOCKBIN/curl"

BASE_ENV=("PATH=$MOCKBIN:$PREFIX/bin:/usr/bin:/bin" "PREFIX=$PREFIX" "TERMUX_VERSION=mock")
success_output="$(env "${BASE_ENV[@]}" HOME="$SUCCESS_HOME" bash "$ROOT/install.sh" --yes 2>&1)"
grep -q 'SUCCESS: agy --version completed' <<<"$success_output"
grep -q 'agy mock 1.0.0' <<<"$success_output"

if fail_output="$(env "${BASE_ENV[@]}" HOME="$FAIL_HOME" FAKE_AGY_FAIL=1 bash "$ROOT/install.sh" --yes 2>&1)"; then
  echo "Installer incorrectly succeeded when agy --version failed." >&2
  exit 1
else
  fail_status=$?
fi
[[ "$fail_status" -ne 0 ]]
if grep -q 'SUCCESS: agy --version completed' <<<"$fail_output"; then
  echo "Failure path printed a success message." >&2
  exit 1
fi
grep -q 'agy --version failed' <<<"$fail_output"

if upstream_output="$(env "${BASE_ENV[@]}" HOME="$UPSTREAM_FAIL_HOME" FAKE_UPSTREAM_FAIL=1 bash "$ROOT/install.sh" --yes 2>&1)"; then
  echo "Installer incorrectly succeeded when the upstream installer failed." >&2
  exit 1
else
  upstream_status=$?
fi
[[ "$upstream_status" -ne 0 ]]
if grep -q 'SUCCESS: agy --version completed' <<<"$upstream_output"; then
  echo "Upstream failure path printed a success message." >&2
  exit 1
fi

echo "Mock install tests passed: success, CLI failure, and upstream failure."
