import SwiftUI
import Charts
import KafeelCore

struct GitDetailView: View {
    let commits: [GitActivity]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRepository: String = "All Repositories"

    private var repositories: [String] {
        let repos = Set(commits.map { $0.repositoryName }).sorted()
        return ["All Repositories"] + repos
    }

    private var filteredCommits: [GitActivity] {
        if selectedRepository == "All Repositories" {
            return commits
        }
        return commits.filter { $0.repositoryName == selectedRepository }
    }

    private var stats: GitRepoStats {
        GitService.shared.getAggregatedStats(from: filteredCommits)
    }

    private var dailyCommits: [DailyCommitData] {
        let calendar = Calendar.current
        var commitsByDay: [Date: Int] = [:]

        for commit in filteredCommits {
            let day = calendar.startOfDay(for: commit.date)
            commitsByDay[day, default: 0] += 1
        }

        return commitsByDay.map { date, count in
            DailyCommitData(date: date, commits: count)
        }.sorted { $0.date < $1.date }
    }

    private var recentCommits: [GitActivity] {
        Array(filteredCommits.sorted { $0.date > $1.date }.prefix(10))
    }

    private var repositoryBreakdown: [RepoData] {
        var repoCommits: [String: Int] = [:]
        for commit in commits {
            repoCommits[commit.repositoryName, default: 0] += 1
        }
        return repoCommits.map { name, count in
            RepoData(name: name, commits: count)
        }.sorted { $0.commits > $1.commits }
    }

    private var heatmapData: [HeatmapData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [HeatmapData] = []

        for weekOffset in (0..<12).reversed() {
            for dayOffset in 0..<7 {
                if let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
                   let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                    let count = filteredCommits.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
                    data.append(HeatmapData(date: date, commits: count, week: weekOffset, day: dayOffset))
                }
            }
        }
        return data
    }

    private var hourlyDistribution: [GitHourData] {
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]

        for commit in filteredCommits {
            let hour = calendar.component(.hour, from: commit.date)
            hourCounts[hour, default: 0] += 1
        }

        return (0..<24).map { hour in
            GitHourData(hour: hour, commits: hourCounts[hour, default: 0])
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    statsCards

                    HStack(spacing: 16) {
                        contributionChart
                        repositoryPieChart
                    }

                    commitHeatmap
                    timeOfDayChart
                    commitList
                }
                .padding(24)
            }
        }
        .frame(width: 1000, height: 700)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Text("Git Activity Details")
                .font(.title2.weight(.semibold))

            Spacer()

            Picker("Repository", selection: $selectedRepository) {
                ForEach(repositories, id: \.self) { repo in
                    Text(repo).tag(repo)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 200)

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

    private var statsCards: some View {
        HStack(spacing: 16) {
            GitStatCard(
                title: "Total Commits",
                value: "\(stats.totalCommits)",
                color: .orange,
                icon: "checkmark.circle.fill"
            )

            GitStatCard(
                title: "Lines Added",
                value: formatNumber(stats.totalAdditions),
                color: .green,
                icon: "plus.circle.fill"
            )

            GitStatCard(
                title: "Lines Removed",
                value: formatNumber(stats.totalDeletions),
                color: .red,
                icon: "minus.circle.fill"
            )

            GitStatCard(
                title: "Files Changed",
                value: "\(stats.filesChanged)",
                color: .blue,
                icon: "doc.circle.fill"
            )
        }
    }

    private var contributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contribution Activity")
                .font(.headline)

            if !dailyCommits.isEmpty {
                Chart {
                    ForEach(dailyCommits) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Commits", item.commits)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .orange.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
            } else {
                Text("No commit data available")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var repositoryPieChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Repository Breakdown")
                .font(.headline)

            if !repositoryBreakdown.isEmpty && repositoryBreakdown.count > 1 {
                Chart(repositoryBreakdown.prefix(5)) { item in
                    SectorMark(
                        angle: .value("Commits", item.commits),
                        innerRadius: .ratio(0.5),
                        angularInset: 2.0
                    )
                    .foregroundStyle(by: .value("Repository", item.name))
                }
                .chartLegend(position: .bottom, alignment: .leading, spacing: 8)
                .frame(height: 200)
            } else {
                Text("Single repository")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var commitHeatmap: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Commit Heatmap (Last 12 Weeks)")
                .font(.headline)

            if !heatmapData.isEmpty {
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text("")
                            .font(.system(size: 8))
                            .frame(width: 20)

                        ForEach(0..<12, id: \.self) { week in
                            if week % 2 == 0 {
                                Text("\(12 - week)w")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.secondary)
                                    .frame(width: 12)
                            } else {
                                Text("")
                                    .frame(width: 12)
                            }
                        }
                    }

                    ForEach(0..<7, id: \.self) { day in
                        HStack(spacing: 2) {
                            Text(dayLabel(day))
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                                .frame(width: 20, alignment: .leading)

                            ForEach(heatmapData.filter { $0.day == day }) { data in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(heatmapColor(for: data.commits))
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No commit data available")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var timeOfDayChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time of Day Distribution")
                .font(.headline)

            if !filteredCommits.isEmpty {
                Chart(hourlyDistribution) { item in
                    BarMark(
                        x: .value("Hour", item.hour),
                        y: .value("Commits", item.commits)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(2)
                }
                .chartXAxis {
                    AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                        if let hour = value.as(Int.self) {
                            AxisValueLabel {
                                Text(timeLabel(hour))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 150)
            } else {
                Text("No commit data available")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var commitList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Commits")
                .font(.headline)

            if recentCommits.isEmpty {
                Text("No commits found")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(recentCommits) { commit in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(commit.shortHash)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.orange)

                            Spacer()

                            Text(formatDate(commit.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(commit.message)
                            .font(.body)
                            .lineLimit(2)

                        HStack(spacing: 12) {
                            if commit.additions > 0 {
                                Label("\(commit.additions)", systemImage: "plus")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }

                            if commit.deletions > 0 {
                                Label("\(commit.deletions)", systemImage: "minus")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }

                            if commit.filesChanged > 0 {
                                Label("\(commit.filesChanged) files", systemImage: "doc")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        if !commit.repositoryName.isEmpty {
                            Text(commit.repositoryName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                )
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fk", Double(num) / 1000.0)
        }
        return "\(num)"
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func dayLabel(_ day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[day]
    }

    private func timeLabel(_ hour: Int) -> String {
        if hour == 0 { return "12am" }
        if hour < 12 { return "\(hour)am" }
        if hour == 12 { return "12pm" }
        return "\(hour - 12)pm"
    }

    private func heatmapColor(for commits: Int) -> Color {
        if commits == 0 {
            return Color(nsColor: .controlBackgroundColor)
        } else if commits <= 2 {
            return .orange.opacity(0.3)
        } else if commits <= 5 {
            return .orange.opacity(0.5)
        } else if commits <= 10 {
            return .orange.opacity(0.7)
        } else {
            return .orange
        }
    }
}

private struct DailyCommitData: Identifiable {
    let id = UUID()
    let date: Date
    let commits: Int
}

private struct RepoData: Identifiable {
    let id = UUID()
    let name: String
    let commits: Int
}

private struct HeatmapData: Identifiable {
    let id = UUID()
    let date: Date
    let commits: Int
    let week: Int
    let day: Int
}

private struct GitHourData: Identifiable {
    let id = UUID()
    let hour: Int
    let commits: Int
}

private struct GitStatCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}
