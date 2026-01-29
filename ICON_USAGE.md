# Kafeel App Icon

## Design

The Kafeel app icon features a modern, minimalist design perfect for a productivity/activity tracker:

- **Concept**: Stylized bar chart showing activity levels
- **Colors**: Purple to blue gradient (#667eea to #764ba2)
- **Style**: Clean white bars with rounded corners
- **Shape**: macOS-standard rounded square (continuous corner radius)

## Icon Files

All icon files have been generated at:
`/Users/zahid/workspace/new/kafeel/apps/macos-client/AppIcon.appiconset/`

### Generated Sizes
- 16x16 (1x and 2x)
- 32x32 (1x and 2x)
- 128x128 (1x and 2x)
- 256x256 (1x and 2x)
- 512x512 (1x and 2x)

The largest size (icon_512x512@2x.png) is 1024x1024 pixels - perfect for high-resolution displays.

## Using the Icons

### Option 1: Xcode Project
If you create an Xcode project:
1. Add an Asset Catalog (Assets.xcassets) to your project
2. Copy the entire `AppIcon.appiconset` folder into `Assets.xcassets/`
3. Xcode will automatically detect and use the icons

### Option 2: Swift Package Manager (SPM)
SPM doesn't support asset catalogs natively. For SPM projects:
- The icons are already used programmatically via `AppIconView.swift`
- The SwiftUI view renders the icon in the sidebar and About screen
- For menu bar, we use `MenuBarIconView` or SF Symbols

### Option 3: Custom .app Bundle
When building a distributable .app:
1. Build your app with `swift build -c release`
2. Create .app bundle structure manually
3. Copy the largest icon (1024x1024) to `Contents/Resources/AppIcon.icns`
4. Use `iconutil` to convert PNG to ICNS format:
   ```bash
   iconutil -c icns -o AppIcon.icns AppIcon.appiconset
   ```

## Programmatic Icon (SwiftUI)

The icon is also available as SwiftUI views:

### AppIconView
```swift
// Full-color gradient icon with chart
AppIconView(size: 128)
    .frame(width: 128, height: 128)
```

Used in:
- Sidebar header (32x32)
- About screen (128x128)

### MenuBarIconView
```swift
// Monochrome template icon for menu bar
MenuBarIconView(size: 18)
```

Used in:
- Menu bar icon (18x18)
- Adapts to light/dark mode automatically

## Files

- `/Sources/App/Assets/AppIconView.swift` - SwiftUI icon views
- `/Sources/App/Assets/IconGenerator.swift` - PNG export utility (Swift)
- `/generate_icons.py` - Python script for generating PNGs (used)
- `/AppIcon.appiconset/` - Generated PNG files + Contents.json
- `/Sources/App/Views/AboutView.swift` - About screen showing the icon

## Customization

To change the icon design, edit `AppIconView.swift`:
- Change gradient colors (currently #667eea to #764ba2)
- Adjust bar heights and spacing
- Modify corner radius
- Change bar count or arrangement

After editing, regenerate PNGs:
```bash
python3 generate_icons.py AppIcon.appiconset
```

## Preview

Run the standalone preview script to see the icon:
```bash
swift preview-icon.swift
```

This opens a window showing the icon at 256x256 resolution.
