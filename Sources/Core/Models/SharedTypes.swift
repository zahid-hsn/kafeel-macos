import Foundation

// MARK: - Time Filter

public enum TimeFilter: String, CaseIterable, Identifiable {
    case day = "Day"
    case week = "Week"
    case year = "Year"

    public var id: String { rawValue }

    public func dateRange(from date: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        switch self {
        case .day:
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start)!
            return (start, end)

        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            let end = calendar.date(byAdding: .day, value: 7, to: start)!
            return (start, end)

        case .year:
            let start = calendar.dateInterval(of: .year, for: date)?.start ?? date
            let end = calendar.date(byAdding: .year, value: 1, to: start)!
            return (start, end)
        }
    }
}

// MARK: - App Usage Statistics

public struct AppUsageStat: Identifiable {
    public let id = UUID()
    public let bundleIdentifier: String
    public let appName: String
    public let totalSeconds: Int

    public var formattedDuration: String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    public init(bundleIdentifier: String, appName: String, totalSeconds: Int) {
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.totalSeconds = totalSeconds
    }
}
