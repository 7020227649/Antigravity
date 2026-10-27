#!/usr/bin/env bash
# Forward external HTTP(S) links from Linux apps to Android's default browser.
# TERMUX_PREFIX is passed in by the GUI launcher.
set -eo pipefail
target="$1"
case "$target" in
  http://*|https://*)
    if [ -n "$TERMUX_PREFIX" ] && [ -x "$TERMUX_PREFIX/bin/termux-open-url" ]; then
      exec "$TERMUX_PREFIX/bin/termux-open-url" "$target"
    fi
    ;;
esac
exec /usr/bin/xdg-open "$@"
