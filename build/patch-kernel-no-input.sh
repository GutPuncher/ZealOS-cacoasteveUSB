#!/bin/sh
# Sync kernel sources and queue an automatic kernel compile on the NEXT boot.
# No keyboard or mouse needed inside the VM — StartOS runs BootKernelOnly before
# the desktop loads, then reboots. Shut down UTM first.
set -e
export AUTO_BOOT_INS=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
