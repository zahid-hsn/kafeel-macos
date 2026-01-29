import SwiftUI
import Charts
import KafeelCore

struct GitActivityDashboardCard: View {
    let commits: [GitActivity]

    @State private var showDetail = false
    @State private var isHovering = false

    private var stats: GitRepoStats {
        GitService.shared.getAggregatedStats(from: commits)
    }

    private var activeReposCount: Int {
        Set(commits.map { $0.repositoryName }).count
    }

    private var todayCommits: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return commits.filter { calendar.isDate($0.date, inSameDayAs: today) }.count
    }

    private var weekCommits: Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return commits.filter { $0.date >= weekAgo }.count
    }

    private var last7DaysData: [DailyCommitData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var data: [DailyCommitData] = []

        for dayOffset in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                let count = commits.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
                data.append(DailyCommitData(date: date, commits: count))
            }
        }
        return data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.title2)
                    .foregroundStyle(.orange)

                Text("Git Activity")
                    .font(.headline)

                Spacer()

                Text("Last 30 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    GitStatItem(
                        value: "\(todayCommits)",
                        label: "Today",
                        color: .orange
                    )

                    GitStatItem(
                        value: "\(weekCommits)",
                        label: "This Week",
                        color: .orange.opacity(0.7)
                    )

                    GitStatItem(
                        value: "\(activeReposCount)",
                        label: "Repos",
                        color: .blue
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 7 Days")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !last7DaysData.isEmpty {
                        Chart(last7DaysData) { item in
                            BarMark(
                                x: .value("Day", item.date, unit: .day),
                                y: .value("Commits", item.commits)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .orange.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(2)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                                    .font(.system(size: 8))
                            }
                        }
                        .chartYAxis(.hidden)
                        .frame(height: 60)
                    } else {
                        Text("No activity")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .frame(height: 60)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            GitDetailView(commits: commits)
        }
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000 {
            return String(format: "%.1fk", Double(num) / 1000.0)
        }
        return "\(num)"
    }
}

private struct DailyCommitData: Identifiable {
    let id = UUID()
    let date: Date
    let commits: Int
}

struct GitStatItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GitActivityDashboardCard(commits: [])
        .padding()
        .frame(width: 600)
}
