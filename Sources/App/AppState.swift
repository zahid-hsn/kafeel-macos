import Foundation
import SwiftUI
import SwiftData
import KafeelCore

@MainActor
@Observable
final class AppState {
    var selectedTimeFilter: TimeFilter = .day
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var todayActivities: [ActivityLog] = []
    var focusScore: Double = 0.0
    var appUsageStats: [AppUsageStat] = []

    // Git Activity
    var recentGitActivity: [GitActivity] = []
    var weeklyFocusScores: [Double] = []

    // Browser History
    var browsingActivities: [BrowsingActivity] = []

    // Activity Monitor
    var activityMonitor: ActivityMonitor
    var isTrackingEnabled: Bool = true

    // Dependencies
    private var modelContext: ModelContext?

    // MARK: - Computed Properties for Detail Views

    var productiveSeconds: Int {
        guard let modelContext = modelContext else { return 0 }
        let categories = fetchCategories(from: modelContext)
        return todayActivities
            .filter { categories[$0.appBundleIdentifier] == .productive }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    var distractingSeconds: Int {
        guard let modelContext = modelContext else { return 0 }
        let categories = fetchCategories(from: modelContext)
        return todayActivities
            .filter { categories[$0.appBundleIdentifier] == .distracting }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    var neutralSeconds: Int {
        guard let modelContext = modelContext else { return 0 }
        let categories = fetchCategories(from: modelContext)
        return todayActivities
            .filter { categories[$0.appBundleIdentifier] == .neutral }
            .reduce(0) { $0 + $1.durationSeconds }
    }

    var totalSeconds: Int {
        todayActivities.reduce(0) { $0 + $1.durationSeconds }
    }

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        self.activityMonitor = ActivityMonitor()
    }

    private func fetchCategories(from context: ModelContext) -> [String: CategoryType] {
        let descriptor = FetchDescriptor<AppCategory>()
        let categories = (try? context.fetch(descriptor)) ?? []
        return Dictionary(uniqueKeysWithValues: categories.map { ($0.bundleIdentifier, $0.category) })
    }

    func startTracking() {
        activityMonitor.startMonitoring()
        isTrackingEnabled = true
    }

    func stopTracking() {
        activityMonitor.stopMonitoring()
        isTrackingEnabled = false
    }

    // MARK: - Refresh Data

    func refreshData() async {
        isLoading = true
        defer { isLoading = false }

        guard let modelContext = modelContext else {
            // Use mock data if no context available (preview mode)
            loadMockData()
            return
        }

        do {
            // Get date range based on filter
            let (startDate, endDate) = selectedTimeFilter.dateRange(from: selectedDate)

            // Fetch activities in date range
            let descriptor = FetchDescriptor<ActivityLog>(
                predicate: #Predicate<ActivityLog> { activity in
                    activity.startTime >= startDate && activity.startTime < endDate
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )

            let fetchedActivities = try modelContext.fetch(descriptor)

            // Filter out loginwindow - it represents idle time, not active usage
            todayActivities = fetchedActivities.filter { $0.appBundleIdentifier != "com.apple.loginwindow" }

            // Calculate app usage statistics
            calculateAppUsageStats()

            // Calculate focus score
            calculateFocusScore(modelContext: modelContext)
            // Fetch git activity
            fetchGitActivity(modelContext: modelContext)
            // Fetch browser history
            fetchBrowsingHistory(startDate: startDate)

        } catch {
            print("Error refreshing data: \(error)")
            todayActivities = []
            appUsageStats = []
            focusScore = 0
        }
    }

    private func fetchGitActivity(modelContext: ModelContext) {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        let descriptor = FetchDescriptor<GitActivity>(
            predicate: #Predicate<GitActivity> { activity in
                activity.date >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            recentGitActivity = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching git activity: \(error)")
            recentGitActivity = []
        }
    }

    private func fetchBrowsingHistory(startDate: Date) {
        // Fetch browsing history using BrowserHistoryService
        // This gracefully handles cases where permissions aren't granted
        let history = BrowserHistoryService.shared.fetchHistory(since: startDate, limit: 500)
        browsingActivities = history
        print("Fetched \(history.count) browsing activities since \(startDate)")
    }

    // MARK: - Git Activity Scanning

    func refreshGitActivity() async -> GitScanResult {
        guard let modelContext = modelContext else {
            return GitScanResult(
                repositoriesFound: 0,
                commitsFound: 0,
                newCommitsAdded: 0,
                scanDuration: 0,
                errors: ["No model context available"]
            )
        }

        // Fetch app settings
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? modelContext.fetch(settingsDescriptor).first else {
            return GitScanResult(
                repositoriesFound: 0,
                commitsFound: 0,
                newCommitsAdded: 0,
                scanDuration: 0,
                errors: ["No settings found"]
            )
        }

        // Perform scan using GitScanService
        let result = await GitScanService.shared.scanWorkspace(settings: settings)

        // Refresh the git activity array
        fetchGitActivity(modelContext: modelContext)

        return result
    }

    // MARK: - Private Helpers

    private func calculateAppUsageStats() {
        var usageDict: [String: (name: String, duration: Int)] = [:]

        for activity in todayActivities {
            let key = activity.appBundleIdentifier
            let currentDuration = usageDict[key]?.duration ?? 0
            usageDict[key] = (
                name: activity.appName,
                duration: currentDuration + activity.durationSeconds
            )
        }

        appUsageStats = usageDict.map { bundleId, data in
            AppUsageStat(
                bundleIdentifier: bundleId,
                appName: data.name,
                totalSeconds: data.duration
            )
        }.sorted { $0.totalSeconds > $1.totalSeconds }
    }

    private func calculateFocusScore(modelContext: ModelContext) {
        guard !todayActivities.isEmpty else {
            focusScore = 0
            return
        }

        // Fetch all app categories
        let descriptor = FetchDescriptor<AppCategory>()
        let categories: [AppCategory]
        do {
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching categories: \(error)")
            focusScore = 0
            return
        }

        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.bundleIdentifier, $0.category) })

        // Calculate weighted score
        var totalWeightedTime: Double = 0
        var totalTime: Double = 0

        for activity in todayActivities {
            let duration = Double(activity.durationSeconds)
            let category = categoryMap[activity.appBundleIdentifier] ?? .neutral
            let weight = category.weight

            totalWeightedTime += duration * weight
            totalTime += duration
        }

        focusScore = totalTime > 0 ? (totalWeightedTime / totalTime) * 100 : 0
    }

    private func loadMockData() {
        // Mock data for previews
        appUsageStats = [
            AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
            AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
            AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 1800),
            AppUsageStat(bundleIdentifier: "com.apple.Music", appName: "Music", totalSeconds: 900),
        ]
        focusScore = 75.0
    }
}

// Note: TimeFilter and AppUsageStat are now defined in KafeelCore/SharedTypes.swift
