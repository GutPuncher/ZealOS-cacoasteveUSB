#!/bin/sh
# Fix zeal2 UTM VM: ZealOS requires AHCI ports. UTM's default IDE CD does NOT
# appear on AHCI port 1, so installed systems panic looking for drive D: (CD).
#
# This attaches HDD to ahci.0 and CD to ahci.1 via QEMU args.
#
# Usage: ./fix-zeal2-utm-ahci.sh [path-to-zeal2.utm]

set -e

UTM_BUNDLE="${1:-$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/zeal2.utm}"
CONFIG="$UTM_BUNDLE/config.plist"
DATA="$UTM_BUNDLE/Data"

if [ ! -f "$CONFIG" ]; then
	echo "zeal2.utm not found at $UTM_BUNDLE" >&2
	exit 1
fi

DISK="$(ls "$DATA"/*.qcow2 2>/dev/null | head -1)"
ISO="$DATA/ZealOS-Browser-Supplement.iso"

if [ -z "$DISK" ]; then
	echo "No .qcow2 disk in $DATA" >&2
	exit 1
fi

if [ ! -f "$ISO" ]; then
	ISO="$(cd "$(dirname "$0")" && pwd)/ZealOS-Browser-Supplement.iso"
	if [ -f "$ISO" ]; then
		cp -f "$ISO" "$DATA/ZealOS-Browser-Supplement.iso"
		ISO="$DATA/ZealOS-Browser-Supplement.iso"
	fi
fi

if [ ! -f "$ISO" ]; then
	echo "Browser supplement ISO missing. Run ./build-browser-supplement.sh first." >&2
	exit 1
fi

cp -f "$CONFIG" "$CONFIG.before-ahci-fix-$(date +%Y%m%d-%H%M%S)"

python3 <<PY
import plistlib, os

config_path = "$CONFIG"
disk_path = "$DISK"
iso_path = "$ISO"

with open(config_path, "rb") as f:
    plist = plistlib.load(f)

drives = plist.get("Drive", [])
disk_entry = None
cd_entry = None

for d in drives:
    if d.get("ImageType") == "Disk":
        disk_entry = d
    elif d.get("ImageType") == "CD":
        cd_entry = d

if not disk_entry:
    raise SystemExit("No disk drive in config")

if not cd_entry:
    cd_entry = {
        "Identifier": "66D24FCF-60EC-42BE-BC6D-9EADD378A362",
        "ImageType": "CD",
        "ReadOnly": True,
        "InterfaceVersion": 1,
    }
    drives.append(cd_entry)

# UTM: Interface "None" = drive defined but attached only via QEMU args
disk_entry["Interface"] = "None"
disk_entry["ImageName"] = os.path.basename(disk_path)
cd_entry["Interface"] = "None"
cd_entry["ImageName"] = os.path.basename(iso_path)
cd_entry["ReadOnly"] = True

plist["Drive"] = drives

# QEMU 11+ uses ide-hd (ide-drive was removed). Match ZealOS input/display too.
args = [
    "-drive", f"if=none,file={disk_path},format=qcow2,id=zealdisk,media=disk",
    "-drive", f"if=none,file={iso_path},format=raw,id=zealcd,media=cdrom,readonly=on",
    "-device", "ide-hd,drive=zealdisk,bus=ahci.0",
    "-device", "ide-cd,drive=zealcd,bus=ahci.1",
]

display = plist.get("Display", [{}])
if display:
    display[0]["Hardware"] = "virtio-vga"

qemu = plist.setdefault("QEMU", {})
qemu["PS2Controller"] = False
qemu["AdditionalArguments"] = args
inp = plist.setdefault("Input", {})
inp["UsbBusSupport"] = "3.0"
inp["UsbSharing"] = False

with open(config_path, "wb") as f:
    plistlib.dump(plist, f)

print("Updated zeal2 UTM config:")
print(f"  Disk (ahci.0): {disk_path}")
print(f"  CD   (ahci.1): {iso_path}")
print("  Both drives set to Interface=None with AHCI QEMU args")
PY

echo
echo "Done. Quit UTM completely, reopen zeal2, and boot."
echo "Port 0 should be ATA (C:), port 1 ATAPI (D: with browser ISO)."
