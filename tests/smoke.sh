#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT

bash -n "$ROOT/install.sh"
bash -n "$ROOT/tests/smoke.sh"

help_output="$(env -u PREFIX -u TERMUX_VERSION HOME="$tmp_home" bash "$ROOT/install.sh" --help)"
grep -q -- '--doctor' <<<"$help_output"
grep -q -- '--native' <<<"$help_output"

if env -u PREFIX -u TERMUX_VERSION HOME="$tmp_home" bash "$ROOT/install.sh" --unknown >/dev/null 2>&1; then
  echo "Unexpectedly accepted unknown option" >&2
  exit 1
fi
[[ ! -e "$tmp_home/.cache/antigravity-termux" ]]

if env -u PREFIX -u TERMUX_VERSION HOME="$tmp_home" bash "$ROOT/install.sh" --doctor >/dev/null 2>&1; then
  echo "Doctor unexpectedly accepted a non-Termux environment" >&2
  exit 1
fi
[[ ! -e "$tmp_home/.cache/antigravity-termux" ]]

echo "Installer syntax and argument/preflight smoke tests passed."
