#!/usr/bin/env bash

# Remove all generated files from build/ (converted source and build artifacts)
# Cleans per-target subdirectories: build/cpm/, build/acorn/, build/beanzee/
# Preserves tracked scripts (build.sh) and persistent source (src/beanzee/)
# Usage: ./clean.sh

set -e

BUILD_DIRS="build/cpm build/acorn build/beanzee"

count=0
for dir in $BUILD_DIRS; do
    for pattern in "$dir"/*.asm "$dir"/*.inc "$dir"/*.o "$dir"/*.bin "$dir"/*.map "$dir"/*.lis "$dir"/*.hex; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                rm -f "$file"
                count=$((count + 1))
            fi
        done
    done
done

if [ "$count" -gt 0 ]; then
    echo "Removed $count generated file(s) from build/"
else
    echo "Nothing to clean - no generated files in build/"
fi
