#!/bin/sh
# Scan ZealOS kernel .ZC for HolyC patterns that fail Comp("/Kernel/Kernel").
# Not a full compiler; catches documented traps from ::/Doc/USBBoot.DD.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SRC_DIR="${SRC_DIR:-$SCRIPT_DIR/../src}"
SCOPE="${1:-Kernel/SerialDev}"

if [ ! -d "$SRC_DIR/$SCOPE" ]; then
	echo "ERROR: $SRC_DIR/$SCOPE not found" >&2
	exit 1
fi

FAIL=0
ISSUES=0

check() {
	name=$1
	pattern=$2
	shift 2
	files=$(rg -l "$pattern" "$@" 2>/dev/null || true)
	if [ -n "$files" ]; then
		echo "FAIL: $name"
		rg -n "$pattern" "$@" 2>/dev/null || true
		echo
		FAIL=1
		ISSUES=$((ISSUES + 1))
	fi
}

echo "ZealC kernel trap scan: $SRC_DIR/$SCOPE"
echo

# continue (ZealC has no continue; use goto)
check "continue statement" '\bcontinue\s*;' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# compound assign on postfix-cast lvalue: *(x)(U32 *) |= ...
check "compound assign on postfix cast" '\)\(U[0-9]+ \*\)\s*[|&]=' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# *ptr = !*ptr
check "pointer ! toggle (*x = !*x)" '\*\w+\s*=\s*!\*' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# member/global self ! toggle (usb.x = !usb.x)
check "self ! toggle (member = !member)" '\.\w+\s*=\s*!\w+\.' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'
check "self ! toggle (global = !global)" '^\s*\w+\.\w+\s*=\s*!\w+\.\w+' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# trb->field &= or |= (often needs temp; &= ~ is the common trap)
check "trb->field compound assign" '->\w+\s*[|&]=' \
	"$SRC_DIR/$SCOPE" --glob 'USB*.ZC'

# postfix ++/-- on dereference
check "postfix inc/dec on deref" '\(\*\w+\)\+\+|--\(\*\w+\)|\(\*\w+\)--|\+\+\(\*\w+\)' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# C-style casts are intentionally not checked here. A simple regex cannot
# distinguish invalid "(U32 *)expr" from valid ZealC postfix casts "expr(U32 *)".

# DevCtx(slot,0)[0]; use temp pointer
check "DevCtx(...)[subscript]" 'DevCtx\([^)]+\)\[' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# t = Spawn( in kernel (Invalid lval at Spawn)
check "Spawn assignment in kernel" '=\s*Spawn\(' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# StrCmp (use StrCompare)
check "StrCmp (use StrCompare)" '\bStrCmp\b' \
	"$SRC_DIR/$SCOPE" --glob '*.ZC'

# Risky USB* compound names in SerialDev (HolyC may split USB.Mouse).
if [ -d "$SRC_DIR/$SCOPE/SerialDev" ]; then
	USB_SCOPE="$SRC_DIR/$SCOPE/SerialDev"
else
	USB_SCOPE="$SRC_DIR/$SCOPE"
fi
if rg -q '\bUSB[A-Z][a-zA-Z0-9_]+\s*\(' "$USB_SCOPE" --glob 'USB*.ZC' 2>/dev/null; then
	echo "WARN: USB* compound function names in SerialDev (review for USB.X parsing):"
	rg -n '\bUSB[A-Z][a-zA-Z0-9_]+\s*\(' "$USB_SCOPE" --glob 'USB*.ZC' 2>/dev/null || true
	echo "(warnings do not fail the scan)"
	echo
fi

# KConfig: interactive prompt code is still parsed even if hidden below returns.
if [ -f "$SRC_DIR/Kernel/KConfig.ZC" ]; then
	if rg -q "CharGet|StrGet|I64Get" "$SRC_DIR/Kernel/KConfig.ZC" 2>/dev/null; then
		echo "FAIL: KConfig still contains interactive prompt code"
		rg -n "CharGet|StrGet|I64Get" "$SRC_DIR/Kernel/KConfig.ZC" 2>/dev/null || true
		echo
		FAIL=1
		ISSUES=$((ISSUES + 1))
	fi
fi

if [ "$FAIL" -eq 0 ]; then
	echo "OK: no documented ZealC kernel traps found in $SCOPE"
	exit 0
fi

echo "$ISSUES trap category(ies) matched; fix before BootHDInsAuto / auto-rebuild."
echo "See ZealOS/src/Doc/USBBoot.DD (ZealC Kernel Compile Traps)."
exit 1
