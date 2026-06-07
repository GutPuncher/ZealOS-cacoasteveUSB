#!/bin/sh
# Sync sources, enable UsbBootInit marker, and queue normal-boot kernel auto-rebuild.
set -e
export SET_USB_BOOT_OK=1
export AUTO_NORMAL_REBUILD=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
