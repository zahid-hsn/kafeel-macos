import SwiftUI
import Charts
import KafeelCore

struct ScreenTimeComparison: View {
    let activities: [ActivityLog]
    let timeFilter: TimeFilter

    @State private var isAnimated = false
    @State private var showDetail = false
    @State private var isHovering = false

    private var comparisonData: [ComparisonData] {
        let calendar = Calendar.current
        let now = Date()

        switch timeFilter {
        case .day:
            // Today vs Yesterday
            let todayStart = calendar.startOfDay(for: now)
            let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart)!

            let todayTime = calculateTotalTime(from: todayStart, to: now)
            let yesterdayTime = calculateTotalTime(from: yesterdayStart, to: todayStart)

            return [
                ComparisonData(id: UUID(), label: "Yesterday", seconds: yesterdayTime, type: .previous),
                ComparisonData(id: UUID(), label: "Today", seconds: todayTime, type: .current),
            ]

        case .week:
            // This week vs Last week
            let thisWeekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart)!

            let thisWeekTime = calculateTotalTime(from: thisWeekStart, to: now)
            let lastWeekTime = calculateTotalTime(from: lastWeekStart, to: thisWeekStart)

            return [
                ComparisonData(id: UUID(), label: "Last Week", seconds: lastWeekTime, type: .previous),
                ComparisonData(id: UUID(), label: "This Week", seconds: thisWeekTime, type: .current),
            ]

        case .year:
            // This year vs Last year
            let thisYearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let lastYearStart = calendar.date(byAdding: .year, value: -1, to: thisYearStart)!

            let thisYearTime = calculateTotalTime(from: thisYearStart, to: now)
            let lastYearTime = calculateTotalTime(from: lastYearStart, to: thisYearStart)

