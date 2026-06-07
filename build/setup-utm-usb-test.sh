#!/bin/sh
# UTM/QEMU USB test workflow (shut down VM first):
#   1. UTM Input USB = Disabled; PS/2 = Off (USB-only test).
#   2. QEMU Additional Arguments:
#        -device qemu-xhci,id=xhci -device usb-kbd,bus=xhci.0 -device usb-mouse,bus=xhci.0
#   3. Run this script — syncs sources, queues normal-boot kernel rebuild.
#   4. Boot VM; wait for desktop, auto compile (~5-15 min), auto reboot.
#   5. build/check-utm-usb-boot.sh — expect active=0x3, evt/len moving when you type/move.
# Fresh QEMU-from-ISO installs: use build/build-iso.sh, same xHCI args, BootHDInsAuto; Reboot; inside guest.
set -e
# StartOS always tries native USB first; the rebuild bakes driver changes into Kernel.ZXE.
export AUTO_NORMAL_REBUILD=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
