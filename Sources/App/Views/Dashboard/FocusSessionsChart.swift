import SwiftUI
import Charts
import KafeelCore

struct FocusSessionsChart: View {
    let activities: [ActivityLog]
    let categories: [String: CategoryType]

    @State private var selectedSession: FocusSession?
    @State private var isAnimated = false
    @State private var showDetail = false
    @State private var isHovering = false

    private let focusThresholdMinutes = 25

    private var focusSessions: [FocusSession] {
        var sessions: [FocusSession] = []
        var currentSession: FocusSession?

        let sortedActivities = activities.sorted { $0.startTime < $1.startTime }

        for activity in sortedActivities {
            let category = categories[activity.appBundleIdentifier] ?? .neutral
            let durationMinutes = activity.durationSeconds / 60

            // Only productive apps count as focus sessions
            guard category == .productive else {
                // End current session if exists
                if let session = currentSession {
                    sessions.append(session)
                    currentSession = nil
                }
                continue
            }

            if let session = currentSession {
                // Check if this activity is within 5 minutes of the last activity
                let timeSinceLastActivity = activity.startTime.timeIntervalSince(session.endTime)
                if timeSinceLastActivity <= 300 { // 5 minutes
                    // Extend current session
                    currentSession = FocusSession(
                        id: session.id,
                        startTime: session.startTime,
                        endTime: activity.endTime ?? Date(),
                        durationMinutes: session.durationMinutes + durationMinutes,
                        apps: session.apps + [activity.appName]
                    )
                } else {
                    // Start new session
                    sessions.append(session)
                    currentSession = FocusSession(
                        id: UUID(),
                        startTime: activity.startTime,
                        endTime: activity.endTime ?? Date(),
                        durationMinutes: durationMinutes,
                        apps: [activity.appName]
                    )
                }
            } else {
                // Start new session
                currentSession = FocusSession(
                    id: UUID(),
                    startTime: activity.startTime,
                    endTime: activity.endTime ?? Date(),
                    durationMinutes: durationMinutes,
                    apps: [activity.appName]
                )
            }
        }

        // Add the last session if exists
        if let session = currentSession {
            sessions.append(session)
        }

        // Filter sessions that are at least focusThresholdMinutes long
        return sessions.filter { $0.durationMinutes >= focusThresholdMinutes }
    }

    private var totalDeepWorkTime: Int {
        focusSessions.map(\.durationMinutes).reduce(0, +)
    }

