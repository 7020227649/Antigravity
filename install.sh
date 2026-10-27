#!/usr/bin/env bash
# Install Google's original Linux ARM64 Antigravity IDE GUI via Debian PRoot + Termux:X11.
set -Eeuo pipefail
IFS=$'\n\t'
PROJECT_NAME="antigravity-termux"
OFFICIAL_DOWNLOAD_PAGE="https://antigravity.google/download"
X11_APK_URL="https://github.com/termux/termux-x11/releases/download/nightly/termux-x11-universal-debug.apk"
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

usage() {
  cat <<'EOF'
Standalone Antigravity IDE GUI for Termux — experimental Linux ARM64 desktop app
Usage: bash install.sh [options]
  --help        Show help and exit without changes
  --yes         Skip installer confirmation (Android APK approval is still required)
  --no-launch   Install app and launcher but do not open GUI at the end
  --doctor      Read-only environment diagnostics
This installs Google's standalone Linux ARM64 Antigravity IDE into Debian
under proot-distro and displays it with Termux:X11. Android/Termux is not an
officially supported Google desktop target.
EOF
}
YES=0
NO_LAUNCH=0
DOCTOR=0
while (($#)); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --yes|-y) YES=1 ;;
    --no-launch) NO_LAUNCH=1 ;;
    --doctor) DOCTOR=1 ;;
    *) usage >&2; printf '[ERROR] Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
plain_error() { printf '[ERROR] %s\n' "$1" >&2; exit "${2:-1}"; }
require_termux() {
  [[ -n "${PREFIX:-}" && "$PREFIX" == */com.termux/files/usr && -x "$PREFIX/bin/pkg" ]] ||
    plain_error "Run this installer in native Termux, not inside Debian or another Linux shell." 2
  local arch
  arch="$(uname -m)"
  [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] ||
    plain_error "This installer targets ARM64 Android. Detected: $arch" 2
  [[ "$(id -u)" != "0" ]] || plain_error "Do not run from a rooted shell; use the regular Termux app user." 2
}
x11_app_installed() {
  if command -v pm >/dev/null 2>&1; then
    pm path com.termux.x11 >/dev/null 2>&1
  elif [[ -x /system/bin/pm ]]; then
    /system/bin/pm path com.termux.x11 >/dev/null 2>&1
  else
    return 1
  fi
}
doctor() {
  printf '== Antigravity GUI / Termux diagnostics ==\n'
  printf 'Android release: %s\n' "$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
  printf 'Android API: %s\n' "$(getprop ro.build.version.sdk 2>/dev/null || echo unknown)"
  printf 'Termux version: %s\n' "${TERMUX_VERSION:-unknown}"
  printf 'Architecture: %s\n' "$(uname -m)"
  printf 'Page size: %s\n' "$(getconf PAGE_SIZE 2>/dev/null || echo unavailable)"
  printf 'Free storage: '
  df -h "$HOME" 2>/dev/null | tail -n 1 || echo unavailable
  printf 'Termux:X11 Android app: '
  if x11_app_installed; then echo installed; else echo missing; fi
  printf 'Termux:X11 command: '
  if command -v termux-x11 >/dev/null 2>&1; then echo installed; else echo missing; fi
  printf 'proot-distro command: '
  if command -v proot-distro >/dev/null 2>&1; then echo installed; else echo missing; fi
  echo "Diagnostics are local only; no tokens or project files are collected."
}
require_termux
if ((DOCTOR)); then doctor; exit 0; fi

STATE_DIR="$HOME/.local/share/$PROJECT_NAME"
LOG_DIR="$HOME/.cache/$PROJECT_NAME/logs"
mkdir -p "$LOG_DIR" "$STATE_DIR" || plain_error "Cannot create writable state/log directories." 1
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
: > "$LOG_FILE" || plain_error "Cannot create log file: $LOG_FILE" 1
log() { printf '%s\n' "$*" | tee -a "$LOG_FILE"; }
info() { printf '[INFO] %s\n' "$*" | tee -a "$LOG_FILE"; }
warn() { printf '[WARN] %s\n' "$*" | tee -a "$LOG_FILE" >&2; }
die() { local rc="${2:-1}"; printf '[ERROR] %s\n' "$1" | tee -a "$LOG_FILE" >&2; exit "$rc"; }
on_err() {
  local rc=$?
  trap - ERR
  warn "Stopped with exit code $rc. Log: $LOG_FILE"
  exit "$rc"
}
trap on_err ERR

