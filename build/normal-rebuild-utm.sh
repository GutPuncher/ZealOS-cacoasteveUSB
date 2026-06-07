#!/bin/sh
# Sync sources and queue a normal-boot kernel rebuild (needs mouse to reach desktop).
# UsbBootOk is written by BootKernelFull after compile — not here.
set -e
export AUTO_NORMAL_REBUILD=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
