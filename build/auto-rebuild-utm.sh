#!/bin/sh
# Sync USB sources AND queue a normal-boot kernel rebuild on the UTM disk.
# Next ZealOS boot: no keyboard needed — /Home/Once.ZC rebuilds after the system server starts.
set -e
export AUTO_NORMAL_REBUILD=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
