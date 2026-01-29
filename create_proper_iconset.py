#!/usr/bin/env python3
"""
Create a properly formatted iconset for macOS iconutil

iconutil expects specific naming: icon_<size>x<size>[x2].png
where x2 is used instead of @2x
"""

import shutil
from pathlib import Path

# Source and destination
src_dir = Path("AppIcon.appiconset")
dest_dir = Path("Kafeel.iconset")

# Create destination directory
dest_dir.mkdir(exist_ok=True)

# Mapping from our format to iconutil format
mappings = [
    ("icon_16x16.png", "icon_16x16.png"),
    ("icon_16x16@2x.png", "icon_16x16@2x.png"),
    ("icon_32x32.png", "icon_32x32.png"),
    ("icon_32x32@2x.png", "icon_32x32@2x.png"),
    ("icon_128x128.png", "icon_128x128.png"),
    ("icon_128x128@2x.png", "icon_128x128@2x.png"),
    ("icon_256x256.png", "icon_256x256.png"),
    ("icon_256x256@2x.png", "icon_256x256@2x.png"),
    ("icon_512x512.png", "icon_512x512.png"),
    ("icon_512x512@2x.png", "icon_512x512@2x.png"),
]

print("Creating iconutil-compatible iconset...")
for src_name, dest_name in mappings:
    src_file = src_dir / src_name
    dest_file = dest_dir / dest_name

    if src_file.exists():
        shutil.copy(src_file, dest_file)
        print(f"Copied: {dest_name}")

print(f"\nIconset created at: {dest_dir.absolute()}")
print("\nTo create .icns file, run:")
print(f"  iconutil -c icns {dest_dir}")
