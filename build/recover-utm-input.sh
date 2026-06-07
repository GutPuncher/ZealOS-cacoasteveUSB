#!/bin/sh
# Sync USB sources and queue a normal-boot kernel rebuild.
# Use with PS/2 enabled if USB-only boot has no input.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
export AUTO_NORMAL_REBUILD=1
exec "$SCRIPT_DIR/patch-utm-disk.sh"