    private var formattedDeepWorkTime: String {
        let hours = totalDeepWorkTime / 60
        let minutes = totalDeepWorkTime % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus Sessions")
                        .font(.title3.weight(.semibold))

                    Text("\(focusSessions.count) sessions (\(focusThresholdMinutes)+ min) • \(formattedDeepWorkTime) deep work")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Deep work badge
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption)
                    Text(formattedDeepWorkTime)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                )
            }

            if focusSessions.isEmpty {
                emptyState
            } else {
                VStack(spacing: 16) {
                    // Timeline
                    ScrollView(.horizontal, showsIndicators: false) {
                        timelineView
                            .padding(.vertical, 8)
                    }

                    // Stats
                    statsView
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
            FocusSessionsDetailView(focusSessions: focusSessions)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
        .onChange(of: activities) { _, _ in
            isAnimated = false
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                isAnimated = true
            }
        }
    }

    private var timelineView: some View {
        HStack(spacing: 8) {
            ForEach(Array(focusSessions.enumerated()), id: \.element.id) { index, session in
                sessionBlock(for: session, index: index)
            }
        }
        .frame(height: 80)
    }

    private func sessionBlock(for session: FocusSession, index: Int) -> some View {
        let isSelected = selectedSession?.id == session.id
        let width = CGFloat(min(session.durationMinutes, 120)) * 2 // Scale for display

        return VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(sessionGradient)
                .frame(width: width, height: 50)
                .overlay(
                    VStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)

                        Text("\(session.durationMinutes)m")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                )
                .scaleEffect(isSelected ? 1.05 : (isAnimated ? 1.0 : 0.8))
                .shadow(
                    color: isSelected ? Color.purple.opacity(0.4) : Color.clear,
                    radius: isSelected ? 8 : 0
                )

            Text(formatTime(session.startTime))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedSession = selectedSession?.id == session.id ? nil : session
            }
        }
    }

    private var sessionGradient: LinearGradient {
        LinearGradient(
            colors: [Color.purple, Color.blue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statsView: some View {
        HStack(spacing: 16) {
            statCard(
                icon: "chart.bar.fill",
                title: "Sessions",
                value: "\(focusSessions.count)",
                color: .blue
            )

            statCard(
                icon: "clock.fill",
                title: "Avg Duration",
                value: "\(focusSessions.isEmpty ? 0 : totalDeepWorkTime / focusSessions.count)m",
                color: .purple
            )

            statCard(
                icon: "star.fill",
                title: "Longest",
                value: "\(focusSessions.map(\.durationMinutes).max() ?? 0)m",
                color: .orange
            )
        }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial)
        .cornerRadius(10)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No focus sessions yet")
                .font(.body)
                .foregroundStyle(.secondary)
            Text("Work on productive apps for \(focusThresholdMinutes)+ minutes")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct FocusSession: Identifiable, Equatable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let durationMinutes: Int
    let apps: [String]

    var uniqueApps: [String] {
        Array(Set(apps)).sorted()
    }

    static func == (lhs: FocusSession, rhs: FocusSession) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Detail View

struct FocusSessionsDetailView: View {
    let focusSessions: [FocusSession]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("All Focus Sessions")
                    .font(.title2.weight(.bold))
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            if focusSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "flame")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No focus sessions yet")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(focusSessions) { session in
                            FocusSessionDetailCard(session: session)
                        }
                    }
                }
            }
        }
        .padding(32)
        .frame(width: 600, height: 700)
    }
}

struct FocusSessionDetailCard: View {
    let session: FocusSession

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(session.durationMinutes) minutes")
                        .font(.body.weight(.bold))

                    Text("\(formatTime(session.startTime)) - \(formatTime(session.endTime))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(sessionQuality(session.durationMinutes))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(sessionQualityColor(session.durationMinutes))
                    )
            }

            if !session.uniqueApps.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Apps Used")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)

                    FlowLayout(spacing: 6) {
                        ForEach(session.uniqueApps, id: \.self) { app in
                            Text(app)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.1))
                                .foregroundStyle(.purple)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func sessionQuality(_ minutes: Int) -> String {
        switch minutes {
        case 0..<45: return "Focus"
        case 45..<90: return "Deep Work"
        default: return "Flow State"
        }
    }

    private func sessionQualityColor(_ minutes: Int) -> Color {
        switch minutes {
        case 0..<45: return .blue
        case 45..<90: return .purple
        default: return .orange
        }
    }
}

// Simple flow layout for tags (if not already defined)
extension FlowLayout {
    // Already defined in DailyHeatmap.swift
}

#Preview {
    let now = Date()
    let activities = [
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: now.addingTimeInterval(-5400)),
        ActivityLog(appBundleIdentifier: "com.apple.Xcode", appName: "Xcode", startTime: now.addingTimeInterval(-3600)),
        ActivityLog(appBundleIdentifier: "com.apple.Terminal", appName: "Terminal", startTime: now.addingTimeInterval(-1800)),
    ]

    for activity in activities {
        activity.finalize()
    }

    let categories = [
        "com.apple.Xcode": CategoryType.productive,
        "com.apple.Terminal": CategoryType.productive,
    ]

    return VStack {
        FocusSessionsChart(activities: activities, categories: categories)
        FocusSessionsChart(activities: [], categories: [:])
    }
    .padding()
    .frame(width: 700)
}
