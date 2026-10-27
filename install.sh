#!/data/data/com.termux/files/usr/bin/bash
# Antigravity for Termux — experimental CLI-first installer.
# Source project: https://github.com/7020227649/antigravity
set -Eeuo pipefail
IFS=$'\n\t'

PROJECT_NAME="antigravity-termux"
LOG_DIR="${PREFIX:-$HOME}/var/log/$PROJECT_NAME"
STATE_DIR="${PREFIX:-$HOME}/var/lib/$PROJECT_NAME"
mkdir -p "$LOG_DIR" "$STATE_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
: > "$LOG_FILE" 2>/dev/null || LOG_FILE="$HOME/.antigravity-termux-install.log"

RED='' GREEN='' YELLOW='' BLUE='' RESET=''
if [[ -t 1 ]]; then
  RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; BLUE=$'\033[34m'; RESET=$'\033[0m'
fi

log() { printf '%s\n' "$*" | tee -a "$LOG_FILE"; }
info() { printf '%s[INFO]%s %s\n' "$BLUE" "$RESET" "$*" | tee -a "$LOG_FILE"; }
warn() { printf '%s[WARN]%s %s\n' "$YELLOW" "$RESET" "$*" | tee -a "$LOG_FILE" >&2; }
die() { local code="${2:-1}"; printf '%s[ERROR]%s %s\n' "$RED" "$RESET" "$1" | tee -a "$LOG_FILE" >&2; exit "$code"; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Antigravity for Termux — experimental one-shot installer

Usage: bash install.sh [options]
  --help        Show this help without changes
  --yes         Skip confirmation (no destructive resets are performed)
  --cli-only    Install/test official CLI path (default)
  --gui         Reserved for future optional Termux:X11 experiment
  --doctor      Run platform diagnostics only
EOF
}
YES=0 DOCTOR=0 GUI=0
while (($#)); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --yes|-y) YES=1 ;;
    --doctor) DOCTOR=1 ;;
    --gui) GUI=1 ;;
    --cli-only) GUI=0 ;;
    *) usage; die "Unknown option: $1" 2 ;;
  esac
  shift
done

on_err() {
  local rc=$?
  warn "Installation stopped (exit $rc). See log: $LOG_FILE"
  exit "$rc"
}
trap on_err ERR

check_host() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]] || die "Run this script inside the Termux app, not inside Debian or a desktop shell." 2
  local arch
  arch="$(uname -m)"
  [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] || die "This initial release targets ARM64 Termux. Detected: $arch" 2
  have pkg || die "Termux package manager 'pkg' was not found." 2
}
doctor() {
  echo "== Antigravity for Termux diagnostics =="
  printf 'Android release: %s\n' "$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
  printf 'Android SDK: %s\n' "$(getprop ro.build.version.sdk 2>/dev/null || echo unknown)"
  printf 'Termux arch: %s\n' "$(uname -m)"
  printf 'Termux prefix: %s\n' "${PREFIX:-unknown}"
  printf 'Storage available: '
  df -h "$HOME" 2>/dev/null | tail -n 1 || true
  printf 'proot-distro: '
  if have proot-distro; then echo installed; else echo missing; fi
  printf 'Termux:X11 command: '
  if have termux-x11; then echo installed; else echo not-installed; fi
  printf 'Debian state: '
  if have proot-distro; then proot-distro list 2>/dev/null | grep -i debian || echo "not detected"; else echo "proot-distro missing"; fi
  echo "No environment variables, tokens, or project files are collected."
}
if ((DOCTOR)); then
  check_host
  doctor
  exit 0
fi

check_host
if ((GUI)); then
  die "GUI mode is not implemented yet. Use --cli-only; desktop support will be added after CLI testing." 2
fi

cat <<'EOF'
This installer will:
  1. Update Termux package metadata and install proot-distro/curl.
  2. Install Debian only if it is not already listed by proot-distro.
  3. Install basic Linux tools inside Debian.
  4. Fetch and run Google's official Antigravity CLI installer inside Debian.
  5. Attempt a CLI version/help smoke check.

Compatibility is experimental. Google does not officially list Android/Termux/PRoot as supported.
This script does not reset/delete existing Debian and does not enable --no-sandbox.
EOF
if (( ! YES )); then
  read -r -p "Proceed with CLI-only setup? [y/N] " answer
  case "$answer" in y|Y|yes|YES) ;; *) log "Cancelled by user."; exit 0 ;; esac
fi

info "Log file: $LOG_FILE"
have curl || pkg install -y curl
info "Checking official installer URL over HTTPS..."
curl -fsSI --connect-timeout 10 https://antigravity.google/cli/install.sh >/dev/null || die "Cannot reach Google's CLI installer over HTTPS. Check network/time/TLS and retry." 1

info "Updating Termux package metadata and installing proot-distro..."
pkg update
pkg install -y proot-distro curl

if ! proot-distro list 2>/dev/null | grep -Eiq 'debian'; then
  info "Debian not detected; installing Debian."
  proot-distro install debian
else
  info "Debian appears installed; reusing without reset."
fi

info "Checking Debian architecture..."
ARCH="$(proot-distro login debian -- /usr/bin/dpkg --print-architecture 2>/dev/null | tail -n 1 || true)"
[[ "$ARCH" == "arm64" ]] || die "Debian reports '${ARCH:-empty}', expected arm64. No reset attempted." 1

info "Installing Debian baseline tools..."
proot-distro login debian -- /usr/bin/env DEBIAN_FRONTEND=noninteractive /bin/bash -c 'apt-get update && apt-get install -y ca-certificates curl git xdg-utils dbus-x11'

info "Fetching Google's official CLI install script inside Debian..."
# Upstream content can change. User confirmation above precedes its execution.
proot-distro login debian -- /usr/bin/env PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c 'set -e; tmp="$(mktemp)"; trap '''rm -f "$tmp"''' EXIT; curl -fsSL https://antigravity.google/cli/install.sh -o "$tmp"; bash "$tmp"'

info "Checking CLI command..."
if proot-distro login debian -- /usr/bin/env PATH=/root/.local/bin:/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin /bin/bash -c 'command -v agy >/dev/null 2>&1'; then
  if ! proot-distro login debian -- /usr/bin/env PATH=/root/.local/bin:/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin /bin/bash -c 'agy --version || agy --help'; then
    warn "The CLI exists but the smoke test failed; Android/PRoot runtime incompatibility is possible."
  fi
  log "CLI install step finished. Enter Debian with: proot-distro login debian"
  log "Then start the agent with: agy"
  warn "Install/smoke check does not prove a complete authenticated coding session. Device compatibility remains unverified."
else
  warn "The installer finished but 'agy' was not found on the expected PATH."
  die "CLI installation could not be verified. Inspect the output above and rerun diagnostics." 1
fi

log "Done. Diagnostics: bash install.sh --doctor"
log "Installer log: $LOG_FILE"
