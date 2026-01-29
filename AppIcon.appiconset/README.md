# Kafeel App Icon Set

## Overview

This directory contains the complete Kafeel app icon set for macOS, generated programmatically with all required sizes and resolutions.

## Icon Design

**Concept**: Modern activity tracker icon featuring a stylized bar chart
**Colors**: Purple-blue gradient (#667eea → #764ba2)
**Style**: Clean white rounded bars on gradient background
**Theme**: Productivity, analytics, focus tracking

## Contents

### Icon Files
All standard macOS icon sizes at 1x and 2x resolutions:

| Size | 1x (pixels) | 2x (pixels) | Filename |
|------|-------------|-------------|----------|
| 16pt | 16x16 | 32x32 | icon_16x16.png, icon_16x16@2x.png |
| 32pt | 32x32 | 64x64 | icon_32x32.png, icon_32x32@2x.png |
| 128pt | 128x128 | 256x256 | icon_128x128.png, icon_128x128@2x.png |
| 256pt | 256x256 | 512x512 | icon_256x256.png, icon_256x256@2x.png |
| 512pt | 512x512 | 1024x1024 | icon_512x512.png, icon_512x512@2x.png |

### Contents.json
Xcode Asset Catalog metadata file for automatic icon detection.

## Usage

### For Xcode Projects
1. Create or open an Xcode project
2. Add/create Assets.xcassets in your project
3. Copy this entire `AppIcon.appiconset` folder into `Assets.xcassets/`
4. Xcode will automatically recognize and use the icons

### For .app Bundle
1. Use `iconutil` to convert to .icns format:
   ```bash
   iconutil -c icns -o AppIcon.icns AppIcon.appiconset
   ```
2. Copy AppIcon.icns to `YourApp.app/Contents/Resources/`
3. Reference in Info.plist:
   ```xml
   <key>CFBundleIconFile</key>
   <string>AppIcon</string>
   ```

## Regenerating Icons

If you need to regenerate these icons:

```bash
# Using Python script (recommended)
python3 ../generate_icons.py AppIcon.appiconset

# Or using Swift (once project builds)
swift run KafeelClient --generate-icons AppIcon.appiconset
```

## Design Philosophy

The bar chart design symbolizes:
- Activity tracking and monitoring
- Data visualization and analytics
- Productivity metrics
- Time management
- Focus score trends

The gradient background provides:
- Modern, professional aesthetic
- Good contrast for dock visibility
- Distinctive color scheme
- Matches app's overall design language

## Technical Details

- Format: PNG with transparency
- Color Space: sRGB
- Corners: Rounded (22% radius for macOS compliance)
- Generated: Programmatically using Python/PIL
- Quality: Optimized for all resolutions