            return [
                ComparisonData(id: UUID(), label: "Last Year", seconds: lastYearTime, type: .previous),
                ComparisonData(id: UUID(), label: "This Year", seconds: thisYearTime, type: .current),
            ]
        }
    }

    private var difference: (seconds: Int, isIncrease: Bool) {
        guard comparisonData.count == 2 else { return (0, false) }
        let current = comparisonData[1].seconds
        let previous = comparisonData[0].seconds
        let diff = current - previous
        return (abs(diff), diff > 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Screen Time")
                    .font(.title3.weight(.semibold))

                Text("Comparison with previous period")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if comparisonData.isEmpty || comparisonData.allSatisfy({ $0.seconds == 0 }) {
                emptyState
            } else {
                VStack(spacing: 24) {
                    // Bar chart
                    Chart(comparisonData) { data in
                        BarMark(
                            x: .value("Time", isAnimated ? Double(data.seconds) / 3600.0 : 0),
                            y: .value("Period", data.label)
                        )
                        .foregroundStyle(barGradient(for: data.type))
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let hours = value.as(Double.self) {
                                    Text("\(Int(hours))h")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.secondary.opacity(0.1))
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisValueLabel {
                                if let label = value.as(String.self) {
                                    Text(label)
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                    .frame(height: 120)

                    // Difference indicator
                    differenceView
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .animation(.spring(response: 0.3), value: isHovering)
        .onHover { isHovering = $0 }
        .onTapGesture { showDetail = true }
        .sheet(isPresented: $showDetail) {
            ScreenTimeComparisonDetailView(
                comparisonData: comparisonData,
                difference: difference,
                timeFilter: timeFilter
            )
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
        .onChange(of: activities) { _, _ in
            isAnimated = false
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
    }

    private var differenceView: some View {
        HStack {
            Spacer()

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: difference.isIncrease ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .font(.title3)
                        .foregroundStyle(difference.isIncrease ? .red : .green)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDifference(difference.seconds))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)

                        Text(difference.isIncrease ? "More screen time" : "Less screen time")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(difference.isIncrease ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            difference.isIncrease ? Color.red.opacity(0.2) : Color.green.opacity(0.2),
                            lineWidth: 1
                        )
                )
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No comparison data yet")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func calculateTotalTime(from startDate: Date, to endDate: Date) -> Int {
        activities
            .filter { $0.startTime >= startDate && $0.startTime < endDate }
            .map(\.durationSeconds)
            .reduce(0, +)
    }

    private func formatDifference(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }

    private func barGradient(for type: ComparisonType) -> LinearGradient {
        switch type {
        case .previous:
            return LinearGradient(
                colors: [Color.secondary, Color.secondary.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .current:
            return LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.7)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

struct ComparisonData: Identifiable {
    let id: UUID
    let label: String
    let seconds: Int
    let type: ComparisonType
}

enum ComparisonType {
    case previous
    case current
}

// MARK: - Detail View

struct ScreenTimeComparisonDetailView: View {
    let comparisonData: [ComparisonData]
    let difference: (seconds: Int, isIncrease: Bool)
    let timeFilter: TimeFilter
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Time Comparison")
                        .font(.title2.weight(.bold))

                    Text(periodLabel)
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

            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    if comparisonData.count == 2 {
                        PeriodCard(
                            label: comparisonData[0].label,
                            seconds: comparisonData[0].seconds,
                            color: .secondary
                        )

                        PeriodCard(
                            label: comparisonData[1].label,
                            seconds: comparisonData[1].seconds,
                            color: .blue
                        )
                    }
                }

                Divider()

                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: difference.isIncrease ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(difference.isIncrease ? .red : .green)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(formatDifference(difference.seconds))
                                .font(.title.weight(.bold))

                            Text(difference.isIncrease ? "More screen time" : "Less screen time")
                                .font(.body)
                                .foregroundStyle(.secondary)

                            Text("compared to previous period")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }

                        Spacer()
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill((difference.isIncrease ? Color.red : Color.green).opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                (difference.isIncrease ? Color.red : Color.green).opacity(0.2),
                                lineWidth: 1
                            )
                    )

                    if comparisonData.count == 2 {
                        let percentageChange = calculatePercentageChange()
                        HStack {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("\(abs(percentageChange))%")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(difference.isIncrease ? .red : .green)

                                Text("Percentage change")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                    }
                }

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Insights")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(insights, id: \.self) { insight in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundStyle(.yellow)
                                    .font(.caption)
                                Text(insight)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(32)
        .frame(width: 600, height: 650)
    }

    private var periodLabel: String {
        switch timeFilter {
        case .day: return "Today vs Yesterday"
        case .week: return "This Week vs Last Week"
        case .year: return "This Year vs Last Year"
        }
    }

    private func calculatePercentageChange() -> Int {
        guard comparisonData.count == 2 else { return 0 }
        let current = comparisonData[1].seconds
        let previous = comparisonData[0].seconds
        guard previous > 0 else { return 0 }
        return Int((Double(current - previous) / Double(previous)) * 100)
    }

    private var insights: [String] {
        var result: [String] = []

        if difference.isIncrease {
            result.append("You're spending more time on screen. Consider setting time limits for apps.")
            result.append("Regular breaks can help maintain focus and reduce eye strain.")
        } else {
            result.append("Great job reducing screen time! This helps maintain work-life balance.")
            result.append("Keep up the good habits and continue monitoring your usage.")
        }

        return result
    }

    private func formatDifference(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60

        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            }
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "\(seconds)s"
        }
    }
}

struct PeriodCard: View {
    let label: String
    let seconds: Int
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(formatTime(seconds))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text("Total screen time")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
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

#Preview {
    let now = Date()
    let activities = [
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: now.addingTimeInterval(-7200)),
        ActivityLog(appBundleIdentifier: "com.google.Chrome", appName: "Chrome", startTime: now.addingTimeInterval(-3600)),
        ActivityLog(appBundleIdentifier: "com.apple.Safari", appName: "Safari", startTime: now.addingTimeInterval(-86400 - 5400)),
    ]

    for activity in activities {
        activity.finalize()
    }

    return VStack {
        ScreenTimeComparison(activities: activities, timeFilter: .day)
        ScreenTimeComparison(activities: [], timeFilter: .day)
    }
    .padding()
    .frame(width: 600)
}
