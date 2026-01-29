import SwiftUI
import Charts
import KafeelCore

struct CategoryDetailView: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @Environment(\.dismiss) private var dismiss

    private var categoryData: [CategoryData] {
        var productive = 0
        var neutral = 0
        var distracting = 0

        for activity in activities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let duration = activity.durationSeconds

            switch category {
            case .productive:
                productive += duration
            case .neutral:
                neutral += duration
            case .distracting:
                distracting += duration
            }
        }

        let total = productive + neutral + distracting
        guard total > 0 else { return [] }

        return [
            CategoryData(
                id: UUID(),
                category: .productive,
                seconds: productive,
                percentage: Double(productive) / Double(total) * 100
            ),
            CategoryData(
                id: UUID(),
                category: .neutral,
                seconds: neutral,
                percentage: Double(neutral) / Double(total) * 100
            ),
            CategoryData(
                id: UUID(),
                category: .distracting,
                seconds: distracting,
                percentage: Double(distracting) / Double(total) * 100
            ),
        ].filter { $0.seconds > 0 }
    }

    private var appBreakdown: [AppBreakdownItem] {
        var appDurations: [String: (name: String, seconds: Int, category: CategoryType)] = [:]

        for activity in activities {
            let bundleId = activity.appBundleIdentifier
            let category = categories[bundleId] ?? .neutral

            if let existing = appDurations[bundleId] {
                appDurations[bundleId] = (existing.name, existing.seconds + activity.durationSeconds, category)
            } else {
                appDurations[bundleId] = (activity.appName, activity.durationSeconds, category)
            }
        }

        return appDurations.map { bundleId, data in
            AppBreakdownItem(
                bundleId: bundleId,
                name: data.name,
                seconds: data.seconds,
                category: data.category
            )
        }.sorted { $0.seconds > $1.seconds }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    largePieChart
                    categoryBreakdown
                    appList
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Text("Category Breakdown")
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

    private var largePieChart: some View {
        Chart(categoryData) { data in
            SectorMark(
                angle: .value("Time", data.seconds),
                innerRadius: .ratio(0.55),
                angularInset: 3
            )
            .foregroundStyle(categoryGradient(for: data.category))
            .cornerRadius(6)
        }
        .frame(width: 300, height: 300)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time by Category")
                .font(.headline)

            ForEach(categoryData) { data in
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(data.category.color)
                        .frame(width: 4, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.category.displayName)
                            .font(.body.weight(.medium))

                        HStack(spacing: 8) {
                            Text(formatDuration(data.seconds))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Text("•")
                                .foregroundStyle(.tertiary)

                            Text("\(Int(data.percentage))%")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Progress bar
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(data.category.color.opacity(0.2))
                            .overlay(
                                HStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(data.category.color)
                                        .frame(width: geometry.size.width * (data.percentage / 100))
                                    Spacer(minLength: 0)
                                }
                            )
                    }
                    .frame(width: 200, height: 8)
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

    private var appList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("App Breakdown")
                .font(.headline)

            ForEach(appBreakdown.prefix(10)) { item in
                HStack {
                    Circle()
                        .fill(item.category.color)
                        .frame(width: 10, height: 10)

                    Text(item.name)
                        .font(.body)

                    Spacer()

                    Text(formatDuration(item.seconds))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                        )
                }
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
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

    private func categoryGradient(for category: CategoryType) -> LinearGradient {
        let color = category.color
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct AppBreakdownItem: Identifiable {
    let id = UUID()
    let bundleId: String
    let name: String
    let seconds: Int
    let category: CategoryType
}

struct CategoryData: Identifiable, Equatable {
    let id: UUID
    let category: CategoryType
    let seconds: Int
    let percentage: Double

    static func == (lhs: CategoryData, rhs: CategoryData) -> Bool {
        lhs.id == rhs.id
    }
}
