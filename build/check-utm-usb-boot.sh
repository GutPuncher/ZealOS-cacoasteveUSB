#!/bin/sh
# Read /Home/UsbBootLast.DD from the ZealOS UTM disk (no VM keyboard needed).
set -e
UTM_BUNDLE="${UTM_BUNDLE:-$HOME/Library/Containers/com.utmapp.UTM/Data/Documents/ZealOS.utm}"
IMAGE_NAME=$(/usr/libexec/PlistBuddy -c "Print :Drive:0:ImageName" "$UTM_BUNDLE/config.plist" 2>/dev/null || true)
[ -n "$IMAGE_NAME" ] || IMAGE_NAME="9B0F9544-DD68-41D3-ACC3-96A486D80F73-2.qcow2"
DISK="$UTM_BUNDLE/Data/$IMAGE_NAME"
PART1_OFF=32256
PART2_OFF=542900736
export MTOOLS_SKIP_CHECK=1

if [ ! -f "$DISK" ]; then
	echo "ERROR: disk not found: $DISK" >&2
	exit 1
fi

python3 - "$DISK" "$PART1_OFF" "$PART2_OFF" <<'PY'
import subprocess, sys, tempfile, os
disk = sys.argv[1]
offsets = [int(sys.argv[2]), int(sys.argv[3])]
raw = tempfile.mktemp(suffix=".raw")
try:
    subprocess.run(["qemu-img", "convert", "-f", "qcow2", "-O", "raw", disk, raw], check=True, capture_output=True)
except subprocess.CalledProcessError as e:
    err = e.stderr.decode("ascii", "replace").strip()
    print("ERROR: could not read qcow2. Shut down the ZealOS UTM VM first.", file=sys.stderr)
    if err:
        print(err, file=sys.stderr)
    sys.exit(1)
try:
    for n, off in enumerate(offsets, 1):
        img = f"{raw}@@{off}"
        print(f"Partition {n}:")
        for path in ("::/Home/UsbBootLast.DD", "::/Home/UsbBootOk.DD", "::/Home/BootInsPending.DD", "::/Home/NormalRebuildKernel.DD", "::/Home/BootInsStage.DD", "::/Home/BootInsErrs.DD", "::/Home/BootCompileLog.DD", "::/Home/BootAutoKernelConfig.DD"):
            out = tempfile.mktemp()
            r = subprocess.run(["mcopy", "-i", img, path, out], capture_output=True)
            label = path.split("/")[-1]
            if r.returncode == 0:
                data = open(out, "rb").read()
                text = data.decode("ascii", "replace").strip()
                print(f"{label}:")
                if text:
                    if label == "BootCompileLog.DD" and len(text) > 8000:
                        print("... (truncated, showing last 8000 chars) ...")
                        print(text[-8000:])
                    else:
                        print(text)
                else:
                    print("(empty)")
            else:
                print(f"{label}: (missing)")
            if os.path.exists(out):
                os.remove(out)
        print()
finally:
    os.remove(raw)
print(f"Disk: {disk}")
PY
