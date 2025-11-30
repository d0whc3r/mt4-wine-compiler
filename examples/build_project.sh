#!/bin/bash
set -e

# MT4 Project Build Script
# This script demonstrates how to build a complex MT4 project with dependencies

echo "Starting MT4 project build..."

# 1. Copy project sources to Wine environment
echo "Copying project sources..."
cp -r /home/wine/project/Experts /home/wine/.mt4/drive_c/mt4/
cp -r /home/wine/project/Include /home/wine/.mt4/drive_c/mt4/

# 2. Copy library dependencies (if you have external libraries)
echo "Copying library dependencies..."
if [ -d "/home/wine/project/lib" ]; then
    mkdir -p /home/wine/.mt4/drive_c/mt4/Include/External
    cp -r /home/wine/project/lib/* /home/wine/.mt4/drive_c/mt4/Include/External/
fi

# 3. Compile all .mq4 files
echo "Compiling .mq4 files..."
find "/home/wine/.mt4/drive_c/mt4/Experts" -name "*.mq4" | while read source_file; do
    basename_file=$(basename "$source_file")
    echo "  Compiling $basename_file..."
    
    # Use the entrypoint script for each file
    /home/wine/entrypoint.sh "$source_file" || {
        echo "  ❌ Failed to compile $basename_file"
        exit 1
    }
done

# 4. Copy compiled files to artifacts directory
echo "Copying artifacts..."
mkdir -p /home/wine/artifacts
cp /home/wine/.mt4/drive_c/mt4/Experts/*.ex4 /home/wine/artifacts/ 2>/dev/null || true

echo "✅ Build completed successfully!"
echo "Artifacts available in /home/wine/artifacts/"

