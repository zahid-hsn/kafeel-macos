#!/bin/bash
#
# View all Kafeel icon assets
#

echo "Opening Kafeel app icons..."
echo

# Open the main .icns file
echo "1. Opening Kafeel.icns (macOS icon bundle)"
open Kafeel.icns

sleep 1

# Open the icon set folder
echo "2. Opening AppIcon.appiconset (PNG files)"
open AppIcon.appiconset/

sleep 1

# Open the largest PNG
echo "3. Opening hero image (1024x1024)"
open AppIcon.appiconset/icon_512x512@2x.png

echo
echo "Icon files opened!"
echo
echo "File locations:"
echo "  • Kafeel.icns - macOS icon bundle"
echo "  • AppIcon.appiconset/ - All PNG sizes"
echo "  • Sources/App/Assets/AppIconView.swift - SwiftUI code"
echo