LOCK_DIR="$STATE_DIR/install.lock"
TMP_DIR=""
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  owner=""
  if [[ -r "$LOCK_DIR/pid" ]]; then IFS= read -r owner < "$LOCK_DIR/pid" || true; fi
  if [[ "$owner" =~ ^[0-9]+$ ]] && kill -0 "$owner" 2>/dev/null; then
    die "Another installer appears to be running (PID $owner)."
  fi
  warn "Recovering an installer lock whose process is no longer running."
  rm -f "$LOCK_DIR/pid"
  rmdir "$LOCK_DIR" 2>/dev/null || die "Cannot recover stale installer lock."
  mkdir "$LOCK_DIR" || die "Cannot acquire installer lock."
fi
printf '%s\n' "$$" > "$LOCK_DIR/pid"
cleanup() {
  [[ -z "$TMP_DIR" ]] || rm -rf "$TMP_DIR"
  if [[ -r "$LOCK_DIR/pid" ]] && [[ "$(cat "$LOCK_DIR/pid" 2>/dev/null || true)" == "$$" ]]; then
    rm -f "$LOCK_DIR/pid"
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}
trap cleanup EXIT
TMP_DIR="$(mktemp -d "$LOG_DIR/work.XXXXXX")"

cat <<'EOF'
This installs the standalone Antigravity IDE GUI, not the newer Antigravity App or the terminal-only CLI.
It installs Termux:X11, a Debian ARM64 userspace, GUI libraries and the official
Antigravity IDE Linux ARM64 archive.

Important:
- Android/Termux is not a Google-supported desktop target.
- Several GB of free storage are needed; 6 GB or more is recommended.
- Adreno acceleration is best-effort, not guaranteed.
- The default launch preserves the app's normal sandbox. If Chromium's sandbox
  fails inside PRoot, a separate explicit --no-sandbox retry is available; that
  reduces isolation and should only be used with trusted projects.
EOF
if (( ! YES )); then
  read -r -p "Continue with the GUI installation? [y/N] " answer
  case "$answer" in y|Y|yes|YES) ;; *) log "Cancelled."; exit 0 ;; esac
fi

avail_kb="$(df -Pk "$HOME" 2>/dev/null | tail -n 1 | awk '{print $4}')"
if [[ "$avail_kb" =~ ^[0-9]+$ ]]; then
  if (( avail_kb < 3500000 )); then
    die "Less than about 3.5 GB of free storage is available. Free space before installing Debian and Antigravity." 1
  elif (( avail_kb < 6000000 )); then
    warn "Less than 6 GB of free storage is available; installation or updates may run out of space."
  fi
fi
mem_mb="$(awk '/^MemTotal:/ {print int($2/1024)}' /proc/meminfo 2>/dev/null || echo 0)"
if [[ "$mem_mb" =~ ^[0-9]+$ ]] && (( mem_mb > 0 && mem_mb < 6000 )); then
  warn "Device reports about ${mem_mb} MiB RAM. The desktop app may be slow or be killed by Android."
fi

info "Updating Termux package metadata..."
pkg update 2>&1 | tee -a "$LOG_FILE"
info "Installing Termux:X11 and PRoot dependencies..."
pkg install -y x11-repo proot-distro curl tar procps termux-tools xorg-xdpyinfo python 2>&1 | tee -a "$LOG_FILE"
pkg install -y termux-x11-nightly 2>&1 | tee -a "$LOG_FILE"

if ! x11_app_installed; then
  APK_PATH="$TMP_DIR/termux-x11-universal-debug.apk"
  info "Downloading the official Termux:X11 APK from its nightly release."
  curl --fail --location --silent --show-error --retry 2 --connect-timeout 15 \
    --proto '=https' --proto-redir '=https' "$X11_APK_URL" -o "$APK_PATH"
  [[ -s "$APK_PATH" ]] || die "The Termux:X11 APK download was empty."
  command -v termux-open >/dev/null 2>&1 || die "termux-open was not found. Install termux-tools, then retry."
  info "Opening the Android package installer. Android will ask you to approve the APK installation."
  termux-open "$APK_PATH" || die "Could not open the APK. Install it manually from: $X11_APK_URL"
  [[ -t 0 ]] || die "Install Termux:X11 from the Android prompt, then rerun bash install.sh."
  read -r -p "After Android confirms Termux:X11 is installed, return here and press Enter. "
  x11_app_installed || die "Termux:X11 is still not detected. Install the APK, allow Termux to install apps if asked, then rerun."
fi

info "Resolving the current official Linux ARM64 standalone Antigravity IDE download."
curl --fail --location --silent --show-error --compressed --retry 2 --connect-timeout 15 \
  --proto '=https' --proto-redir '=https' "$OFFICIAL_DOWNLOAD_PAGE" -o "$TMP_DIR/download.html"
