#!/bin/sh
# Build a small ISO9660 CD with the ZealOS Text Browser module.
# Works on macOS (hdiutil or xorriso) and Linux.
#
# Usage:
#   ./build-browser-supplement.sh
#
# In ZealOS (UTM): mount this ISO on the CD drive, then:
#   DriveRep;
#   Cd("D:");   // use your CD drive letter
#   #include "Install.ZC"

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
BROWSER_SRC="$REPO_ROOT/src/Home/Net/Programs/Browser"
STAGING="$(mktemp -d)"
OUT_ISO="$SCRIPT_DIR/ZealOS-Browser-Supplement.iso"

cleanup() {
	rm -rf "$STAGING"
}
trap cleanup EXIT

if [ ! -d "$BROWSER_SRC" ]; then
	echo "ERROR: Browser source not found at $BROWSER_SRC" >&2
	exit 1
fi

echo "Staging browser files..."
mkdir -p "$STAGING/Home/Net/Programs"
cp -R "$BROWSER_SRC" "$STAGING/Home/Net/Programs/"

cat > "$STAGING/Install.ZC" <<'EOF'
/* Install ZealOS Text Browser from supplemental CD.
   Usage (from writable C: or ~):
     BrowserInstallFromCD("T:");   // your CD letter from DriveRep
*/

public U0 BrowserInstallFromCD(U8 *cd_let="T:")
{
	U8 *src, *dst;
	I64 n;

	DirMake("~/Net/Programs");
	src = MStrPrint("%s/Home/Net/Programs/Browser", cd_let);
	dst = MStrPrint("~/Net/Programs/Browser");

	n = CopyTree(src, dst);
	if (n <= 0)
	{
		PrintErr("CopyTree failed from %s\n", src);
		PrintErr("Try: Cd(\"%s\"); Dir;  then verify Home/Net/Programs/Browser exists.\n", cd_let);
		Free(src);
		Free(dst);
		return;
	}

	"%d files copied to %s\n\n", n, dst;
	"Run: $$FG,2$#include \"~/Net/Programs/Browser/Run.ZC\"$$FG$$\n";
	"Then: $$FG,2$BrowserTestLocal();$$FG$$\n\n";

	Free(src);
	Free(dst);
}
EOF

cat > "$STAGING/Install.DD" <<'EOF'
$BG,0$$FG,15$ZealOS Browser Supplement$FG,0$$BG,15$

Mount this CD in UTM, then at the ZealOS command line:

	$FG,2$DriveRep;$FG$
	$FG,2$Cd("C:");$FG$
	$FG,2$#include "T:/Install.ZC"$$FG$
	$FG,2$BrowserInstallFromCD("T:");$$FG$	// use your CD letter

Local test (recommended first): $FG,2$#include "~/Net/Programs/Browser/RunLocal.ZC"$$FG$

Full browser + HTTP: $FG,2$#include "~/Net/Programs/Browser/Run.ZC"$$FG$

$FG,2$Quick test (no network):$FG$

	BrowserTestLocal();

$FG,2$Interactive browser:$FG$

	Browser("file:/Home/Net/Programs/Browser/TestFixtures/Sample.HTML");
EOF

rm -f "$OUT_ISO"

if command -v xorriso >/dev/null 2>&1; then
	echo "Building ISO with xorriso..."
	xorriso -as mkisofs -R -r -J -V ZEALBROWSER -o "$OUT_ISO" "$STAGING"
elif command -v hdiutil >/dev/null 2>&1; then
	echo "Building ISO with hdiutil..."
	hdiutil makehybrid -iso -joliet -joliet-volume-name ZEALBROWSER \
		-default-volume-name ZEALBROWSER -o "$OUT_ISO" "$STAGING"
else
	echo "ERROR: need xorriso or hdiutil to build ISO" >&2
	exit 1
fi

echo
echo "Built: $OUT_ISO"
ls -lh "$OUT_ISO"
echo
echo "UTM (ZealOS VM):"
echo "  1. Shut down the VM if the disk is locked."
echo "  2. Run: ./attach-browser-iso-to-utm.sh"
echo "     Or manually attach $OUT_ISO as a CD in UTM."
echo "  3. Boot ZealOS, DriveRep, Cd to CD letter, #include \"Install.ZC\""
