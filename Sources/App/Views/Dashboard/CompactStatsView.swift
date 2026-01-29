import SwiftUI
import KafeelCore

struct CompactStatsView: View {
    let stats: [AppUsageStat]
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    @State private var showDetail = false
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 0) {
            CompactStatItem(
                icon: "desktopcomputer",
                value: totalScreenTime,
                label: "Total Time",
                color: .blue
            )

            Divider()
                .frame(height: 50)

            CompactStatItem(
                icon: "brain.head.profile",
                value: deepWorkTime,
                label: "Deep Work",
                color: .green
            )

            Divider()
                .frame(height: 50)

            CompactStatItem(
                icon: "bolt.fill",
                value: "\(flowStates)",
                label: "Flow States",
                color: .purple
            )

            Divider()
                .frame(height: 50)

            CompactStatItem(
                icon: "percent",
                value: productivePercentage,
                label: "Productive",
                color: .orange
            )
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .onTapGesture { showDetail = true }
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovering)
        .onHover { isHovering = $0 }
        .sheet(isPresented: $showDetail) {
            CompactStatsDetailView(stats: stats, activities: activities, categories: categories)
        }
    }

    // MARK: - Computed Properties

    private var totalScreenTime: String {
        let total = stats.reduce(0) { $0 + $1.totalSeconds }
        return formatTime(total)
    }

    private var deepWorkTime: String {
        // Deep work = time in productive apps for sessions >= 25 min
        let deepWorkActivities = activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 1500 // 25 min
        }
        let total = deepWorkActivities.reduce(0) { $0 + $1.durationSeconds }
        return formatTime(total)
    }

    private var flowStates: Int {
        // Flow state = sessions >= 45 min in productive apps
        activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 2700 // 45 min
        }.count
    }

    private var productivePercentage: String {
        let totalSeconds = stats.reduce(0) { $0 + $1.totalSeconds }
        guard totalSeconds > 0 else { return "0%" }

        let productiveSeconds = stats
            .filter { (categories[$0.bundleIdentifier] ?? .neutral) == .productive }
            .reduce(0) { $0 + $1.totalSeconds }

        let percentage = Int((Double(productiveSeconds) / Double(totalSeconds)) * 100)
        return "\(percentage)%"
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct CompactStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Detail View

struct CompactStatsDetailView: View {
    let stats: [AppUsageStat]
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Statistics Detail")
                    .font(.title2.weight(.bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 20) {
                DetailStatCard(
                    icon: "desktopcomputer",
                    label: "Total Screen Time",
                    value: totalScreenTime,
                    color: .blue,
                    subtitle: "All activity today"
                )

                DetailStatCard(
                    icon: "brain.head.profile",
                    label: "Deep Work Time",
                    value: deepWorkTime,
                    color: .green,
                    subtitle: "Sessions of 25+ minutes in productive apps"
                )

                DetailStatCard(
                    icon: "bolt.fill",
                    label: "Flow States",
                    value: "\(flowStates) sessions",
                    color: .purple,
                    subtitle: "Sessions of 45+ minutes in productive apps"
                )

                DetailStatCard(
                    icon: "percent",
                    label: "Productive Time",
                    value: productivePercentage,
                    color: .orange,
                    subtitle: "Percentage of time in productive apps"
                )
            }
        }
        .padding(32)
        .frame(width: 500)
    }

    private var totalScreenTime: String {
        let total = stats.reduce(0) { $0 + $1.totalSeconds }
        return formatTime(total)
    }

    private var deepWorkTime: String {
        let deepWorkActivities = activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 1500
        }
        let total = deepWorkActivities.reduce(0) { $0 + $1.durationSeconds }
        return formatTime(total)
    }

    private var flowStates: Int {
        activities.filter { activity in
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            return category == .productive && activity.durationSeconds >= 2700
        }.count
    }

    private var productivePercentage: String {
        let totalSeconds = stats.reduce(0) { $0 + $1.totalSeconds }
        guard totalSeconds > 0 else { return "0%" }

        let productiveSeconds = stats
            .filter { (categories[$0.bundleIdentifier] ?? .neutral) == .productive }
            .reduce(0) { $0 + $1.totalSeconds }

        let percentage = Int((Double(productiveSeconds) / Double(totalSeconds)) * 100)
        return "\(percentage)%"
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct DetailStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.title2.weight(.bold))

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    let stats = [
        AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
        AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
    ]

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.google.Chrome": CategoryType.neutral,
    ]

    return CompactStatsView(
        stats: stats,
        activities: [],
        categories: categories
    )
    .padding()
    .frame(width: 600)
}