# shellcheck source=lib/app-metadata.sh
source "$SCRIPT_DIR/lib/app-metadata.sh"
APP_URL="$(extract_antigravity_ide_url "$TMP_DIR/download.html")"
if [[ -z "$APP_URL" ]]; then
  info "The download page does not expose the archive URL directly; resolving its official JavaScript metadata."
  BUNDLE_URL="$(python3 "$SCRIPT_DIR/lib/resolve-download.py" bundle-url "$TMP_DIR/download.html" "$OFFICIAL_DOWNLOAD_PAGE")"
  [[ -n "$BUNDLE_URL" ]] || die "Could not find the official download page's JavaScript bundle. Refusing to guess an artifact URL."
  curl --fail --location --silent --show-error --compressed --retry 2 --connect-timeout 15 \
    --proto '=https' --proto-redir '=https' "$BUNDLE_URL" -o "$TMP_DIR/download.js"
  APP_URL="$(extract_antigravity_ide_url "$TMP_DIR/download.js")"
fi
[[ -n "$APP_URL" ]] || die "Could not identify the standalone Antigravity IDE Linux ARM64 link in official Google metadata. Refusing to guess an artifact URL."
APP_VERSION="$(extract_antigravity_ide_version "$APP_URL")"
[[ -n "$APP_VERSION" ]] || die "Could not read the standalone IDE version from the official URL."
info "Official Antigravity IDE version detected: $APP_VERSION"
log "Official download URL: $APP_URL"

if ! proot-distro login debian -- /bin/true >/dev/null 2>&1; then
  info "Debian is not available; installing it with proot-distro."
  proot-distro install debian 2>&1 | tee -a "$LOG_FILE"
else
  info "Reusing the existing Debian container without resetting it."
fi

ARCH="$(proot-distro login debian -- /usr/bin/dpkg --print-architecture 2>/dev/null | tail -n 1 || true)"
[[ "$ARCH" == "arm64" ]] || die "Debian architecture is '$ARCH', expected arm64. Existing containers were not reset." 1
# shellcheck disable=SC2016
DEBIAN_RELEASE_CMD='. /etc/os-release; printf "%s" "${VERSION_CODENAME:-unknown}"'
DEBIAN_CODENAME="$(proot-distro login debian -- /bin/bash -c "$DEBIAN_RELEASE_CMD")"
case "$DEBIAN_CODENAME" in
  trixie|forky|sid|testing|unstable)
    AUDIO_ATK_PKGS=(libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 libatspi2.0-0t64 libgtk-3-0t64)
    ;;
  *)
    AUDIO_ATK_PKGS=(libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libgtk-3-0)
    ;;
esac
BASE_DEBIAN_PKGS=(
  ca-certificates curl tar gzip file binutils dbus-x11 xdg-utils fonts-liberation passwd libstdc++6 libgcc-s1
  libcairo2 libcups2 libdbus-1-3 libdrm2 libexpat1 libgbm1 libglib2.0-0
  libnspr4 libnss3 libpango-1.0-0 libsecret-1-0 libx11-6 libx11-xcb1 libxcb1
  libxcomposite1 libxdamage1 libxext6 libxfixes3 libxkbcommon0 libxkbfile1
  libxrandr2 libxrender1 libxss1 libxtst6 libxshmfence1
)
info "Installing GUI libraries inside Debian ($DEBIAN_CODENAME)."
proot-distro login debian -- /usr/bin/env DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get update 2>&1 | tee -a "$LOG_FILE"
proot-distro login debian -- /usr/bin/env DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y "${BASE_DEBIAN_PKGS[@]}" "${AUDIO_ATK_PKGS[@]}" 2>&1 | tee -a "$LOG_FILE"

info "Creating an unprivileged GUI user inside Debian."
proot-distro login debian -- /bin/bash -c 'id antigravity >/dev/null 2>&1 || useradd --create-home --shell /bin/bash antigravity; mkdir -p /mnt/termux-home /home/antigravity/.local/share; chown antigravity:antigravity /home/antigravity/.local /home/antigravity/.local/share'

info "Downloading and validating the official Antigravity IDE archive inside Debian."
# shellcheck disable=SC2016
proot-distro login debian -- /usr/bin/env ANTIGRAVITY_URL="$APP_URL" ANTIGRAVITY_VERSION="$APP_VERSION" /bin/bash -c '
set -Eeuo pipefail
APP_DIR=/home/antigravity/.local/share/antigravity-ide
STAGE="$(mktemp -d /home/antigravity/.local/share/antigravity-ide.stage.XXXXXX)"
ARCHIVE="$(mktemp /tmp/antigravity-ide.XXXXXX.tar.gz)"
MANIFEST="$(mktemp /tmp/antigravity-ide-manifest.XXXXXX)"
OLD=""
cleanup_inner() {
  [[ -z "$STAGE" ]] || rm -rf "$STAGE"
  rm -f "$ARCHIVE" "$MANIFEST"
}
trap cleanup_inner EXIT
curl --fail --location --silent --show-error --retry 2 --connect-timeout 20 \
  --proto "=https" --proto-redir "=https" "$ANTIGRAVITY_URL" -o "$ARCHIVE"
