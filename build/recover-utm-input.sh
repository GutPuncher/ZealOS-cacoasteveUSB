#!/bin/sh
# Sync USB sources and remove /Home/.usb_boot_ok so the next boot skips UsbBootInit.
# Use when USB-only boot has no input and you need to run BootHDInsAuto.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
export REMOVE_USB_BOOT_OK=1
exec "$SCRIPT_DIR/patch-utm-disk.sh"
