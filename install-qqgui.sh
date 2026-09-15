#!/bin/bash
# DEV quick-deploy for harbour-qqgui (glass variant; mirrors install.sh).
# Shadow-builds so the source tree stays clean, then stages via
# `make install INSTALL_ROOT` and copies the staging tree to /.
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
BLD="$(mktemp -d /tmp/qqgui-build-XXXXXX)"
trap 'rm -rf "$BLD"' EXIT
mkdir -p "$BLD/build" "$BLD/root"

(cd "$BLD/build" && qmake "$ROOT/harbour-qqgui.pro" CONFIG+=release && make -j4 >/dev/null)
(cd "$BLD/build" && make install INSTALL_ROOT="$BLD/root" >/dev/null)

sudo -n cp -r "$BLD/root/." /

echo "installed (dev mode). launch: /usr/bin/harbour-qqgui"
