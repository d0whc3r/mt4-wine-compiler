#!/bin/bash
set -e

# Defaults
COMPILER_PATH="/home/wine/.mt4/drive_c/mt4/metaeditor.exe"
INCLUDE_PATH="C:\\mt4"
LOG_FILE="/home/wine/.mt4/drive_c/mt4/compilation.log"

# Check arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <source_file_path> [output_path]"
    echo "Example: $0 src/Expert.mq4"
    exit 1
fi

SOURCE_FILE="$1"
# If output path is not provided, it defaults to the source file location but compiled
OUTPUT_PATH="${2:-}"

# Convert paths to Windows format for Wine
# We assume the container mounts the workspace at /home/wine/src or similar
# But for flexibility, we'll try to handle relative paths from the working directory

# Ensure source file exists
if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: Source file '$SOURCE_FILE' not found."
    exit 1
fi

# Prepare the command
# We need to copy the source file to a location Wine can access easily or map it correctly.
# We preserve the original filename to ensure output matches expectations and __FILE__ macros work.
BASENAME=$(basename "$SOURCE_FILE")
INTERNAL_SOURCE_PATH="C:\\mt4\\$BASENAME"
cp "$SOURCE_FILE" "/home/wine/.mt4/drive_c/mt4/$BASENAME"

echo "Compiling $SOURCE_FILE..."

# Run compilation
# /compile:<path>
# /include:<path>
# /log[:<path>]
WINEPREFIX=/home/wine/.mt4 WINEARCH=win32 wine "$COMPILER_PATH" /compile:"$INTERNAL_SOURCE_PATH" /include:"$INCLUDE_PATH" /log:"$LOG_FILE" || true

# Check for log file
if [ -f "$LOG_FILE" ]; then
    # The log file is likely UTF-16LE. Convert it to UTF-8 or ASCII for grep.
    # We use tr to strip null bytes which is a simple way to convert basic UTF-16LE to ASCII
    # This avoids dependency on iconv if not present, though iconv is better.
    # Let's try to read it into a variable with conversion
    LOG_CONTENT=$(cat "$LOG_FILE" | tr -d '\000')
    
    # Check for success in log (MetaEditor doesn't always return non-zero on failure)
    if echo "$LOG_CONTENT" | grep -q "0 errors"; then
        echo "Compilation successful."
        
        # If successful, the .ex4 file should be next to the source in drive_c
        # It will have the same basename but with .ex4 extension
        COMPILED_BASENAME="${BASENAME%.*}.ex4"
        COMPILED_FILE="/home/wine/.mt4/drive_c/mt4/$COMPILED_BASENAME"
        
        if [ -f "$COMPILED_FILE" ]; then
            # Determine destination
            if [ -z "$OUTPUT_PATH" ]; then
                # Default: replace .mq4 with .ex4 in the original path
                DESTINATION="${SOURCE_FILE%.mq4}.ex4"
            else
                DESTINATION="$OUTPUT_PATH"
            fi
            
            echo "Moving compiled file to $DESTINATION"
            mv "$COMPILED_FILE" "$DESTINATION"
        else
            echo "Error: Compiled file not found despite '0 errors' log."
            exit 1
        fi
    else
        echo "Compilation failed."
        exit 1
    fi
else
    echo "Error: Log file not generated."
    exit 1
fi
