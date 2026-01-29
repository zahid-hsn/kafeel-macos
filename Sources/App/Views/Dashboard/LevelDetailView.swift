import SwiftUI
import SwiftData
import Charts
import KafeelCore

struct LevelDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let userProfile: UserProfile

    @State private var animatedLevel: Int = 0
    @Query(sort: \DailyScore.date, order: .reverse) private var dailyScores: [DailyScore]
    @Query private var achievements: [Achievement]

    private var last7DaysXP: [DailyScore] {
        Array(dailyScores.prefix(7).reversed())
    }

    private var tierColor: Color {
        switch userProfile.tier {
        case .apprentice: return .green
        case .journeyman: return .blue
        case .expert: return .purple
        case .master: return .orange
        }
    }

    private var tierGradient: LinearGradient {
        switch userProfile.tier {
        case .apprentice:
            return LinearGradient(
                colors: [Color.green, Color.mint],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .journeyman:
            return LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .expert:
            return LinearGradient(
                colors: [Color.purple, Color.pink],
                startPoint: .leading,
                endPoint: .trailing
            )
        case .master:
            return LinearGradient(
                colors: [Color.orange, Color.yellow],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    private var totalXPFromAchievements: Int {
        achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.type.xpReward }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Level & XP Details")
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
                    // Large Level Badge
                    levelBadge

                    // XP Breakdown
                    xpBreakdownSection

                    // Progress Visualization
                    progressSection

                    // Tier Roadmap
                    tierRoadmapSection

                    // Achievement Contribution
                    achievementSection
                }
                .padding(24)
            }
        }
        .frame(width: 700, height: 600)
        .background(.ultraThickMaterial)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animatedLevel = userProfile.level
            }
        }
    }

    private var levelBadge: some View {
        VStack(spacing: 20) {
            // Large Badge
            ZStack {
                // Outer ring
                Circle()
                    .stroke(tierGradient, lineWidth: 12)
                    .frame(width: 180, height: 180)

                // Inner glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                tierColor.opacity(0.3),
                                tierColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 90
                        )
                    )
                    .frame(width: 180, height: 180)

                // Content
                VStack(spacing: 8) {
                    Image(systemName: userProfile.tier.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(tierGradient)

                    Text("\(animatedLevel)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(tierColor)
                        .contentTransition(.numericText(value: Double(animatedLevel)))

                    Text("LEVEL")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 8) {
                Text(userProfile.tier.rawValue)
                    .font(.title.weight(.bold))
                    .foregroundStyle(tierColor)

                Text("\(formatNumber(userProfile.totalXP)) Total XP")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .modernCard()
    }

    private var xpBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("XP Breakdown")
                .font(.title2.weight(.semibold))

            VStack(spacing: 12) {
                if !last7DaysXP.isEmpty {
                    XPSourceRow(
                        icon: "calendar.badge.checkmark",
                        label: "This Week",
                        xp: last7DaysXP.reduce(0) { $0 + $1.xpEarned },
                        color: .blue
                    )
                }

                if !dailyScores.isEmpty {
                    XPSourceRow(
                        icon: "clock.fill",
                        label: "Today",
                        xp: dailyScores.first?.xpEarned ?? 0,
                        color: .green
                    )
                }

                XPSourceRow(
                    icon: "trophy.fill",
                    label: "From Achievements",
                    xp: totalXPFromAchievements,
                    color: .yellow
                )

                XPSourceRow(
                    icon: "sparkles",
                    label: "Total Career XP",
                    xp: userProfile.totalXP,
                    color: tierColor
                )
            }

            // Weekly XP Chart
            if !last7DaysXP.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("7-Day XP Trend")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Chart(last7DaysXP) { dayScore in
                        BarMark(
                            x: .value("Date", dayScore.date, unit: .day),
                            y: .value("XP", dayScore.xpEarned)
                        )
                        .foregroundStyle(tierGradient)
                        .cornerRadius(4)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .frame(height: 150)
                }
                .padding(.top, 8)
            }
        }
        .modernCard()
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Level Progress")
                .font(.title2.weight(.semibold))

            VStack(spacing: 20) {
                // Current Level
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level \(userProfile.level)")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("\(formatNumber(userProfile.xpForCurrentLevel)) XP")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Level \(userProfile.level + 1)")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Text("\(formatNumber(userProfile.xpForNextLevel)) XP")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(tierColor.opacity(0.15))
                                .frame(height: 16)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(tierGradient)
                                .frame(
                                    width: geometry.size.width * userProfile.levelProgress,
                                    height: 16
                                )
                                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: userProfile.levelProgress)
                        }
                    }
                    .frame(height: 16)

                    HStack {
                        Text("\(formatNumber(userProfile.xpProgressInLevel)) / \(formatNumber(userProfile.xpRequiredForLevelUp)) XP")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Int(userProfile.levelProgress * 100))% complete")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(tierColor)
                    }
                }

                // XP to Next Level
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(tierColor)

                    Text("\(formatNumber(userProfile.xpForNextLevel - userProfile.totalXP)) XP needed for Level \(userProfile.level + 1)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(tierColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .modernCard()
    }

    private var tierRoadmapSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundStyle(.orange)
                Text("Tier Progression")
                    .font(.title2.weight(.semibold))
            }

            VStack(spacing: 12) {
                TierProgressRow(
                    tier: .apprentice,
                    levelRange: "1-10",
                    isActive: userProfile.tier == .apprentice,
                    isPassed: userProfile.level > 10
                )

                TierProgressRow(
                    tier: .journeyman,
                    levelRange: "11-25",
                    isActive: userProfile.tier == .journeyman,
                    isPassed: userProfile.level > 25
                )

                TierProgressRow(
                    tier: .expert,
                    levelRange: "26-50",
                    isActive: userProfile.tier == .expert,
                    isPassed: userProfile.level > 50
                )

                TierProgressRow(
                    tier: .master,
                    levelRange: "51+",
                    isActive: userProfile.tier == .master,
                    isPassed: false
                )
            }
        }
        .modernCard()
    }

    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Achievement XP")
                    .font(.title2.weight(.semibold))

                Spacer()

                Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Unlocked Achievements")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(achievements.filter { $0.isUnlocked }.count)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.yellow)
                }
                .padding(12)
                .background(Color.yellow.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                HStack {
                    Text("Total XP from Achievements")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(formatNumber(totalXPFromAchievements)) XP")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.orange)
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if let nextAchievement = achievements.first(where: { !$0.isUnlocked }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Achievement")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    HStack {
                        Image(systemName: nextAchievement.type.icon)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(nextAchievement.type.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)

                            Text("+\(nextAchievement.type.xpReward) XP")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
                .padding(12)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .modernCard()
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Helper Components

struct XPSourceRow: View {
    let icon: String
    let label: String
    let xp: Int
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

            Text(formatXP(xp))
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)

            Text("XP")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private func formatXP(_ xp: Int) -> String {
        if xp >= 1_000 {
            return String(format: "%.1fK", Double(xp) / 1_000)
        } else {
            return "\(xp)"
        }
    }
}

struct TierProgressRow: View {
    let tier: UserTier
    let levelRange: String
    let isActive: Bool
    let isPassed: Bool

    private var color: Color {
        switch tier {
        case .apprentice: return .green
        case .journeyman: return .blue
        case .expert: return .purple
        case .master: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isActive ? color : (isPassed ? color.opacity(0.3) : Color.gray.opacity(0.2)))
                    .frame(width: 40, height: 40)

                Image(systemName: tier.icon)
                    .foregroundStyle(isActive ? .white : (isPassed ? .white : .secondary))
                    .font(.body.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tier.rawValue)
                    .font(.headline)
                    .foregroundStyle(isActive ? color : .primary)

                Text("Levels \(levelRange)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isPassed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if isActive {
                Text("Current")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.2))
                    .clipShape(Capsule())
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(isActive ? color.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isActive ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var profile = {
        let profile = UserProfile()
        profile.totalXP = 15000
        return profile
    }()

    return LevelDetailView(userProfile: profile)
}
