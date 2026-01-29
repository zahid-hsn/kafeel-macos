import SwiftUI
import Charts
import KafeelCore

struct WeeklyHoursDetailView: View {
    let activities: [ActivityLog]
    @Environment(\.dismiss) private var dismiss

    private var weeklyData: [DayHours] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var weekStart = today
        if let start = calendar.dateInterval(of: .weekOfYear, for: today)?.start {
            weekStart = start
        }

        var data: [DayHours] = []
        let dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        let shortNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        for dayOffset in 0..<7 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }

            let dayStart = calendar.startOfDay(for: dayDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

            let dayActivities = activities.filter { activity in
                activity.startTime >= dayStart && activity.startTime < dayEnd
            }

            let totalSeconds = dayActivities.reduce(0) { $0 + $1.durationSeconds }
            let hours = Double(totalSeconds) / 3600.0

            data.append(DayHours(
                day: dayNames[dayOffset],
                shortDay: shortNames[dayOffset],
                hours: hours,
                isToday: calendar.isDateInToday(dayDate),
                activities: dayActivities
            ))
        }

        return data
    }

    private var totalWeekHours: Double {
        weeklyData.reduce(0) { $0 + $1.hours }
    }

    private var averageHours: Double {
        let daysWithData = weeklyData.filter { $0.hours > 0 }.count
        guard daysWithData > 0 else { return 0 }
        return totalWeekHours / Double(daysWithData)
    }

    private var longestDay: DayHours? {
        weeklyData.max { $0.hours < $1.hours }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    summaryCards
                    largeWeekChart
                    dailyComparison
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Text("Weekly Hours Breakdown")
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
                title: "Total Hours",
                value: String(format: "%.1f", totalWeekHours),
                color: .blue,
                icon: "clock.fill"
            )

            SummaryCard(
                title: "Daily Average",
                value: String(format: "%.1f", averageHours),
                color: .indigo,
                icon: "chart.bar.fill"
            )

            if let longest = longestDay, longest.hours > 0 {
                SummaryCard(
                    title: "Longest Day",
                    value: longest.shortDay,
                    subtitle: String(format: "%.1fh", longest.hours),
                    color: .purple,
                    icon: "star.fill"
                )
            }
        }
    }

    private var largeWeekChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Hours")
                .font(.headline)

            Chart(weeklyData) { item in
                BarMark(
                    x: .value("Day", item.shortDay),
                    y: .value("Hours", item.hours)
                )
                .foregroundStyle(
                    item.isToday ?
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ) :
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .blue.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(6)
            }
            .frame(height: 250)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var dailyComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Day by Day Comparison")
                .font(.headline)

            ForEach(weeklyData) { day in
                dayComparisonRow(for: day)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private func dayComparisonRow(for day: DayHours) -> some View {
        let percentOfMax = longestDay?.hours ?? 1
        let percentage = percentOfMax > 0 ? (day.hours / percentOfMax) * 100 : 0

        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(day.day)
                    .font(.body.weight(.medium))

                HStack(spacing: 4) {
                    Text("\(day.activities.count) activities")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if day.isToday {
                        Text("• Today")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f hours", day.hours))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            HStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(day.isToday ? Color.blue : Color.blue.opacity(0.6))
                                    .frame(width: geometry.size.width * (percentage / 100))
                                Spacer(minLength: 0)
                            }
                        )
                }
                .frame(width: 200, height: 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(day.isToday ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

private struct DayHours: Identifiable {
    let id = UUID()
    let day: String
    let shortDay: String
    let hours: Double
    let isToday: Bool
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
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.body)
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
