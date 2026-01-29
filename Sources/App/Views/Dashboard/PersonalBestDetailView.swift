import SwiftUI
import SwiftData
import Charts
import KafeelCore

struct PersonalBestDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let todayScore: Double
    let records: [PersonalRecord]
    let streak: Streak

    @Query(sort: \DailyScore.date, order: .reverse) private var dailyScores: [DailyScore]

    private var sortedRecords: [PersonalRecord] {
        records.sorted { $0.achievedAt > $1.achievedAt }
    }

    private var last30DaysScores: [DailyScore] {
        Array(dailyScores.prefix(30).reversed())
    }

    private var bestDayRecord: PersonalRecord? {
        records.first { $0.category == .bestDayScore }
    }

    private var progressToRecords: [(record: PersonalRecord, progress: Double)] {
        records.compactMap { record in
            let currentValue: Double
            switch record.category {
            case .bestDayScore:
                currentValue = todayScore
            case .longestStreak:
                currentValue = Double(streak.currentStreakDays)
            case .highestXPDay:
                currentValue = Double(dailyScores.first?.xpEarned ?? 0)
            default:
                return nil
            }

            guard record.value > 0 else { return nil }
            let progress = (currentValue / record.value) * 100
            return (record, min(progress, 100))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Personal Records")
                    .font(.title.weight(.bold))

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .hoverEffect()
            }
            .padding(24)

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Trophy Display
                    trophyDisplay

                    // All Records
                    allRecordsSection

                    // Record History
                    recordHistorySection

                    // Progress to Beating Records
                    progressSection

                    // Comparison Chart
                    comparisonChart
                }
                .padding(24)
            }
        }
        .frame(width: 700, height: 600)
        .background(.ultraThickMaterial)
    }

    private var trophyDisplay: some View {
        VStack(spacing: 20) {
            // Trophy Animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.4),
                                Color.yellow.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)

                // Trophy Icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .frame(height: 200)

            VStack(spacing: 8) {
                Text("\(records.count)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.orange)

                Text("Personal Records")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .modernCard()
    }

    private var allRecordsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Records")
                .font(.title2.weight(.semibold))

            if sortedRecords.isEmpty {
                Text("No records set yet. Keep working to set your first record!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                VStack(spacing: 12) {
                    ForEach(sortedRecords, id: \.categoryRawValue) { record in
                        RecordRow(record: record)
                    }
                }
            }
        }
        .modernCard()
    }

    private var recordHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(.blue)
                Text("Record History")
                    .font(.title2.weight(.semibold))
            }

            VStack(spacing: 12) {
                ForEach(sortedRecords.filter { $0.improvementCount > 0 }.prefix(5), id: \.categoryRawValue) { record in
                    HStack {
                        Image(systemName: record.category.icon)
                            .foregroundStyle(.orange)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(record.category.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)

                            HStack(spacing: 8) {
                                Text("Set \(formatDate(record.achievedAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if record.improvementCount > 1 {
                                    Text("•")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)

                                    Text("Improved \(record.improvementCount)x")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(record.formattedValue)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)

                            if let improvement = record.formattedImprovement {
                                Text(improvement)
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }

            if sortedRecords.allSatisfy({ $0.improvementCount == 0 }) {
                Text("Keep going to improve your records!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .modernCard()
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundStyle(.blue)
                Text("Progress Towards Records")
                    .font(.title2.weight(.semibold))
            }

            if progressToRecords.isEmpty {
                Text("No comparable records available today")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                VStack(spacing: 16) {
                    ForEach(progressToRecords, id: \.record.categoryRawValue) { item in
                        ProgressToRecordRow(
                            record: item.record,
                            progress: item.progress
                        )
                    }
                }
            }
        }
        .modernCard()
    }

    private var comparisonChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Score History (Last 30 Days)")
                .font(.title2.weight(.semibold))

            if last30DaysScores.isEmpty {
                Text("Not enough data to show chart")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                Chart {
                    // Score line
                    ForEach(last30DaysScores) { dayScore in
                        LineMark(
                            x: .value("Date", dayScore.date, unit: .day),
                            y: .value("Score", dayScore.focusScore)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        AreaMark(
                            x: .value("Date", dayScore.date, unit: .day),
                            y: .value("Score", dayScore.focusScore)
                        )
                        .foregroundStyle(.blue.opacity(0.1))
                    }

                    // Best day line
                    if let bestDay = bestDayRecord {
                        RuleMark(y: .value("Best", bestDay.value))
                            .foregroundStyle(.orange.opacity(0.5))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                            .annotation(position: .top, alignment: .trailing) {
                                Text("Best: \(Int(bestDay.value))")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                    .padding(4)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                    }
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { _ in
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .frame(height: 200)
            }
        }
        .modernCard()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Helper Components

struct RecordRow: View {
    let record: PersonalRecord

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: record.category.icon)
                    .foregroundStyle(.orange)
                    .font(.body)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(record.category.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text("Set")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(formatRecordDate(record.achievedAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let details = record.details {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Text(details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 4) {
                Text(record.formattedValue)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.orange)

                if !record.category.unit.isEmpty {
                    Text(record.category.unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }

    private func formatRecordDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct ProgressToRecordRow: View {
    let record: PersonalRecord
    let progress: Double

    private var statusColor: Color {
        if progress >= 100 { return .green }
        if progress >= 85 { return .orange }
        return .blue
    }

    private var statusIcon: String {
        if progress >= 100 { return "checkmark.circle.fill" }
        if progress >= 85 { return "bolt.fill" }
        return "arrow.up.circle.fill"
    }

    private var statusText: String {
        if progress >= 100 { return "New Record!" }
        if progress >= 85 { return "Almost there!" }
        return "\(Int(progress))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: record.category.icon)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)

                Text(record.category.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.caption)
                    Text(statusText)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .clipShape(Capsule())
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(statusColor)
                        .frame(
                            width: min(geometry.size.width * (progress / 100), geometry.size.width),
                            height: 8
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background(statusColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var records = {
        let records = [
            PersonalRecord(category: .bestDayScore, value: 85),
            PersonalRecord(category: .longestFocusSession, value: 10800),
            PersonalRecord(category: .highestXPDay, value: 1500),
            PersonalRecord(category: .longestStreak, value: 25),
            PersonalRecord(category: .bestWeekScore, value: 78)
        ]
        records[0].improvementCount = 3
        records[0].previousValue = 75
        records[1].improvementCount = 2
        return records
    }()

    @Previewable @State var streak = {
        let streak = Streak()
        streak.currentStreakDays = 18
        streak.longestStreakDays = 25
        return streak
    }()

    return PersonalBestDetailView(
        todayScore: 82,
        records: records,
        streak: streak
    )
}
