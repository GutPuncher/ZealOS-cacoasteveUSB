#!/bin/sh
# Fix ZealOS UTM input (shut down VM first).
# Use UTM's USB 3.0 UI path only: PS/2 off, no QEMU USB Additional Arguments.
set -e

UTM_BUNDLE="${UTM_BUNDLE:-$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/ZealOS.utm}"
CONFIG="$UTM_BUNDLE/config.plist"

if [ ! -f "$CONFIG" ]; then
	echo "ERROR: UTM bundle not found: $UTM_BUNDLE" >&2
	exit 1
fi

python3 - "$CONFIG" <<'PY'
import plistlib, shutil, sys

config_path = sys.argv[1]
backup = config_path + ".before-recover-input"
shutil.copy2(config_path, backup)

with open(config_path, "rb") as f:
    plist = plistlib.load(f)

inp = plist.setdefault("Input", {})
old_usb = inp.get("UsbBusSupport", "?")
inp["UsbBusSupport"] = "3.0"
inp["UsbSharing"] = False

qemu = plist.setdefault("QEMU", {})
qemu["PS2Controller"] = False
qemu["AdditionalArguments"] = []

with open(config_path, "wb") as f:
    plistlib.dump(plist, f)

print(f"Updated {config_path}")
print(f"Backup: {backup}")
print(f"  Was Input USB: {old_usb} -> 3.0")
print("  PS/2: Off")
print("  Additional Arguments: (cleared)")
PY

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
if [ "${SYNC_SOURCES:-1}" = 1 ]; then
	AUTO_NORMAL_REBUILD="${AUTO_NORMAL_REBUILD:-0}" "$SCRIPT_DIR/patch-utm-disk.sh"
fi

echo ""
echo "Cold-boot the VM. Expect: USB boot: active=0x3"
echo "Check: build/check-utm-usb-boot.sh"
