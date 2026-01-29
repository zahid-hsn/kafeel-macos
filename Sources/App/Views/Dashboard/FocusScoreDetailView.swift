import SwiftUI
import SwiftData
import Charts
import KafeelCore

struct FocusScoreDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let score: Double
    let productiveSeconds: Int
    let distractingSeconds: Int
    let neutralSeconds: Int
    let totalSeconds: Int

    @State private var animatedScore: Double = 0
    @Query(sort: \DailyScore.date, order: .reverse) private var dailyScores: [DailyScore]

    private var last7DaysScores: [DailyScore] {
        Array(dailyScores.prefix(7).reversed())
    }

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    private var scoreLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Needs Work"
        default: return "Low"
        }
    }

    private var scoreGradient: LinearGradient {
        switch score {
        case 80...100: return LinearGradient(
            colors: [Color.green, Color.mint],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case 60..<80: return LinearGradient(
            colors: [Color.blue, Color.cyan],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case 40..<60: return LinearGradient(
            colors: [Color.yellow, Color.orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        case 20..<40: return LinearGradient(
            colors: [Color.orange, Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        default: return LinearGradient(
            colors: [Color.red, Color.pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        }
    }

    private var personalBest: Double {
        dailyScores.map { $0.focusScore }.max() ?? score
    }

    private var productivePercentage: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(productiveSeconds) / Double(totalSeconds) * 100
    }

    private var distractingPercentage: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(distractingSeconds) / Double(totalSeconds) * 100
    }

    private var neutralPercentage: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(neutralSeconds) / Double(totalSeconds) * 100
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Focus Score Details")
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
                    // Large Score Display
                    scoreDisplay

                    // Breakdown
                    breakdownSection

                    // Trend Chart
                    trendChart

                    // Tips
                    tipsSection

                    // Comparison
                    comparisonSection
                }
                .padding(24)
            }
        }
        .frame(width: 700, height: 600)
        .background(.ultraThickMaterial)
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.7).delay(0.1)) {
                animatedScore = score
            }
        }
    }

    private var scoreDisplay: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background circle
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 20)
                    .frame(width: 200, height: 200)

                // Animated progress circle
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(scoreGradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.2, dampingFraction: 0.7), value: animatedScore)

                // Center content
                VStack(spacing: 8) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText(value: animatedScore))

                    Text(scoreLabel)
                        .font(.title3)
                        .foregroundStyle(scoreColor.opacity(0.8))
                }
            }

            Text("Today's Focus Score")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .modernCard()
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time Breakdown")
                .font(.title2.weight(.semibold))

            VStack(spacing: 12) {
                BreakdownRow(
                    label: "Productive",
                    percentage: productivePercentage,
                    color: .green,
                    duration: formatDuration(productiveSeconds)
                )

                BreakdownRow(
                    label: "Neutral",
                    percentage: neutralPercentage,
                    color: .gray,
                    duration: formatDuration(neutralSeconds)
                )

                BreakdownRow(
                    label: "Distracting",
                    percentage: distractingPercentage,
                    color: .red,
                    duration: formatDuration(distractingSeconds)
                )
            }
        }
        .modernCard()
    }

    private var trendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("7-Day Trend")
                .font(.title2.weight(.semibold))

            if last7DaysScores.isEmpty {
                Text("Not enough data to show trend")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                Chart(last7DaysScores) { dayScore in
                    LineMark(
                        x: .value("Date", dayScore.date, unit: .day),
                        y: .value("Score", dayScore.focusScore)
                    )
                    .foregroundStyle(scoreGradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    AreaMark(
                        x: .value("Date", dayScore.date, unit: .day),
                        y: .value("Score", dayScore.focusScore)
                    )
                    .foregroundStyle(scoreGradient.opacity(0.2))

                    PointMark(
                        x: .value("Date", dayScore.date, unit: .day),
                        y: .value("Score", dayScore.focusScore)
                    )
                    .foregroundStyle(scoreColor)
                    .symbol(Circle())
                    .symbolSize(60)
                }
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .frame(height: 200)
            }
        }
        .modernCard()
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Tips to Improve")
                    .font(.title2.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(tipsForScore, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.body)

                        Text(tip)
                            .font(.body)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .modernCard()
    }

    private var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison")
                .font(.title2.weight(.semibold))

            VStack(spacing: 16) {
                ComparisonRow(
                    label: "Today",
                    value: score,
                    icon: "calendar",
                    color: scoreColor
                )

                ComparisonRow(
                    label: "Personal Best",
                    value: personalBest,
                    icon: "trophy.fill",
                    color: .orange
                )

                if personalBest > 0 {
                    let percentage = (score / personalBest) * 100
                    HStack {
                        Text("You're at \(Int(percentage))% of your personal best")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        if score >= personalBest {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("New Record!")
                                    .font(.caption.weight(.semibold))
                            }
                            .foregroundStyle(.yellow)
                        }
                    }
                }
            }
        }
        .modernCard()
    }

    private var tipsForScore: [String] {
        switch score {
        case 80...100:
            return [
                "Excellent work! Maintain your productive habits.",
                "Consider sharing your workflow with the team.",
                "Take regular breaks to sustain this performance."
            ]
        case 60..<80:
            return [
                "Good progress! Try minimizing distractions during peak hours.",
                "Use Focus mode to block distracting apps.",
                "Set specific goals for deep work sessions."
            ]
        case 40..<60:
            return [
                "Identify your biggest time drains and limit them.",
                "Schedule dedicated focus time blocks.",
                "Use the Pomodoro technique: 25 min work, 5 min break.",
                "Turn off notifications during important tasks."
            ]
        case 20..<40:
            return [
                "Start with small wins: aim for one productive hour.",
                "Block distracting websites during work hours.",
                "Create a distraction-free workspace.",
                "Review your daily schedule and prioritize tasks."
            ]
        default:
            return [
                "Begin with a clear plan for the day.",
                "Set a timer and commit to focused work.",
                "Eliminate the biggest distraction first.",
                "Consider using website blockers.",
                "Talk to a colleague about accountability."
            ]
        }
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
}

// MARK: - Helper Components

struct BreakdownRow: View {
    let label: String
    let percentage: Double
    let color: Color
    let duration: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(duration)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("(\(Int(percentage))%)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(color)
                        .frame(
                            width: geometry.size.width * (percentage / 100),
                            height: 8
                        )
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ComparisonRow: View {
    let label: String
    let value: Double
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(label)
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()

            Text(String(format: "%.0f", value))
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
        }
        .padding(12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    FocusScoreDetailView(
        score: 82.5,
        productiveSeconds: 18000,
        distractingSeconds: 3600,
        neutralSeconds: 7200,
        totalSeconds: 28800
    )
}
