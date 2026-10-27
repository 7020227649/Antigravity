#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$ROOT/install.sh" ]]
bash -n "$ROOT/install.sh"
bash -n "$ROOT/tests/smoke.sh"
help_output="$(bash "$ROOT/install.sh" --help)"
grep -q -- '--doctor' <<<"$help_output"
grep -q -- '--cli-only' <<<"$help_output"
if bash "$ROOT/install.sh" --bogus >/dev/null 2>&1; then
  echo "Unexpectedly accepted unknown option" >&2
  exit 1
fi
echo "Installer syntax and argument smoke tests passed."
