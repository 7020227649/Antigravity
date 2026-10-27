#!/usr/bin/env bash
set -Eeuo pipefail
if [[ -z "${PREFIX:-}" || "$PREFIX" != */com.termux/files/usr ]]; then
  echo "[ERROR] Run antigravity-stop from native Termux." >&2
  exit 2
fi
command -v proot-distro >/dev/null 2>&1 || { echo "[ERROR] proot-distro is missing." >&2; exit 2; }
proot-distro login --user antigravity debian -- /usr/bin/pkill -TERM -f '[/]home/antigravity/.local/share/antigravity-ide/' 2>/dev/null || true
echo "Sent a stop signal to Antigravity. Termux:X11 was left running for other X11 apps."
