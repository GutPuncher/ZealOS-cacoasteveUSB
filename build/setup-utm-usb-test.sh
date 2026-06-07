#!/bin/sh
# Sync sources, enable UsbBootInit marker, and queue normal-boot kernel auto-rebuild.
set -e
# UsbBootOk is written by BootKernelFull after a successful compile — not here.
export AUTO_NORMAL_REBUILD=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
