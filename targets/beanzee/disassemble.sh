#!/usr/bin/env bash

# Disassemble bbcbasic.bin (BeanZee target)
# Usage: cd targets/beanzee && ./disassemble.sh
#
# Requires: z88dk with z88dk-dis

set -e
cd "$(dirname "$0")"

BIN="bbcbasic.bin"
MAP="bbcbasic.map"
ORG="0x0000"

if [ ! -f "$BIN" ]; then
    echo "Error: $BIN not found. Run ./build.sh first."
    exit 1
fi

OUTPUT="disassembled.asm"

if [ -f "$MAP" ]; then
    z88dk-dis -o $ORG -x "$MAP" "$BIN" > "$OUTPUT"
else
    z88dk-dis -o $ORG "$BIN" > "$OUTPUT"
fi

echo "Disassembled to $OUTPUT"
