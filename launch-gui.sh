#!/usr/bin/env bash
# Launch the official standalone Antigravity IDE through Debian PRoot + Termux:X11.
set -Eeuo pipefail
IFS=$'\n\t'
[[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/files/usr ]] || { echo "[ERROR] Run in native Termux." >&2; exit 2; }
command -v proot-distro >/dev/null 2>&1 || { echo "[ERROR] proot-distro is missing; rerun install.sh." >&2; exit 2; }
command -v termux-x11 >/dev/null 2>&1 || { echo "[ERROR] termux-x11 is missing; rerun install.sh." >&2; exit 2; }
command -v xdpyinfo >/dev/null 2>&1 || { echo "[ERROR] xdpyinfo is missing; install xorg-xdpyinfo." >&2; exit 2; }
if command -v pm >/dev/null 2>&1; then
  pm path com.termux.x11 >/dev/null 2>&1 || { echo "[ERROR] Install the Termux:X11 Android app first." >&2; exit 2; }
fi
LOG_DIR="$HOME/.cache/antigravity-termux/logs"
mkdir -p "$LOG_DIR"
GUI_LOG="$LOG_DIR/gui-$(date +%Y%m%d-%H%M%S).log"
DISPLAY_NUM="${ANTIGRAVITY_DISPLAY:-:1}"
APP_REL="$(proot-distro login debian -- /bin/cat /home/antigravity/.local/share/antigravity-ide/.bundle-path 2>/dev/null || true)"
[[ -n "$APP_REL" && "$APP_REL" != /* && "$APP_REL" != *..* ]] || { echo "[ERROR] GUI not installed; run bash install.sh." >&2; exit 2; }
proot-distro login debian -- /bin/test -x "/home/antigravity/.local/share/antigravity-ide/$APP_REL" || { echo "[ERROR] GUI binary missing; rerun install.sh." >&2; exit 2; }
if ! pgrep -x termux-x11 >/dev/null 2>&1; then
  echo "[INFO] Starting Termux:X11 on display $DISPLAY_NUM."
  termux-x11 "$DISPLAY_NUM" >"$LOG_DIR/x11.log" 2>&1 &
fi
if command -v am >/dev/null 2>&1; then am start -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1 || true; fi
ready=0
for _ in $(seq 1 30); do
  if xdpyinfo -display "$DISPLAY_NUM" >/dev/null 2>&1; then ready=1; break; fi
  sleep 1
done
if (( ! ready )); then
  echo "[ERROR] Termux:X11 did not become ready within 30 seconds. Check $LOG_DIR/x11.log." >&2
  exit 1
fi
APP_ARGS=()
SOFTWARE_RENDERING=0
for arg in "$@"; do
  case "$arg" in --software-rendering) SOFTWARE_RENDERING=1 ;; *) APP_ARGS+=("$arg") ;; esac
done
if ((SOFTWARE_RENDERING)); then APP_ARGS+=(--disable-gpu --disable-gpu-compositing); fi
printf '[INFO] Launching Antigravity GUI. Log: %s\n' "$GUI_LOG"
set +e
proot-distro login --user antigravity --shared-tmp --bind "$HOME:/mnt/termux-home" debian -- \
  /usr/bin/env DISPLAY="$DISPLAY_NUM" XDG_RUNTIME_DIR=/tmp TERMUX_PREFIX="$PREFIX" \
  /usr/bin/dbus-launch --exit-with-session "/home/antigravity/.local/share/antigravity-ide/$APP_REL" "${APP_ARGS[@]}" \
  2>&1 | tee -a "$GUI_LOG"
rc=${PIPESTATUS[0]}
set -e
if ((rc != 0)); then
  echo "[WARN] Antigravity exited with status $rc. Read $GUI_LOG." >&2
  echo "If the error explicitly concerns Chromium sandbox initialization, only for trusted projects, retry: antigravity --no-sandbox" >&2
  echo "For a blank window or GPU errors, try: antigravity --software-rendering" >&2
fi
exit "$rc"
