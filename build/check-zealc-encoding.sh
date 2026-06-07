#!/bin/sh
# Validate ZealOS CP437 source files before syncing them to a VM disk.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SRC_DIR="${SRC_DIR:-$SCRIPT_DIR/../src}"

if [ "$#" -eq 0 ]; then
	set -- "$SRC_DIR"
fi

python3 - "$@" <<'PY'
import pathlib
import sys

paths = [pathlib.Path(arg) for arg in sys.argv[1:]]
suffixes = {".ZC", ".HH", ".DD", ".IN", ".PRJ"}

files = []
for path in paths:
    if path.is_dir():
        files.extend(p for p in path.rglob("*") if p.suffix in suffixes)
    elif path.suffix in suffixes:
        files.append(path)

utf8_sequences = []
for val in range(0x80, 0x100):
    ch = bytes([val]).decode("cp437")
    raw = ch.encode("utf-8")
    if len(raw) > 1:
        utf8_sequences.append((raw, val, ch))
utf8_sequences.sort(key=lambda item: len(item[0]), reverse=True)

issues = []

def line_no(data, offset):
    return data.count(b"\n", 0, offset) + 1

for path in sorted(set(files)):
    try:
        data = path.read_bytes()
    except OSError as exc:
        issues.append((path, 0, f"could not read: {exc}"))
        continue

    for raw, val, ch in utf8_sequences:
        start = 0
        while True:
            idx = data.find(raw, start)
            if idx < 0:
                break
            issues.append((path, line_no(data, idx),
                           f"raw UTF-8 {ch!r}; use CP437 byte 0x{val:02X}"))
            start = idx + len(raw)

    start = 0
    while True:
        idx = data.find(b"\x9D", start)
        if idx < 0:
            break
        line_start = data.rfind(b"\n", 0, idx) + 1
        line_end = data.find(b"\n", idx)
        if line_end < 0:
            line_end = len(data)
        line = data[line_start:line_end]
        comment = line.find(b"//")
        in_comment = comment >= 0 and idx > line_start + comment
        font_glyph_comment = path.name in {"FontAux.ZC", "FontStd.ZC"} and in_comment
        if not font_glyph_comment:
            issues.append((path, line_no(data, idx),
                           "CP437 byte 0x9D (yen) in source; likely corrupt pi/infinity token"))
        start = idx + 1

if issues:
    print("FAIL: ZealOS CP437 encoding check")
    for path, line, message in issues[:200]:
        where = f"{path}:{line}" if line else str(path)
        print(f"{where}: {message}")
    if len(issues) > 200:
        print(f"... {len(issues) - 200} more issue(s)")
    sys.exit(1)

print(f"OK: CP437 encoding check passed ({len(files)} file(s))")
PY
