import SwiftUI
import Charts
import KafeelCore

struct HourlyDetailView: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]
    @Environment(\.dismiss) private var dismiss

    private var hourlyData: [HourActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var data: [HourActivity] = []

        for hour in 0..<24 {
            guard let hourStart = calendar.date(byAdding: .hour, value: hour, to: today),
                  let hourEnd = calendar.date(byAdding: .hour, value: hour + 1, to: today) else {
                continue
            }

            let hourActivities = activities.filter { activity in
                let activityEnd = activity.startTime.addingTimeInterval(TimeInterval(activity.durationSeconds))
                return activity.startTime < hourEnd && activityEnd > hourStart
            }

            let totalMinutes = hourActivities.reduce(0) { $0 + $1.durationSeconds } / 60

            var categoryMinutes: [CategoryType: Int] = [:]
            for activity in hourActivities {
                let category = categories[activity.appBundleIdentifier] ?? .neutral
                let minutes = activity.durationSeconds / 60
                categoryMinutes[category, default: 0] += minutes
            }

            let label = formatHourLabel(hour)

            data.append(HourActivity(
                hour: hour,
                label: label,
                minutes: totalMinutes,
                productiveMinutes: categoryMinutes[.productive] ?? 0,
                neutralMinutes: categoryMinutes[.neutral] ?? 0,
                distractingMinutes: categoryMinutes[.distracting] ?? 0,
                activities: hourActivities
            ))
        }

        return data
    }

    private var peakHours: [HourActivity] {
        hourlyData.filter { $0.minutes > 0 }
            .sorted { $0.minutes > $1.minutes }
            .prefix(3)
            .map { $0 }
    }

    private var totalActiveHours: Int {
        hourlyData.filter { $0.minutes >= 5 }.count
    }

    private func formatHourLabel(_ hour: Int) -> String {
        if hour == 0 {
            return "12 AM"
        } else if hour < 12 {
            return "\(hour) AM"
        } else if hour == 12 {
            return "12 PM"
        } else {
            return "\(hour - 12) PM"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            ScrollView {
                VStack(spacing: 24) {
                    summaryCards
                    fullDayChart
                    peakHoursSection
                    hourlyBreakdown
                }
                .padding(24)
            }
        }
        .frame(width: 800, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var headerView: some View {
        HStack {
            Text("24-Hour Activity Breakdown")
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
                title: "Active Hours",
                value: "\(totalActiveHours)",
                color: .blue,
                icon: "clock.fill"
            )

            if let peak = peakHours.first {
                SummaryCard(
                    title: "Peak Hour",
                    value: peak.label,
                    subtitle: "\(peak.minutes)m",
                    color: .cyan,
                    icon: "chart.line.uptrend.xyaxis"
                )
            }

            SummaryCard(
                title: "Total Time",
                value: formatTotalTime(),
                color: .indigo,
                icon: "timer"
            )
        }
    }

    private var fullDayChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity Throughout the Day")
                .font(.headline)

            Chart(hourlyData) { item in
                BarMark(
                    x: .value("Hour", item.label),
                    y: .value("Minutes", item.minutes)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: 3)) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge)
                .fill(.ultraThinMaterial)
        )
    }

    private var peakHoursSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Peak Productivity Hours")
                .font(.headline)

            ForEach(peakHours) { hour in
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)

                    Text(hour.label)
                        .font(.body.weight(.medium))

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(hour.minutes) min")
                            .font(.body.weight(.semibold))

                        HStack(spacing: 8) {
                            if hour.productiveMinutes > 0 {
                                Text("\(hour.productiveMinutes)m productive")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                            if hour.distractingMinutes > 0 {
                                Text("\(hour.distractingMinutes)m distracted")
                                    .font(.caption2)
                                    .foregroundStyle(.red)
                            }
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

    private var hourlyBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hour by Hour")
                .font(.headline)

            ForEach(hourlyData.filter { $0.minutes > 0 }) { hour in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(hour.label)
                            .font(.body.weight(.medium))

                        Spacer()

                        Text("\(hour.minutes) minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Category breakdown bar
                    if hour.productiveMinutes + hour.neutralMinutes + hour.distractingMinutes > 0 {
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                if hour.productiveMinutes > 0 {
                                    Rectangle()
                                        .fill(Color.green)
                                        .frame(width: geometry.size.width * Double(hour.productiveMinutes) / Double(hour.minutes))
                                }
                                if hour.neutralMinutes > 0 {
                                    Rectangle()
                                        .fill(Color.gray)
                                        .frame(width: geometry.size.width * Double(hour.neutralMinutes) / Double(hour.minutes))
                                }
                                if hour.distractingMinutes > 0 {
                                    Rectangle()
                                        .fill(Color.red)
                                        .frame(width: geometry.size.width * Double(hour.distractingMinutes) / Double(hour.minutes))
                                }
                            }
                            .cornerRadius(4)
                        }
                        .frame(height: 8)
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

    private func formatTotalTime() -> String {
        let totalMinutes = hourlyData.reduce(0) { $0 + $1.minutes }
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

private struct HourActivity: Identifiable {
    let id = UUID()
    let hour: Int
    let label: String
    let minutes: Int
    let productiveMinutes: Int
    let neutralMinutes: Int
    let distractingMinutes: Int
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
