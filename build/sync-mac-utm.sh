#!/bin/sh
# ZealOS uses the RedSea filesystem — it cannot be mounted natively on macOS.
#
# To get browser (or any src/) changes into your UTM ZealOS VM on a Mac:
#
#   1. Supplemental CD (recommended, VM can stay as-is):
#        ./build-browser-supplement.sh
#        ./attach-browser-iso-to-utm.sh
#      Then in ZealOS: DriveRep; Cd("D:"); #include "Install.ZC"
#
#   2. Full distro rebuild (Linux or WSL with qemu-nbd):
#        ./build-iso.sh
#      Attach the new ZealOS-BSD2-UEFI-*.iso in UTM and reinstall, or
#      use ./sync.sh vm with ZEALDISK set to your .qcow2 on Linux.
#
#   3. Edit inside the running VM:
#        Copy/paste source into ZealOS editor, or use the supplemental ISO.

echo "RedSea disks are not mountable on macOS."
echo "Use ./build-browser-supplement.sh and ./attach-browser-iso-to-utm.sh instead."
exit 1
