import SwiftUI
import SwiftData
import Charts
import KafeelCore

struct StreakDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let streak: Streak

    @State private var animatedStreakDays: Int = 0
    @State private var showFlame = false
    @Query(sort: \DailyScore.date, order: .reverse) private var dailyScores: [DailyScore]

    private var last30Days: [DailyScore] {
        Array(dailyScores.prefix(30).reversed())
    }

    private var streakColor: Color {
        streak.isActive ? .green : .gray
    }

    private var flameGradient: LinearGradient {
        LinearGradient(
            colors: [Color.orange, Color.red, Color.yellow],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    private var milestones: [(days: Int, reached: Bool, shields: Int, xp: Int)] {
        [
            (7, streak.reached7Days, 1, 500),
            (30, streak.reached30Days, 2, 2000),
            (100, streak.reached100Days, 3, 10000)
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Streak Details")
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
                    // Large Streak Display
                    streakDisplay

                    // Calendar View
                    calendarView

                    // Milestones
                    milestonesSection

                    // Shield Info
                    shieldSection

                    // Statistics
                    statisticsSection
                }
                .padding(24)
            }
        }
        .frame(width: 700, height: 600)
        .background(.ultraThickMaterial)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                animatedStreakDays = streak.currentStreakDays
                showFlame = true
            }
        }
    }

    private var streakDisplay: some View {
        VStack(spacing: 20) {
            // Flame Animation
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.4),
                                Color.red.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 120
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(showFlame ? 1.0 : 0.8)
                    .opacity(showFlame ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: showFlame)

                // Flame Icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(flameGradient)
                    .scaleEffect(showFlame ? 1.0 : 0.5)
                    .opacity(showFlame ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showFlame)
            }
            .frame(height: 200)

            // Streak Number
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(animatedStreakDays)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(streakColor)
                        .contentTransition(.numericText(value: Double(animatedStreakDays)))

                    Text("days")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Text(streak.isActive ? "Active Streak" : "Broken Streak")
                    .font(.headline)
                    .foregroundStyle(streak.isActive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .modernCard()
    }

    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 30 Days")
                .font(.title2.weight(.semibold))

            if last30Days.isEmpty {
                Text("Not enough data to show calendar")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                    ForEach(last30Days, id: \.date) { dayScore in
                        DayCell(
                            date: dayScore.date,
                            isProductive: dayScore.isProductiveDay,
                            focusScore: dayScore.focusScore
                        )
                    }
                }
            }

            HStack(spacing: 16) {
                LegendItem(color: .green, label: "Productive Day (Score ≥ 60)")
                LegendItem(color: .red, label: "Below Target")
                LegendItem(color: .gray.opacity(0.2), label: "No Data")
            }
            .font(.caption)
        }
        .modernCard()
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(.orange)
                Text("Milestone Progress")
                    .font(.title2.weight(.semibold))
            }

            VStack(spacing: 16) {
                ForEach(milestones, id: \.days) { milestone in
                    MilestoneRow(
                        days: milestone.days,
                        reached: milestone.reached,
                        currentDays: streak.currentStreakDays,
                        shields: milestone.shields,
                        xp: milestone.xp
                    )
                }
            }
        }
        .modernCard()
    }

    private var shieldSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundStyle(.blue)
                Text("Streak Shields")
                    .font(.title2.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Shields:")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(0..<max(streak.streakShields, 0), id: \.self) { _ in
                            Image(systemName: "shield.fill")
                                .foregroundStyle(.blue)
                        }
                    }

                    Text("\(streak.streakShields)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.blue)
                }
                .padding(12)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text("Shields protect your streak if you miss one day. They're earned by reaching milestones.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .modernCard()
    }

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.title2.weight(.semibold))

            VStack(spacing: 12) {
                StatRow(
                    icon: "flame.fill",
                    label: "Current Streak",
                    value: "\(streak.currentStreakDays) days",
                    color: streakColor
                )

                StatRow(
                    icon: "trophy.fill",
                    label: "Longest Streak",
                    value: "\(streak.longestStreakDays) days",
                    color: .orange
                )

                if let startDate = streak.streakStartDate {
                    StatRow(
                        icon: "calendar",
                        label: "Streak Started",
                        value: formatDate(startDate),
                        color: .blue
                    )
                }

                if let lastDate = streak.lastProductiveDate {
                    StatRow(
                        icon: "clock.fill",
                        label: "Last Productive Day",
                        value: formatDate(lastDate),
                        color: .green
                    )
                }
            }
        }
        .modernCard()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Helper Components

struct DayCell: View {
    let date: Date
    let isProductive: Bool
    let focusScore: Double

    var body: some View {
        VStack(spacing: 4) {
            Text(dayOfMonth)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Circle()
                .fill(cellColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var dayOfMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private var cellColor: Color {
        if focusScore == 0 {
            return .gray.opacity(0.2)
        } else if isProductive {
            return .green.opacity(min(focusScore / 100, 1.0))
        } else {
            return .red.opacity(0.4)
        }
    }
}

struct MilestoneRow: View {
    let days: Int
    let reached: Bool
    let currentDays: Int
    let shields: Int
    let xp: Int

    var body: some View {
        HStack(spacing: 16) {
            // Checkmark or Progress
            ZStack {
                Circle()
                    .fill(reached ? Color.green : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)

                if reached {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .font(.title3.weight(.bold))
                } else {
                    Text("\(days)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(days) Day Streak")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(spacing: 12) {
                    Label("\(shields) shield\(shields > 1 ? "s" : "")", systemImage: "shield.fill")
                    Label("\(xp) XP", systemImage: "sparkles")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Progress indicator for current milestone
            if !reached && currentDays < days {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(currentDays)/\(days)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ProgressView(value: Double(currentDays), total: Double(days))
                        .frame(width: 80)
                }
            } else if reached {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }
        }
        .padding(12)
        .background(reached ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
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

            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var streak = {
        let streak = Streak()
        streak.currentStreakDays = 15
        streak.longestStreakDays = 25
        streak.streakShields = 2
        streak.lastProductiveDate = Date()
        streak.streakStartDate = Calendar.current.date(byAdding: .day, value: -15, to: Date())
        streak.reached7Days = true
        return streak
    }()

    return StreakDetailView(streak: streak)
}
