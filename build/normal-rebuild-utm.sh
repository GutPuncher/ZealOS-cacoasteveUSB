#!/bin/sh
# Sync sources and queue a normal-boot kernel rebuild (needs mouse to reach desktop).
# StartOS always tries native USB first; the rebuild bakes driver changes into Kernel.ZXE.
set -e
export AUTO_NORMAL_REBUILD=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
