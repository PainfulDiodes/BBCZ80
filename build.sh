#!/usr/bin/env bash

# z88dk modular build script for BBC BASIC Z80
# Usage:
#   ./build-modular.sh             # Build CP/M version (default)
#   ./build-modular.sh cpm         # Build CP/M version
#   ./build-modular.sh acorn       # Build Acorn tube version
#
# Requires: z88dk with z88dk-z80asm
#
# This script builds each module separately to object files, then links them.
# This mirrors the original CP/M build process and avoids namespace collisions.
#
# Before first use, run: ./convert-source.sh

set -e  # Exit on error

# Configuration
OUTPUT_DIR="output"
ASM_DIR="asm"

# Target selection
TARGET="${1:-cpm}"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Module list varies by target
case "$TARGET" in
    cpm)
        MODULES="DIST MAIN EXEC EVAL ASMB MATH HOOK CMOS DATA"
        OUTPUT_NAME="bbcbasic"
        CODE_ORG="0x0100"
        DATA_ORG="0x4B00"
        ;;
    acorn)
        MODULES="MAIN EXEC EVAL ASMB MATH ACORN AMOS DATA"
        OUTPUT_NAME="bbctube"
        CODE_ORG="0x0100"
        DATA_ORG="0x4C00"
        ;;
    *)
        echo "Unknown target: $TARGET"
        echo "Usage: $0 [cpm|acorn]"
        exit 1
        ;;
esac

echo "Building BBC BASIC Z80 ($TARGET) - Modular Build"
echo "================================================="

# Check asm directory exists
if [ ! -d "$ASM_DIR" ]; then
    echo "Error: $ASM_DIR directory not found."
    echo "Run ./convert-source.sh first to convert source files."
    exit 1
fi

# Clean previous build
rm -f "$OUTPUT_DIR"/*.o "$OUTPUT_DIR"/*.bin "$OUTPUT_DIR"/*.map "$OUTPUT_DIR"/*.lis

# Assemble each module to object file
echo ""
echo "Assembling modules..."
for module in $MODULES; do
    if [ ! -f "$ASM_DIR/$module.asm" ]; then
        echo "Error: $ASM_DIR/$module.asm not found"
        exit 1
    fi
    echo "  $module.asm -> $module.o"
    z88dk-z80asm -I"$ASM_DIR" -l -m -o"$OUTPUT_DIR/$module.o" "$ASM_DIR/$module.asm"
done

# Build object file list for linking
# All modules linked together; DATA follows code
ALL_OBJS=""
for module in $MODULES; do
    ALL_OBJS="$ALL_OBJS $OUTPUT_DIR/$module.o"
done

# Link all modules together
# Note: DATA segment will follow code, not at fixed address
# TODO: Use section directives for proper DATA placement at $DATA_ORG
echo ""
echo "Linking all modules at $CODE_ORG..."
z88dk-z80asm -b -m \
    -o"$OUTPUT_DIR/$OUTPUT_NAME.bin" \
    -r$CODE_ORG \
    $ALL_OBJS

# Report size
BIN_SIZE=$(wc -c < "$OUTPUT_DIR/$OUTPUT_NAME.bin" | tr -d ' ')

echo ""
echo "Build complete:"
echo "  Binary: $OUTPUT_DIR/$OUTPUT_NAME.bin ($BIN_SIZE bytes at $CODE_ORG)"
echo ""
echo "Note: DATA segment follows code; not at fixed address $DATA_ORG"
echo "See map file: $OUTPUT_DIR/$OUTPUT_NAME.map"

# Compare with reference if available
REF_BIN="bin/$TARGET/BBCBASIC.COM"
if [ -f "$REF_BIN" ]; then
    REF_SIZE=$(wc -c < "$REF_BIN" | tr -d ' ')
    echo ""
    echo "Reference binary: $REF_BIN ($REF_SIZE bytes)"
fi
