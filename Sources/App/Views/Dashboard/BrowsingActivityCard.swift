import SwiftUI

struct BrowsingActivityCard: View {
    @State private var showDetail = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "safari.fill")
                    .foregroundStyle(.blue)
                Text("Browsing Activity")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)

                Text("Coming Soon")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.primary)

                Text("Browser history tracking will be available in a future update")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovering)
        .onHover { isHovering = $0 }
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            BrowsingActivityDetailView()
        }
    }
}

// MARK: - Detail View

struct BrowsingActivityDetailView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "safari.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Browsing Activity")
                        .font(.title2.weight(.bold))

                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 20) {
                Image(systemName: "globe")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary.opacity(0.5))

                VStack(spacing: 12) {
                    Text("Browser History Tracking")
                        .font(.title3.weight(.semibold))

                    Text("This feature will track your browsing patterns and provide insights into:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 8) {
                        FeatureItem(icon: "chart.bar.fill", text: "Top visited websites")
                        FeatureItem(icon: "clock.fill", text: "Time spent on different sites")
                        FeatureItem(icon: "tag.fill", text: "Website categories and patterns")
                        FeatureItem(icon: "eye.fill", text: "Productive vs distracting sites")
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text("Stay tuned for future updates!")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 500, height: 500)
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.blue)
                .frame(width: 24)

            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }
}

#Preview {
    BrowsingActivityCard()
        .padding()
        .frame(width: 400)
}
