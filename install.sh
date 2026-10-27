#!/usr/bin/env bash
# Antigravity for Termux — native Android CLI installer.
# Official upstream installer: https://antigravity.google/cli/install.sh
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_NAME="antigravity-termux"
OFFICIAL_INSTALLER_URL="https://antigravity.google/cli/install.sh"
LOG_FILE=""

usage() {
  cat <<'EOF'
Antigravity for Termux — experimental native Android installer

Usage: bash install.sh [options]
  --help        Show this help without changing anything
  --yes         Skip the confirmation prompt
  --native      Install using Google's official installer in Termux (default)
  --proot       Deprecated/experimental: not implemented in this version
  --gui         Show that the desktop GUI path is not implemented
  --doctor      Print environment diagnostics without installing

The native path avoids Debian PRoot. It succeeds only if Google's upstream
installer provides a compatible Android/Termux binary for this device.
EOF
}
YES=0
DOCTOR=0
MODE="native"
while (($#)); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --yes|-y) YES=1 ;;
    --doctor) DOCTOR=1 ;;
    --native) MODE="native" ;;
    --proot) MODE="proot" ;;
    --gui) MODE="gui" ;;
    *) usage >&2; printf '[ERROR] Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

plain_error() {
  printf '[ERROR] %s\n' "$1" >&2
  exit "${2:-1}"
}

check_host() {
  if [[ -z "${PREFIX:-}" || "$PREFIX" != */com.termux/files/usr || ! -x "$PREFIX/bin/pkg" ]]; then
    plain_error "Run this script from the native Termux app, not inside Debian/PRoot or a desktop Linux shell." 2
  fi
  local arch
  arch="$(uname -m)"
  case "$arch" in
    aarch64|arm64) ;;
    *) plain_error "This build targets ARM64 Android. Detected architecture: $arch" 2 ;;
  esac
  if [[ "$(id -u)" == "0" ]]; then
    plain_error "Do not run from a rooted shell. Run as the regular Termux app user." 2
  fi
  if [[ -z "${TERMUX_VERSION:-}" ]]; then
    printf '[WARN] TERMUX_VERSION is not set; continuing because the Termux prefix was detected.\n' >&2
  fi
}

doctor() {
  printf '== Antigravity for Termux diagnostics ==\n'
  printf 'Android release: %s\n' "$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
  printf 'Android SDK: %s\n' "$(getprop ro.build.version.sdk 2>/dev/null || echo unknown)"
  printf 'Termux version: %s\n' "${TERMUX_VERSION:-unknown}"
  printf 'Host architecture: %s\n' "$(uname -m)"
  printf 'Termux prefix: %s\n' "${PREFIX:-unknown}"
  printf 'Page size: %s\n' "$(getconf PAGE_SIZE 2>/dev/null || echo unavailable)"
  printf 'Available storage: '
  df -h "$HOME" 2>/dev/null | tail -n 1 || echo unavailable
  printf 'curl: '
  command -v curl 2>/dev/null || echo missing
  local agy_path=""
  if [[ -x "$HOME/.local/bin/agy" ]]; then
    agy_path="$HOME/.local/bin/agy"
  elif command -v agy >/dev/null 2>&1; then
    agy_path="$(command -v agy)"
  fi
  printf 'agy path: %s\n' "${agy_path:-not-installed}"
  if [[ -n "$agy_path" ]]; then
    printf 'agy version: '
    "$agy_path" --version 2>&1 || echo "version check failed"
  fi
  printf '\nNo environment variables, tokens, or project files are collected.\n'
}

check_host
if ((DOCTOR)); then doctor; exit 0; fi
case "$MODE" in
  proot) plain_error "The old Debian/PRoot route is intentionally not the default: PRoot shares Android's kernel and cannot remove syscall or virtual-address constraints. This release supports the native official-installer path only." 2 ;;
  gui) plain_error "The desktop GUI / Termux:X11 path is not implemented. This installer targets the native CLI." 2 ;;
esac

LOG_DIR="$HOME/.cache/$PROJECT_NAME/logs"
if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
  LOG_DIR="$HOME/$PROJECT_NAME-logs"
  mkdir -p "$LOG_DIR" || plain_error "Cannot create a writable log directory." 1
fi
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
: > "$LOG_FILE" || plain_error "Cannot write log file: $LOG_FILE" 1

log() { printf '%s\n' "$*" | tee -a "$LOG_FILE"; }
info() { printf '[INFO] %s\n' "$*" | tee -a "$LOG_FILE"; }
warn() { printf '[WARN] %s\n' "$*" | tee -a "$LOG_FILE" >&2; }
die() { local code="${2:-1}"; printf '[ERROR] %s\n' "$1" | tee -a "$LOG_FILE" >&2; exit "$code"; }
on_err() {
  local rc=$?
  trap - ERR
  warn "Stopped with exit code $rc. Read the log: $LOG_FILE"
  exit "$rc"
}
trap on_err ERR

cat <<'EOF'
This installer will:
  1. Install/update curl and CA certificates from configured Termux repositories.
  2. Download Google's official Antigravity CLI installer over HTTPS.
  3. Run that installer in native Termux (no Debian/PRoot).
  4. Require the command agy --version to pass before reporting success.

Compatibility remains experimental: Android/device support is not explicitly
guaranteed for every phone. The installer fails rather than claim success if
the upstream installer or CLI smoke test fails.
EOF

if (( ! YES )); then
  read -r -p "Proceed with the native Termux CLI install? [y/N] " answer
  case "$answer" in y|Y|yes|YES) ;; *) log "Cancelled by user."; exit 0 ;; esac
fi

info "Updating Termux package metadata..."
pkg update 2>&1 | tee -a "$LOG_FILE"
info "Installing curl and CA certificates..."
pkg install -y curl ca-certificates 2>&1 | tee -a "$LOG_FILE"
command -v curl >/dev/null 2>&1 || die "curl is not available after package installation."

tmp="$(mktemp)"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

info "Downloading official installer from $OFFICIAL_INSTALLER_URL"
curl --fail --location --silent --show-error --retry 2 --connect-timeout 15 \
  --proto '=https' --tlsv1.2 "$OFFICIAL_INSTALLER_URL" -o "$tmp"
[[ -s "$tmp" ]] || die "The official installer download was empty."
if ! head -n 1 "$tmp" | grep -qE '^#!.*(sh|bash)'; then
  die "Downloaded installer did not look like a shell script; refusing to execute it."
fi

info "Running Google's official installer."
bash "$tmp" 2>&1 | tee -a "$LOG_FILE"

export PATH="$HOME/.local/bin:$PREFIX/bin:$PATH"
AGY_BIN=""
if [[ -x "$HOME/.local/bin/agy" ]]; then
  AGY_BIN="$HOME/.local/bin/agy"
elif command -v agy >/dev/null 2>&1; then
  AGY_BIN="$(command -v agy)"
fi
[[ -n "$AGY_BIN" && -x "$AGY_BIN" ]] || die "The installer exited successfully, but no executable agy was found in ~/.local/bin or PATH."
info "Verifying the actual CLI binary with --version."
if ! "$AGY_BIN" --version 2>&1 | tee -a "$LOG_FILE"; then
  die "agy --version failed. Do not assume the install worked. Check the log; Android syscall or binary compatibility may be the blocker." 1
fi

log ""
log "SUCCESS: agy --version completed."
log "Start the CLI from a project directory with: agy"
log "Installer log: $LOG_FILE"
log "Authentication and a real coding session have not been tested by this installer."
