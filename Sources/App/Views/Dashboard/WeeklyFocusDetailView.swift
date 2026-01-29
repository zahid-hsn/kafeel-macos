import SwiftUI
import Charts
import KafeelCore

struct WeeklyFocusDetailView: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @Environment(\.dismiss) private var dismiss

    private var weeklyScores: [DayScore] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var weekStart = today
        if let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
            weekStart = start
        }

        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        var scores: [DayScore] = []

        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let dayActivities = activities.filter { activity in
                activity.startTime >= dayStart && activity.startTime < dayEnd
            }

            let score = calculateFocusScore(for: dayActivities)
            let isToday = calendar.isDateInToday(dayDate)
            let isFuture = dayDate > today

            scores.append(DayScore(
                day: dayNames[dayOffset],
                shortDay: String(dayNames[dayOffset].prefix(3)),
                score: score,
                isToday: isToday,
                isFuture: isFuture,
                date: dayDate,
                activities: dayActivities
            ))
        }

        return scores
    }

    private var bestDay: DayScore? {
        weeklyScores.filter { !$0.isFuture }.max { $0.score < $1.score }
    }

    private var worstDay: DayScore? {
        weeklyScores.filter { !$0.isFuture && $0.score > 0 }.min { $0.score < $1.score }
    }

    private var averageScore: Double {
        let validScores = weeklyScores.filter { !$0.isFuture && $0.score > 0 }
        guard !validScores.isEmpty else { return 0 }
        return validScores.map(\.score).reduce(0, +) / Double(validScores.count)
    }

    private func calculateFocusScore(for activities: [ActivityLog]) -> Double {
        guard !activities.isEmpty else { return 0 }

        var totalWeightedTime: Double = 0
        var totalTime: Double = 0

        for activity in activities {
            let duration = Double(activity.durationSeconds)
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let weight = category.weight

            totalWeightedTime += duration * weight
            totalTime += duration
        }

        return totalTime > 0 ? (totalWeightedTime / totalTime) * 100 : 0
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    summaryCards
                    largeWeekChart
                    dailyBreakdown
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Text("Weekly Focus Breakdown")
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

    private var summaryCards: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "Average Score",
                value: "\(Int(averageScore))",
                color: scoreColor(averageScore),
                icon: "chart.line.uptrend.xyaxis"
            )

            if let best = bestDay {
                SummaryCard(
                    title: "Best Day",
                    value: best.shortDay,
                    subtitle: "\(Int(best.score))",
                    color: .green,
                    icon: "trophy.fill"
                )
            }

            if let worst = worstDay {
                SummaryCard(
                    title: "Needs Work",
                    value: worst.shortDay,
                    subtitle: "\(Int(worst.score))",
                    color: .orange,
                    icon: "flag.fill"
                )
            }
        }
    }

    private var largeWeekChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Scores")
                .font(.headline)

            Chart(weeklyScores) { dayScore in
                if !dayScore.isFuture {
                    BarMark(
                        x: .value("Day", dayScore.shortDay),
                        y: .value("Score", dayScore.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [scoreColor(dayScore.score), scoreColor(dayScore.score).opacity(0.6)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(6)
                }
            }
            .chartYScale(domain: 0...100)
            .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var dailyBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Day by Day")
                .font(.headline)

            ForEach(weeklyScores) { dayScore in
                if !dayScore.isFuture {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dayScore.day)
                                .font(.body.weight(.medium))

                            Text("\(dayScore.activities.count) activities")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        ZStack {
                            Circle()
                                .stroke(scoreColor(dayScore.score).opacity(0.2), lineWidth: 6)
                                .frame(width: 60, height: 60)

                            Circle()
                                .trim(from: 0, to: dayScore.score / 100)
                                .stroke(scoreColor(dayScore.score), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .frame(width: 60, height: 60)
                                .rotationEffect(.degrees(-90))

                            Text("\(Int(dayScore.score))")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(dayScore.isToday ? scoreColor(dayScore.score).opacity(0.3) : Color.clear, lineWidth: 2)
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

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }
}

private struct DayScore: Identifiable {
    let id = UUID()
    let day: String
    let shortDay: String
    let score: Double
    let isToday: Bool
    let isFuture: Bool
    let date: Date
    let activities: [ActivityLog]
}

private struct SummaryCard: View {
    let title: String
    let value: String
    var subtitle: String?
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

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}
