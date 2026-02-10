#!/usr/bin/env bash

# Build BBC BASIC Z80 (BeanZee target)
# Usage: cd build/beanzee && ./build.sh
#
# Output: bbcbasic.{bin,hex,map}
#
# Produces a ROM image containing only the code section.
# DATA segment lives in RAM (0x8000+) and is initialised at runtime.
#
# Requires: z88dk with z88dk-z80asm
# Before first use, run: ../../convert.sh

set -e
cd "$(dirname "$0")"

# Core modules (converted from src/) plus BeanZee-specific modules (from src/beanzee/)
MODULES="BDIST MAIN EXEC EVAL ASMB MATH BHOOK BMOS DATA"
OUTPUT_NAME="bbcbasic"
CODE_ORG="0x0000"
DATA_ORG="0x8000"

echo "Building BBC BASIC Z80 (beanzee)"
echo "================================="

if [ ! -f "MAIN.asm" ]; then
    echo "Error: Converted source files not found."
    echo "Run ../../convert.sh first."
    exit 1
fi

rm -f *.o *.lis

echo ""
echo "Assembling modules..."
for module in $MODULES; do
    if [ ! -f "$module.asm" ]; then
        echo "Error: $module.asm not found"
        exit 1
    fi
    EXTRA_FLAGS=""
    if [ "$module" = "DATA" ]; then
        EXTRA_FLAGS="-DDATA_ORG=$DATA_ORG"
    fi
    echo "  $module.asm -> $module.o"
    z88dk-z80asm -l -m $EXTRA_FLAGS -o"$module.o" "$module.asm"
done

ALL_OBJS=""
for module in $MODULES; do
    ALL_OBJS="$ALL_OBJS $module.o"
done

# Link all modules together
# DATA section is placed at DATA_ORG via section directives
echo ""
echo "Linking all modules at $CODE_ORG..."
z88dk-z80asm -b -m \
    -o"$OUTPUT_NAME.bin" \
    -r$CODE_ORG \
    $ALL_OBJS

# Remove DATA section binary - it lives in RAM, not ROM
rm -f "${OUTPUT_NAME}_data.bin"

BIN_SIZE=$(wc -c < "$OUTPUT_NAME.bin" | tr -d ' ')

xxd "$OUTPUT_NAME.bin" > "$OUTPUT_NAME.hex"

echo ""
echo "Build complete:"
echo "  ROM image: $OUTPUT_NAME.bin ($BIN_SIZE bytes at $CODE_ORG)"
echo "  Hex dump:  $OUTPUT_NAME.hex"
echo "  Map file:  $OUTPUT_NAME.map"
echo ""
echo "Memory layout:"
echo "  ROM: $CODE_ORG - code ($BIN_SIZE bytes)"
echo "  RAM: $DATA_ORG - data segment (initialised at runtime)"
