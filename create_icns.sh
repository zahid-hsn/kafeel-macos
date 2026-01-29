#!/bin/bash
#
# Convert Kafeel icon PNG files to macOS .icns format
#
# Usage: ./create_icns.sh
#
# This script uses macOS's built-in iconutil to create an .icns file
# from the AppIcon.appiconset folder.

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APPICONSET_DIR="$SCRIPT_DIR/AppIcon.appiconset"
OUTPUT_FILE="$SCRIPT_DIR/AppIcon.icns"

echo "Creating Kafeel app icon (.icns)..."
echo "Source: $APPICONSET_DIR"
echo "Output: $OUTPUT_FILE"
echo

if [ ! -d "$APPICONSET_DIR" ]; then
    echo "Error: AppIcon.appiconset directory not found"
    echo "Run generate_icons.py first to create the icon files"
    exit 1
fi

# Use iconutil to create .icns file
iconutil -c icns -o "$OUTPUT_FILE" "$APPICONSET_DIR"

if [ $? -eq 0 ]; then
    echo
    echo "Success! Created AppIcon.icns"
    echo
    echo "To use in a .app bundle:"
    echo "1. Copy AppIcon.icns to YourApp.app/Contents/Resources/"
    echo "2. Add to Info.plist:"
    echo "   <key>CFBundleIconFile</key>"
    echo "   <string>AppIcon</string>"
else
    echo "Error: iconutil failed"
    exit 1
fi
