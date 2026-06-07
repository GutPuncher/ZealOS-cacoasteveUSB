#!/bin/sh
# Clear BootInsPending so the VM boots normally (skip early BootKernelOnly).
# Use when stuck in the ZealOS Debugger during "Rebuilding kernel..." at boot.
set -e
export REMOVE_BOOT_INS_PENDING=1
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
exec "$SCRIPT_DIR/patch-utm-disk.sh"
