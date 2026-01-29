#!/usr/bin/env python3
"""
Generate Kafeel app icons programmatically using PIL/Pillow

Usage:
    python3 generate_icons.py [output-directory]

Generates all required macOS icon sizes with Contents.json
"""

import json
import os
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


def create_icon(size: int) -> Image.Image:
    """Create the Kafeel icon at the specified size"""
    # Create image with transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Gradient background (purple to blue)
    # Simplified: use solid purple gradient color
    gradient_color = (102, 126, 234, 255)  # #667eea
    gradient_color2 = (118, 75, 162, 255)  # #764ba2

    # Draw gradient-ish background (simplified for PIL)
    for y in range(size):
        ratio = y / size
        r = int(gradient_color[0] * (1 - ratio) + gradient_color2[0] * ratio)
        g = int(gradient_color[1] * (1 - ratio) + gradient_color2[1] * ratio)
        b = int(gradient_color[2] * (1 - ratio) + gradient_color2[2] * ratio)
        draw.rectangle([(0, y), (size, y + 1)], fill=(r, g, b, 255))

    # Draw activity bars (white, centered vertically in bottom 60% of icon)
    bar_width = int(size * 0.15)
    bar_spacing = int(size * 0.05)
    bar_corner = int(size * 0.03)

    # Heights for each bar (as proportion of size)
    bar_heights = [0.25, 0.45, 0.35, 0.38]

    # Starting position (centered horizontally)
    total_width = 4 * bar_width + 3 * bar_spacing
    start_x = (size - total_width) // 2

    # Vertical positioning (bars sit in bottom area with padding)
    bottom_padding = int(size * 0.15)

    for i, height_ratio in enumerate(bar_heights):
        bar_height = int(size * height_ratio)
        x = start_x + i * (bar_width + bar_spacing)
        y = size - bottom_padding - bar_height

        # Draw rounded rectangle (simplified as rectangle for PIL)
        alpha = 255 if i < 2 else int(255 * (0.9 if i == 2 else 0.85))
        draw.rounded_rectangle(
            [(x, y), (x + bar_width, y + bar_height)],
            radius=bar_corner,
            fill=(255, 255, 255, alpha)
        )

    # Apply rounded corners to entire icon
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = int(size * 0.22)
    mask_draw.rounded_rectangle([(0, 0), (size, size)], radius=corner_radius, fill=255)

    # Apply mask
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(img, (0, 0))
    output.putalpha(mask)

    return output


def generate_all_icons(output_dir: Path):
    """Generate all required macOS icon sizes"""
    output_dir.mkdir(parents=True, exist_ok=True)

    sizes = [
        (16, 1), (16, 2),
        (32, 1), (32, 2),
        (128, 1), (128, 2),
        (256, 1), (256, 2),
        (512, 1), (512, 2),
    ]

    for base_size, scale in sizes:
        pixel_size = base_size * scale
        icon = create_icon(pixel_size)

        suffix = "@2x" if scale == 2 else ""
        filename = f"icon_{base_size}x{base_size}{suffix}.png"
        filepath = output_dir / filename

        icon.save(filepath, 'PNG')
        print(f"Generated: {filename}")

    # Generate Contents.json
    contents = {
        "images": [
            {"filename": f"icon_{s}x{s}.png", "idiom": "mac", "scale": "1x", "size": f"{s}x{s}"}
            for s, scale in sizes if scale == 1
        ] + [
            {"filename": f"icon_{s}x{s}@2x.png", "idiom": "mac", "scale": "2x", "size": f"{s}x{s}"}
            for s, scale in sizes if scale == 2
        ],
        "info": {
            "author": "kafeel-icon-generator",
            "version": 1
        }
    }

    contents_path = output_dir / "Contents.json"
    with open(contents_path, 'w') as f:
        json.dump(contents, f, indent=2)
    print(f"Generated: Contents.json")


def main():
    if len(sys.argv) > 1:
        output_dir = Path(sys.argv[1])
    else:
        output_dir = Path("AppIcon.appiconset")

    print(f"Generating Kafeel app icons...")
    print(f"Output directory: {output_dir.absolute()}")
    print()

    generate_all_icons(output_dir)

    print()
    print("Success! Icons generated.")
    print()
    print("To use these icons:")
    print("1. Create an Xcode project or add Assets.xcassets to your project")
    print("2. Copy the AppIcon.appiconset folder into Assets.xcassets/")
    print("3. The icons will be automatically detected by Xcode")


if __name__ == "__main__":
    main()
