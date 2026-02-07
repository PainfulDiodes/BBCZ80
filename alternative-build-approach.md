# Alternative Build Approach: Modular Build

This document describes an alternative build approach that preserves the original modular structure of BBC BASIC Z80. The main build uses an include-based approach (see [building-BBCZ80.md](building-BBCZ80.md)).

## Modular Build

This approach mirrors the original CP/M linker-based build.

### Process

1. Assemble each module separately to object files
2. Link object files together
3. Handle DATA segment placement separately

### Advantages

- Preserves original code structure
- Faster incremental rebuilds (only changed modules recompile)
- Closer to original build process
- Better for understanding module boundaries

### Disadvantages

- More complex build script
- Requires PUBLIC/EXTERN directives to work correctly
- DATA segment handling is awkward with z88dk

### DATA Segment Handling

The original build places DATA at a specific address using the linker's `/p:` directive. The modular build handles this by producing separate binaries that would need to be combined or loaded separately.

### ORG Directive Conflicts

Some modules contain their own ORG directives (e.g., DIST.Z80 has `ORG 100H` and `ORG 1F0H`). These may conflict with the modular approach where the linker controls placement.

## Build Script

The following script implements this modular build approach:

```bash
#!/usr/bin/env bash

# z88dk modular build script for BBC BASIC Z80
# Usage:
#   ./build-modular.sh             # Build CP/M version (default)
#   ./build-modular.sh cpm         # Build CP/M version
#   ./build-modular.sh acorn       # Build Acorn tube version
#
# Requires: z88dk with z88dk-z80asm
#
# Note: Source files need directive translation before first use.
# See convert-source.sh for automated conversion.

set -e  # Exit on error

# Configuration
OUTPUT_DIR="output"
SRC_DIR="src"

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

echo "Building BBC BASIC Z80 ($TARGET)"
echo "================================"

# Clean previous build
rm -f "$OUTPUT_DIR"/*.o "$OUTPUT_DIR"/*.bin "$OUTPUT_DIR"/*.map "$OUTPUT_DIR"/*.lis

# Assemble each module
for module in $MODULES; do
    echo "Assembling $module..."
    z88dk-z80asm -l -m "$SRC_DIR/$module.Z80" -o"$OUTPUT_DIR/$module.o"
done

# Link all modules
# Note: z88dk-z80asm links in order specified, DATA module placed at DATA_ORG
echo "Linking..."

# Build the object file list
OBJ_LIST=""
for module in $MODULES; do
    if [ "$module" = "DATA" ]; then
        # DATA module has different origin - handle separately
        continue
    fi
    OBJ_LIST="$OBJ_LIST $OUTPUT_DIR/$module.o"
done

# Link code modules
z88dk-z80asm -b -m \
    -o"$OUTPUT_DIR/$OUTPUT_NAME.bin" \
    --org=$CODE_ORG \
    $OBJ_LIST

# Link DATA module at separate address
z88dk-z80asm -b -m \
    -o"$OUTPUT_DIR/data.bin" \
    --org=$DATA_ORG \
    "$OUTPUT_DIR/DATA.o"

# Create hex dump for inspection
hexdump -C "$OUTPUT_DIR/$OUTPUT_NAME.bin" > "$OUTPUT_DIR/$OUTPUT_NAME.hex"

# Create Intel HEX format for programmers
z88dk-appmake +hex --org $CODE_ORG -b "$OUTPUT_DIR/$OUTPUT_NAME.bin" -o "$OUTPUT_DIR/$OUTPUT_NAME.ihx"

echo ""
echo "Build complete:"
echo "  Binary: $OUTPUT_DIR/$OUTPUT_NAME.bin (code at $CODE_ORG)"
echo "  Data:   $OUTPUT_DIR/data.bin (at $DATA_ORG)"
echo "  Hex:    $OUTPUT_DIR/$OUTPUT_NAME.hex"
echo "  Intel:  $OUTPUT_DIR/$OUTPUT_NAME.ihx"
```
