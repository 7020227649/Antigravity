#!/data/data/com.termux/files/usr/bin/bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
bash -n "$ROOT/install.sh" || fail=1
bash -n "$ROOT/tests/smoke.sh" || fail=1
if (( fail )); then
  echo "Shell syntax tests failed." >&2
  exit 1
fi
echo "Shell syntax tests passed."
