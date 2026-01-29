import SwiftUI
import KafeelCore

struct FocusScoreDonut: View {
    let score: Double
    let productiveSeconds: Int
    let distractingSeconds: Int
    let neutralSeconds: Int
    let totalSeconds: Int

    @State private var animatedScore: Double = 0
    @State private var isHovering = false
    @State private var showDetail = false

    private var scoreColor: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
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

    private var scoreLabel: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        case 20..<40: return "Needs Work"
        default: return "Low"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Focus Score")
                .font(.headline)
                .foregroundStyle(.secondary)

            ZStack {
                // Background circle
                Circle()
                    .stroke(scoreColor.opacity(0.15), lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Animated progress circle
                Circle()
                    .trim(from: 0, to: animatedScore / 100)
                    .stroke(scoreGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedScore)

                // Center content
                VStack(spacing: 2) {
                    Text("\(Int(animatedScore))")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                        .contentTransition(.numericText(value: animatedScore))

                    Text(scoreLabel)
                        .font(.caption2)
                        .foregroundStyle(scoreColor.opacity(0.8))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadiusLarge, style: .continuous)
                .strokeBorder(
                    isHovering ? scoreColor.opacity(0.4) : scoreColor.opacity(0.2),
                    lineWidth: isHovering ? 1.5 : 1
                )
                .animation(AppTheme.animationFast, value: isHovering)
        )
        .shadow(
            color: isHovering ? scoreColor.opacity(0.2) : scoreColor.opacity(0.1),
            radius: isHovering ? 16 : 10,
            y: isHovering ? 6 : 4
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(AppTheme.animationSpring, value: isHovering)
        .onTapGesture {
            showDetail = true
        }
        .onHover { hovering in
            isHovering = hovering
            if hovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.2)) {
                animatedScore = score
            }
        }
        .onChange(of: score) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedScore = newValue
            }
        }
        .sheet(isPresented: $showDetail) {
            FocusScoreDetailView(
                score: score,
                productiveSeconds: productiveSeconds,
                distractingSeconds: distractingSeconds,
                neutralSeconds: neutralSeconds,
                totalSeconds: totalSeconds
            )
        }
    }
}

#Preview {
    HStack {
        FocusScoreDonut(
            score: 85,
            productiveSeconds: 18000,
            distractingSeconds: 3600,
            neutralSeconds: 7200,
            totalSeconds: 28800
        )
        FocusScoreDonut(
            score: 65,
            productiveSeconds: 12000,
            distractingSeconds: 7200,
            neutralSeconds: 9600,
            totalSeconds: 28800
        )
        FocusScoreDonut(
            score: 45,
            productiveSeconds: 7200,
            distractingSeconds: 12000,
            neutralSeconds: 9600,
            totalSeconds: 28800
        )
    }
    .padding()
}
