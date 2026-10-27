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

RED=''
GREEN=''
YELLOW=''
BLUE=''
RESET=''
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

Usage:
  bash install.sh [options]

Options:
  --help        Show this help and exit without making changes
  --yes         Skip the confirmation prompt (still no destructive resets)
  --cli-only    Install/test the official CLI path (default)
  --gui         Reserved for future optional Termux:X11 GUI experiment
  --doctor      Run platform diagnostics only
EOF
}
YES=0
DOCTOR=0
GUI=0
CLI_ONLY=1
while (($#)); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --yes|-y) YES=1 ;;
    --doctor) DOCTOR=1 ;;
    --gui) GUI=1; CLI_ONLY=0 ;;
    --cli-only) CLI_ONLY=1; GUI=0 ;;
    *) usage; die "Unknown option: $1" 2 ;;
  esac
  shift
done

on_err() {
  local rc=$?
  warn "Installation stopped (exit $rc). See the log: $LOG_FILE"
  exit "$rc"
}
trap on_err ERR

check_host() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]] || die "Run this script inside the Termux app, not inside Debian or a desktop shell." 2
  [[ "$(uname -m)" == "aarch64" || "$(uname -m)" == "arm64" ]] || die "This initial release targets ARM64 Termux. Detected: $(uname -m)" 2
  have pkg || die "Termux package manager 'pkg' was not found." 2
  have proot-distro || true
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
  if have proot-distro; then proot-distro --version 2>&1 | head -n 1 || echo installed; else echo missing; fi
  printf 'Termux:X11 command: '
  have termux-x11 && echo installed || echo not-installed
  printf 'Debian state: '
  if have proot-distro; then proot-distro list 2>/dev/null | grep -i debian || echo "not detected"; else echo "proot-distro missing"; fi
  echo
  echo "No environment variables, tokens, or project source files are collected."
}
if ((DOCTOR)); then
  check_host
  doctor
  exit 0
fi

check_host

if ((GUI)); then
  warn "GUI mode is not implemented yet. Continuing is intentionally blocked to avoid implying desktop support."
  die "Use --cli-only. Termux:X11 desktop support will be added after the CLI path is tested." 2
fi

cat <<'EOF'
This installer will:
  1. Update Termux package metadata and install proot-distro/curl.
  2. Install Debian only if proot-distro does not already list it.
  3. Install basic Linux runtime tools inside Debian.
  4. Run Google's official Antigravity CLI installer inside Debian.
  5. Attempt a non-interactive smoke check where supported.

Compatibility is experimental. Google does not officially list Android/Termux/PRoot as a supported platform.
The installer will not reset or delete an existing Debian distro or enable --no-sandbox.
EOF
if (( ! YES )); then
  read -r -p "Proceed with the CLI-only setup? [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" || "$answer" == "YES" ]] || { log "Cancelled by user."; exit 0; }
fi

info "Log file: $LOG_FILE"
info "Checking network..."
have curl || { info "Installing curl..."; pkg install -y curl; }
curl -fsSI --connect-timeout 10 https://antigravity.google/cli/install.sh >/dev/null || die "Cannot reach the official Antigravity CLI installer over HTTPS. Check network/time/TLS and retry." 1

info "Installing/updating Termux packages needed by the bootstrap..."
pkg update
pkg install -y proot-distro curl

if ! proot-distro list 2>/dev/null | grep -Eiq 'debian'; then
  info "Debian not detected by proot-distro; installing fresh Debian."
  proot-distro install debian
else
  info "Debian appears to be installed; reusing it without reset."
fi

info "Checking Debian ARM64 architecture..."
ARCH="$(proot-distro login debian -- /usr/bin/dpkg --print-architecture 2>/dev/null | tail -n 1 || true)"
[[ "$ARCH" == "arm64" ]] || die "Debian architecture check failed (reported: ${ARCH:-empty}; expected arm64). No distro reset was attempted." 1

info "Installing Debian runtime packages..."
proot-distro login debian -- /usr/bin/env DEBIAN_FRONTEND=noninteractive /bin/bash -c 'apt-get update && apt-get install -y ca-certificates curl git xdg-utils dbus-x11' 

info "Running the official Google Antigravity CLI installer inside Debian."
# Google documents this URL for Linux. Upstream script content and behavior may change;
# show the source URL and require explicit confirmation above before running it.
proot-distro login debian -- /bin/bash -lc 'set -e; tmp="$(mktemp)"; trap '''rm -f "$tmp"''' EXIT; curl -fsSL https://antigravity.google/cli/install.sh -o "$tmp"; bash "$tmp"'

info "Checking whether agy is installed..."
if proot-distro login debian -- /usr/bin/env PATH=/root/.local/bin:/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin /bin/bash -c 'command -v agy >/dev/null 2>&1'; then
  proot-distro login debian -- /usr/bin/env PATH=/root/.local/bin:/root/.cargo/bin:/usr/local/bin:/usr/bin:/bin /bin/bash -c 'agy --version || agy --help' || warn "The CLI exists but its smoke test failed. This may indicate upstream Android/PRoot incompatibility."
  log ""
  log "Setup command finished. Next, start Debian with:"
  log "  proot-distro login debian"
  log "Then run:"
  log "  agy"
  log ""
  warn "This verifies installation/smoke output only, not a complete authenticated coding session. Authentication and kernel/runtime compatibility remain device-dependent."
else
  warn "The installer finished but 'agy' was not found in a login shell."
  warn "Inspect the Debian-side install output and retry with: proot-distro login debian"
  die "CLI installation could not be verified." 1
fi

log "Done. Diagnostics: bash install.sh --doctor"
log "Installer log: $LOG_FILE"
