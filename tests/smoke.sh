#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

bash -n "$ROOT/install.sh"
bash -n "$ROOT/launch-gui.sh"
bash -n "$ROOT/stop-gui.sh"
bash -n "$ROOT/lib/app-metadata.sh"
bash -n "$ROOT/lib/xdg-open-termux.sh"
python3 -m py_compile "$ROOT/lib/resolve-download.py"

help_output="$(env -u PREFIX bash "$ROOT/install.sh" --help)"
grep -q -- '--no-launch' <<<"$help_output"
grep -q -- 'Antigravity IDE' <<<"$help_output"
if env -u PREFIX bash "$ROOT/install.sh" --unknown >/dev/null 2>&1; then
  echo "Unknown options should fail." >&2
  exit 1
fi
if env -u PREFIX bash "$ROOT/install.sh" --doctor >/dev/null 2>&1; then
  echo "Doctor should reject a non-Termux shell." >&2
  exit 1
fi
expected_login='proot-distro login --user antigravity --shared-tmp --bind "$HOME:/mnt/termux-home" debian --'
expected_executable='/home/antigravity/.local/share/antigravity-ide/$APP_REL'
grep -Fq "$expected_login" "$ROOT/launch-gui.sh"
grep -Fq "$expected_executable" "$ROOT/launch-gui.sh"
grep -Fq 'lib/resolve-download.py' "$ROOT/install.sh"

printf '%s\n' \
  '<a href="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-arm/Antigravity%20IDE.tar.gz">Standalone IDE Linux ARM64</a>' \
  '<a href="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz">x64 IDE decoy</a>' \
  '<a href="https://storage.googleapis.com/antigravity-public/antigravity-hub/2.26.0-6546645232517120/linux-arm/Antigravity.tar.gz">Antigravity App decoy</a>' > "$TMP/download.html"
# shellcheck source=lib/app-metadata.sh
source "$ROOT/lib/app-metadata.sh"
url="$(extract_antigravity_ide_url "$TMP/download.html")"
[[ "$url" == "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-arm/Antigravity%20IDE.tar.gz" ]]
[[ "$(extract_antigravity_ide_version "$url")" == "2.5.5" ]]

printf '%s\n' '<html><script src="/assets/chunks/main-download.js"></script><script src="/chunks/shared.js"></script></html>' > "$TMP/page.html"
bundle_url="$(python3 "$ROOT/lib/resolve-download.py" bundle-url "$TMP/page.html" "https://antigravity.google/download")"
[[ "$bundle_url" == "https://antigravity.google/assets/chunks/main-download.js" ]]

printf '%s\n' 'const archive="https:\/\/edgedl.me.gvt1.com\/edgedl\/release2\/j0qc3\/antigravity\/stable\/2.5.5-4923483625488384\/linux-arm\/Antigravity%20IDE.tar.gz";' > "$TMP/download.js"
js_url="$(extract_antigravity_ide_url "$TMP/download.js")"
[[ "$js_url" == "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-arm/Antigravity%20IDE.tar.gz" ]]

printf '%s\n' '<html>no standalone IDE ARM64 link</html>' > "$TMP/no-link.html"
[[ -z "$(extract_antigravity_ide_url "$TMP/no-link.html")" ]]
[[ -z "$(python3 "$ROOT/lib/resolve-download.py" bundle-url "$TMP/no-link.html" "https://antigravity.google/download")" ]]

mkdir -p "$TMP/fake-prefix/bin"
cat > "$TMP/fake-prefix/bin/termux-open-url" <<'OPENURL'
#!/usr/bin/env bash
printf 'OPEN:%s\n' "$1"
OPENURL
chmod +x "$TMP/fake-prefix/bin/termux-open-url"
bridge_output="$(TERMUX_PREFIX="$TMP/fake-prefix" bash "$ROOT/lib/xdg-open-termux.sh" "https://accounts.google.com/")"
[[ "$bridge_output" == "OPEN:https://accounts.google.com/" ]]

echo "Standalone IDE GUI installer static/metadata smoke tests passed."
