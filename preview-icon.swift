#!/usr/bin/env swift
import SwiftUI
import AppKit

// Simple script to preview the app icon design
// Run with: swift preview-icon.swift

@main
struct IconPreview {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Kafeel Icon Preview"

        let hostingView = NSHostingView(rootView: IconPreviewView())
        window.contentView = hostingView
        window.makeKeyAndOrderFront(nil)

        app.activate(ignoringOtherApps: true)
        app.run()
    }
}

struct IconPreviewView: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("Kafeel App Icon")
                .font(.title)

            AppIconView(size: 256)
                .frame(width: 256, height: 256)
                .shadow(radius: 10)

            Text("256x256 preview")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Modern gradient background - purple to blue
            LinearGradient(
                colors: [
                    Color(hex: "667eea"),
                    Color(hex: "764ba2")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Stylized activity chart
            VStack(spacing: 0) {
                Spacer()

                HStack(alignment: .bottom, spacing: size * 0.05) {
                    // Bar 1 - Short
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white)
                        .frame(width: size * 0.15, height: size * 0.25)

                    // Bar 2 - Tall (focus peak)
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white)
                        .frame(width: size * 0.15, height: size * 0.45)

                    // Bar 3 - Medium
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white.opacity(0.9))
                        .frame(width: size * 0.15, height: size * 0.35)

                    // Bar 4 - Growing
                    RoundedRectangle(cornerRadius: size * 0.03)
                        .fill(.white.opacity(0.85))
                        .frame(width: size * 0.15, height: size * 0.38)
                }

                Spacer()
                    .frame(height: size * 0.15)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
