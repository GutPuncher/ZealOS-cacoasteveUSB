#!/bin/sh
# Copy Browser supplement ISO into the ZealOS UTM bundle and wire the CD drive.
#
# Usage:
#   ./attach-browser-iso-to-utm.sh [path-to-ZealOS.utm]

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
ISO_SRC="$SCRIPT_DIR/ZealOS-Browser-Supplement.iso"

if [ ! -f "$ISO_SRC" ]; then
	echo "ISO not found. Run ./build-browser-supplement.sh first." >&2
	exit 1
fi

UTM_BUNDLE="${1:-$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/ZealOS.utm}"
DATA_DIR="$UTM_BUNDLE/Data"
CONFIG="$UTM_BUNDLE/config.plist"
ISO_NAME="ZealOS-Browser-Supplement.iso"

if [ ! -d "$DATA_DIR" ]; then
	echo "UTM bundle not found: $UTM_BUNDLE" >&2
	exit 1
fi

echo "Copying ISO to $DATA_DIR ..."
cp -f "$ISO_SRC" "$DATA_DIR/$ISO_NAME"

echo "Updating CD drive in config.plist ..."
python3 - <<'PY' "$CONFIG" "$ISO_NAME"
import plistlib, sys, shutil

config_path, iso_name = sys.argv[1:3]
backup = config_path + ".before-browser-iso"

with open(config_path, "rb") as f:
    plist = plistlib.load(f)

shutil.copy2(config_path, backup)

drives = plist.get("Drive", [])
cd = None
for d in drives:
    if d.get("ImageType") == "CD":
        cd = d
        break

if cd is None:
    raise SystemExit("No CD drive entry found in config.plist")

cd["ImageName"] = iso_name
cd["ReadOnly"] = True

with open(config_path, "wb") as f:
    plistlib.dump(plist, f)

print(f"Backed up config to {backup}")
print(f"Set CD ImageName to {iso_name}")
PY

echo
echo "Done. Open UTM → ZealOS → boot the VM."
echo "In ZealOS: DriveRep; Cd(\"D:\");  #include \"Install.ZC\""