[[ -s "$ARCHIVE" ]]
gzip -t "$ARCHIVE"
tar -tzf "$ARCHIVE" > "$MANIFEST"
if grep -Eq "(^/|(^|/)\.\.(/|$))" "$MANIFEST"; then
  echo "Unsafe absolute or parent-traversal path in archive." >&2
  exit 20
fi
grep -Eq "(^|/)antigravity-ide$" "$MANIFEST" || {
  echo "Official standalone IDE archive did not contain the expected antigravity-ide executable." >&2
  exit 21
}
tar -xzf "$ARCHIVE" -C "$STAGE" --no-same-owner
BIN="$(find "$STAGE" -type f -name antigravity-ide -perm -u+x -print -quit)"
[[ -n "$BIN" ]] || { echo "antigravity-ide executable was not found after extraction." >&2; exit 22; }
readelf -h "$BIN" | grep -q "Machine:.*AArch64" || {
  echo "Downloaded Antigravity IDE executable is not Linux AArch64." >&2
  exit 23
}
chmod -R a+rX "$STAGE"
chown -R antigravity:antigravity "$STAGE"
RELATIVE_BIN="$(printf "%s\n" "$BIN" | sed "s#^$STAGE/##")"
printf "%s\n" "$RELATIVE_BIN" > "$STAGE/.bundle-path"
printf "%s\n" "$ANTIGRAVITY_VERSION" > "$STAGE/.version"
printf "managed-by=antigravity-termux\n" > "$STAGE/.antigravity-termux-managed"
if [[ -e "$APP_DIR" ]]; then
  [[ -f "$APP_DIR/.antigravity-termux-managed" ]] || {
    echo "$APP_DIR exists but is not managed by this installer; refusing to overwrite it." >&2
    exit 24
  }
  OLD="/home/antigravity/.local/share/antigravity-ide.previous.$$"
  mv "$APP_DIR" "$OLD"
fi
if ! mv "$STAGE" "$APP_DIR"; then
  [[ -z "$OLD" ]] || mv "$OLD" "$APP_DIR"
  echo "Could not activate the new GUI bundle." >&2
  exit 25
fi
STAGE=""
[[ -z "$OLD" ]] || rm -rf "$OLD"
printf "Installed Antigravity IDE %s at %s\n" "$ANTIGRAVITY_VERSION" "$APP_DIR"
' 2>&1 | tee -a "$LOG_FILE"

info "Setting up Android browser handoff for Google sign-in."
proot-distro login --bind "$SCRIPT_DIR/lib/xdg-open-termux.sh:/tmp/antigravity-xdg-open-termux" debian -- /bin/bash -c '
set -e
if [[ -e /usr/local/bin/xdg-open && ! -f /usr/local/share/antigravity-termux/xdg-open-managed ]]; then
  echo "An existing /usr/local/bin/xdg-open was found; preserving it."
  echo "External browser sign-in handoff may need manual configuration."
else
  install -m 0755 /tmp/antigravity-xdg-open-termux /usr/local/bin/xdg-open
  mkdir -p /usr/local/share/antigravity-termux
  touch /usr/local/share/antigravity-termux/xdg-open-managed
fi
'

info "Installing Termux launch helpers."
install -d "$STATE_DIR"
install -m 0755 "$SCRIPT_DIR/launch-gui.sh" "$STATE_DIR/launch-gui.sh"
install -m 0755 "$SCRIPT_DIR/stop-gui.sh" "$STATE_DIR/stop-gui.sh"
cat > "$PREFIX/bin/antigravity" <<EOF
#!/usr/bin/env bash
exec "$STATE_DIR/launch-gui.sh" "\$@"
EOF
cat > "$PREFIX/bin/antigravity-stop" <<EOF
#!/usr/bin/env bash
exec "$STATE_DIR/stop-gui.sh" "\$@"
EOF
chmod 0755 "$PREFIX/bin/antigravity" "$PREFIX/bin/antigravity-stop"

log ""
log "GUI installation completed: Antigravity IDE $APP_VERSION."
log "Launch with: antigravity"
log "Stop the app with: antigravity-stop"
log "Try antigravity --software-rendering if the window is blank or GPU initialization fails."
log "Only if Chromium's sandbox fails, and only for trusted projects, try: antigravity --no-sandbox"
log "Install log: $LOG_FILE"

if (( ! NO_LAUNCH )); then
  info "Starting the original Antigravity GUI."
  "$PREFIX/bin/antigravity"
fi
