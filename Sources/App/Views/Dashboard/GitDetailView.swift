import SwiftUI
import Charts
import KafeelCore

struct GitDetailView: View {
    let commits: [GitActivity]
    @Environment(\.dismiss) private var dismiss

    private var stats: GitRepoStats {
        GitService.shared.getAggregatedStats(from: commits)
    }

    private var dailyCommits: [DailyCommitData] {
        let calendar = Calendar.current
        var commitsByDay: [Date: Int] = [:]

        for commit in commits {
            let day = calendar.startOfDay(for: commit.date)
            commitsByDay[day, default: 0] += 1
        }

        return commitsByDay.map { date, count in
            DailyCommitData(date: date, commits: count)
        }.sorted { $0.date < $1.date }
    }

    private var recentCommits: [GitActivity] {
        Array(commits.sorted { $0.date > $1.date }.prefix(10))
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    statsCards
                    contributionChart
                    commitList
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Text("Git Activity Details")
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
}

private struct DailyCommitData: Identifiable {
    let id = UUID()
    let date: Date
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
