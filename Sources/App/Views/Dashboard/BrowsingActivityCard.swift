import SwiftUI
import Charts
import KafeelCore

struct BrowsingActivityCard: View {
    let activities: [BrowsingActivity]

    @State private var showDetail = false
    @State private var isHovering = false

    private var hasPermission: Bool {
        let permissions = BrowserHistoryService.shared.checkPermissions()
        return permissions.safari || permissions.chrome
    }

    private var categoryStats: [CategoryStat] {
        var stats: [URLCategory: Int] = [:]
        for activity in activities {
            stats[activity.category, default: 0] += 1
        }
        return stats.map { CategoryStat(category: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private var topCategory: URLCategory? {
        categoryStats.first?.category
    }

    private var topDomain: String? {
        BrowserHistoryService.shared.getTopDomains(from: activities, limit: 1).first?.domain
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "safari.fill")
                    .foregroundStyle(.blue)
                Text("Browsing Activity")
                    .font(.headline)
                Spacer()
            }

            if activities.isEmpty {
                emptyStateView
            } else {
                contentView
            }
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
            BrowsingActivityDetailView(activities: activities)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: hasPermission ? "clock" : "lock.shield.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text(hasPermission ? "No Browsing Data" : "Permission Required")
                .font(.title3.weight(.medium))
                .foregroundStyle(.primary)

            Text(hasPermission
                ? "Browse the web to see activity here"
                : "Grant Full Disk Access in System Settings > Privacy & Security")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stats Row
            HStack(spacing: 20) {
                BrowsingStatItem(
                    icon: "globe",
                    value: "\(activities.count)",
                    label: "Sites"
                )

                if let topCategory = topCategory {
                    BrowsingStatItem(
                        icon: topCategory.icon,
                        value: topCategory.displayName,
                        label: "Top Category"
                    )
                }

                if let topDomain = topDomain {
                    BrowsingStatItem(
                        icon: "star.fill",
                        value: topDomain,
                        label: "Most Visited"
                    )
                }
            }

            // Mini Pie Chart
            if !categoryStats.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category Breakdown")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Chart(categoryStats) { stat in
                        SectorMark(
                            angle: .value("Count", stat.count),
                            innerRadius: .ratio(0.618),
                            angularInset: 1.5
                        )
                        .foregroundStyle(stat.category.color)
                    }
                    .frame(height: 100)

                    // Legend
                    HStack(spacing: 12) {
                        ForEach(categoryStats.prefix(4)) { stat in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(stat.category.color)
                                    .frame(width: 8, height: 8)
                                Text(stat.category.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct BrowsingStatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CategoryStat: Identifiable {
    let id = UUID()
    let category: URLCategory
    let count: Int
}

// MARK: - Detail View

struct BrowsingActivityDetailView: View {
    let activities: [BrowsingActivity]

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: URLCategory?

    private var filteredActivities: [BrowsingActivity] {
        var filtered = activities

        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.domain.localizedCaseInsensitiveContains(searchText) ||
                $0.url.localizedCaseInsensitiveContains(searchText)
            }
        }

        return filtered
    }

    private var categoryStats: [URLCategory: Int] {
        BrowserHistoryService.shared.getCategoryStats(from: activities)
    }

    private var topDomains: [(domain: String, count: Int)] {
        BrowserHistoryService.shared.getTopDomains(from: activities, limit: 10)
    }

    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Image(systemName: "safari.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Browsing Activity")
                        .font(.title2.weight(.bold))

                    Text("\(activities.count) sites visited")
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

            if activities.isEmpty {
                emptyDetailState
            } else {
                detailContent
            }
        }
        .padding(32)
        .frame(width: 800, height: 700)
    }

    private var emptyDetailState: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("No browsing data available")
                .font(.title3.weight(.semibold))

            Text("Make sure Safari or Chrome has Full Disk Access in System Settings")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var detailContent: some View {
        VStack(spacing: 20) {
            // Category Stats
            HStack(spacing: 12) {
                ForEach(URLCategory.allCases, id: \.self) { category in
                    if let count = categoryStats[category], count > 0 {
                        Button {
                            selectedCategory = selectedCategory == category ? nil : category
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                        .font(.caption)
                                    Text("\(count)")
                                        .font(.headline)
                                }
                                .foregroundStyle(selectedCategory == category ? .white : category.color)

                                Text(category.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(selectedCategory == category ? .white : .secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(selectedCategory == category ? category.color : category.color.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search sites...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.quaternary)
            )

            // Content Tabs
            HStack {
                TabButton(title: "Recent", icon: "clock", isSelected: true)
                TabButton(title: "Top Domains", icon: "star.fill", isSelected: false)
            }

            // Activity List
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredActivities.prefix(100)) { activity in
                        BrowsingActivityRow(activity: activity)
                    }
                }
            }
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .font(.subheadline.weight(isSelected ? .semibold : .regular))
        .foregroundStyle(isSelected ? .primary : .secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary.opacity(isSelected ? 1.0 : 0.0))
        )
    }
}

struct BrowsingActivityRow: View {
    let activity: BrowsingActivity

    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            Image(systemName: activity.category.icon)
                .font(.body)
                .foregroundStyle(activity.category.color)
                .frame(width: 24)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(activity.domain)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(activity.timeAgo)
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    if activity.browser != "Safari" {
                        Text("•")
                            .foregroundStyle(.tertiary)

                        Text(activity.browser)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // Category Badge
            Text(activity.category.displayName)
                .font(.caption2)
                .foregroundStyle(activity.category.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(activity.category.color.opacity(0.15))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.quaternary.opacity(0.5))
        )
    }
}

#Preview {
    BrowsingActivityCard(activities: [
        BrowsingActivity(
            url: "https://github.com/apple/swift",
            title: "Swift Programming Language - GitHub",
            visitTime: Date().addingTimeInterval(-3600),
            durationSeconds: 120,
            browser: "Safari",
            category: .work
        ),
        BrowsingActivity(
            url: "https://twitter.com/home",
            title: "Twitter Home",
            visitTime: Date().addingTimeInterval(-7200),
            durationSeconds: 300,
            browser: "Safari",
            category: .social
        ),
        BrowsingActivity(
            url: "https://youtube.com/watch?v=abc",
            title: "Cool Video - YouTube",
            visitTime: Date().addingTimeInterval(-10800),
            durationSeconds: 600,
            browser: "Chrome",
            category: .entertainment
        ),
    ])
        .padding()
        .frame(width: 400)
}
