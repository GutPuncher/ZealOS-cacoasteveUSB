#!/bin/sh
# Restore ZealOS UTM qcow2 and sync selected source files (USB work only).
set -e

UTM_BUNDLE="${UTM_BUNDLE:-$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/ZealOS.utm}"
UTM_DIR="${UTM_DIR:-$UTM_BUNDLE/Data}"
IMAGE_NAME=$(/usr/libexec/PlistBuddy -c "Print :Drive:0:ImageName" "$UTM_BUNDLE/config.plist" 2>/dev/null || true)
[ -n "$IMAGE_NAME" ] || IMAGE_NAME="9B0F9544-DD68-41D3-ACC3-96A486D80F73-2.qcow2"
DISK="${DISK:-$UTM_DIR/$IMAGE_NAME}"
RESTORE_FROM="${RESTORE_FROM:-}"
SRC_DIR="$(cd "$(dirname "$0")/../src" && pwd -P)"
STAMP=$(date +%Y%m%d-%H%M%S)

PART1_OFF=32256
PART2_OFF=542900736

export MTOOLS_SKIP_CHECK=1

SYNC_FILES="
Kernel/KMain.ZC
Kernel/Kernel.PRJ
Kernel/KernelA.HH
Kernel/KernelC.HH
Kernel/SerialDev/MakeSerialDev.ZC
Kernel/SerialDev/Mouse.ZC
Kernel/SerialDev/USB.ZC
Kernel/SerialDev/USB.HH
Kernel/SerialDev/USBXHCI.ZC
Kernel/SerialDev/USBControl.ZC
Kernel/SerialDev/USBKbd.ZC
Kernel/SerialDev/USBMouse.ZC
Doc/Requirements.DD
Doc/Strategy.DD
Doc/WhyNotMore.DD
Doc/USBBoot.DD
Demo/USBInput.ZC
"

[ -f "$DISK" ] || { echo "Missing VM disk: $DISK"; exit 1; }
if [ -n "$RESTORE_FROM" ] && [ ! -f "$RESTORE_FROM" ]; then
	echo "Missing restore backup: $RESTORE_FROM"
	exit 1
fi

if lsof "$DISK" >/dev/null 2>&1; then
	echo "ERROR: $DISK is in use. Shut down the ZealOS UTM VM first."
	lsof "$DISK" 2>/dev/null || true
	exit 1
fi

TMPDIR=$(mktemp -d)
RAW="$TMPDIR/disk.raw"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "Backing up current disk -> ${DISK}.before-sync-${STAMP}"
cp -p "$DISK" "${DISK}.before-sync-${STAMP}"

if [ -n "$RESTORE_FROM" ]; then
	echo "Restoring from $RESTORE_FROM"
	cp -p "$RESTORE_FROM" "$DISK"
fi

echo "Converting qcow2 to raw..."
qemu-img convert -f qcow2 -O raw "$DISK" "$RAW"

fat_path() {
	# Map repo path to FAT LFN path used on ZealOS volumes.
	echo "$1" | sed 's|^|::/|'
}

sync_partition() {
	off=$1
	label=$2
	echo "Patching partition $label..."
	mattrib -i "$RAW@@${off}" -r -/ ::/ >/dev/null 2>&1 || true
	for rel in $SYNC_FILES; do
		local="$SRC_DIR/$rel"
		[ -f "$local" ] || { echo "Missing local file: $local"; exit 1; }
		dest=$(fat_path "$rel")
		echo "  $rel"
		mcopy -o -i "$RAW@@${off}" "$local" "$dest"
	done
}

sync_partition "$PART1_OFF" "1"
sync_partition "$PART2_OFF" "2"

verify_one() {
	rel=$1
	local="$SRC_DIR/$rel"
	dest=$(fat_path "$rel")
	local_sum=$(shasum -a 256 "$local" | awk '{print $1}')
	p1="$TMPDIR/p1"
	p2="$TMPDIR/p2"
	mcopy -i "$RAW@@${PART1_OFF}" "$dest" "$p1"
	mcopy -i "$RAW@@${PART2_OFF}" "$dest" "$p2"
	p1_sum=$(shasum -a 256 "$p1" | awk '{print $1}')
	p2_sum=$(shasum -a 256 "$p2" | awk '{print $1}')
	if [ "$local_sum" = "$p1_sum" ] && [ "$local_sum" = "$p2_sum" ]; then
		echo "  OK $rel"
	else
		echo "  MISMATCH $rel"
		echo "    local=$local_sum part1=$p1_sum part2=$p2_sum"
		exit 1
	fi
}

echo "Verifying checksums:"
verify_one "Kernel/KernelA.HH"
verify_one "Kernel/KMain.ZC"
verify_one "Kernel/SerialDev/USBXHCI.ZC"
verify_one "System/Math/Math.ZC"

echo "Writing raw back to qcow2..."
qemu-img convert -f raw -O qcow2 "$RAW" "$DISK.new"
mv "$DISK.new" "$DISK"

echo "Fresh backup -> ${DISK}.bak-after-sync-${STAMP}"
cp -p "$DISK" "${DISK}.bak-after-sync-${STAMP}"

echo
echo "Done. Boot ZealOS, run BootHDIns, then MountAHCIAuto (C / T)."
