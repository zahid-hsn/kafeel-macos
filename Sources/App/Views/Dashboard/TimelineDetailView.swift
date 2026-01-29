import SwiftUI
import KafeelCore

struct TimelineDetailView: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @Environment(\.dismiss) private var dismiss

    private let startHour = 0
    private let endHour = 24

    private var timelineActivities: [TimelineActivity] {
        let calendar = Calendar.current

        return activities.compactMap { activity in
            guard let hourComponent = calendar.dateComponents([.hour, .minute], from: activity.startTime).hour,
                  let minuteComponent = calendar.dateComponents([.hour, .minute], from: activity.startTime).minute else {
                return nil
            }

            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let startMinutes = hourComponent * 60 + minuteComponent
            let endMinutes = startMinutes + (activity.durationSeconds / 60)

            return TimelineActivity(
                activity: activity,
                category: category,
                startMinutes: startMinutes,
                endMinutes: endMinutes
            )
        }.sorted { $0.startMinutes < $1.startMinutes }
    }

    private var categoryStats: [CategoryType: (count: Int, duration: Int)] {
        var stats: [CategoryType: (count: Int, duration: Int)] = [:]

        for activity in activities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let current = stats[category] ?? (0, 0)
            stats[category] = (current.count + 1, current.duration + activity.durationSeconds)
        }

        return stats
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    categoryStatsView
                    fullTimeline
                    activityList
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Text("Activity Timeline Details")
                .font(.title2.weight(.semibold))

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    private var categoryStatsView: some View {
        HStack(spacing: 16) {
            ForEach([CategoryType.productive, CategoryType.neutral, CategoryType.distracting], id: \.self) { category in
                if let stats = categoryStats[category] {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(category.color)
                                .frame(width: 10, height: 10)
                            Text(category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text("\(stats.count)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(category.color)

                        Text(formatDuration(stats.duration))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
    }

    private var fullTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Full Day Timeline")
                .font(.headline)

            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    // Hour grid lines
                    ForEach(0..<24, id: \.self) { hour in
                        let x = CGFloat(hour) * (geometry.size.width / 24)

                        VStack(alignment: .leading, spacing: 4) {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 1)

                            Text(formatHour(hour))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .offset(x: x)
                    }

                    // Activity blocks
                    ForEach(timelineActivities) { item in
                        let startX = CGFloat(item.startMinutes) / (24.0 * 60.0) * geometry.size.width
                        let width = CGFloat(item.endMinutes - item.startMinutes) / (24.0 * 60.0) * geometry.size.width

                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.category.color)
                            .frame(width: max(width, 2), height: 40)
                            .offset(x: startX, y: 30)
                            .help(item.activity.appName)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var activityList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Sessions")
                .font(.headline)

            ForEach(timelineActivities) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.activity.appName)
                            .font(.body.weight(.medium))

                        HStack(spacing: 8) {
                            Text(formatTime(item.startMinutes))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("-")
                                .foregroundStyle(.tertiary)

                            Text(formatTime(item.endMinutes))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatDuration(item.activity.durationSeconds))
                            .font(.body.weight(.semibold))

                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 8, height: 8)

                            Text(item.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func formatHour(_ hour: Int) -> String {
        if hour == 0 {
            return "12a"
        } else if hour < 12 {
            return "\(hour)a"
        } else if hour == 12 {
            return "12p"
        } else {
            return "\(hour - 12)p"
        }
    }

    private func formatTime(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60

        let period = hour < 12 ? "AM" : "PM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)

        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

private struct TimelineActivity: Identifiable {
    let id = UUID()
    let activity: ActivityLog
    let category: CategoryType
    let startMinutes: Int
    let endMinutes: Int
}
