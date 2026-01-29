import Foundation
import SwiftData

/// Result of a git repository scan operation
public struct GitScanResult {
    public let repositoriesFound: Int
    public let commitsFound: Int
    public let newCommitsAdded: Int
    public let scanDuration: TimeInterval
    public let errors: [String]

    public init(
        repositoriesFound: Int,
        commitsFound: Int,
        newCommitsAdded: Int,
        scanDuration: TimeInterval,
        errors: [String] = []
    ) {
        self.repositoriesFound = repositoriesFound
        self.commitsFound = commitsFound
        self.newCommitsAdded = newCommitsAdded
        self.scanDuration = scanDuration
        self.errors = errors
    }

    public var summary: String {
        var parts = [
            "Found \(repositoriesFound) repositories",
            "Scanned \(commitsFound) commits",
            "Added \(newCommitsAdded) new commits"
        ]

        if !errors.isEmpty {
            parts.append("\(errors.count) errors occurred")
        }

        return parts.joined(separator: ", ")
    }
}

/// Service for orchestrating git repository scanning and commit persistence
@MainActor
public final class GitScanService {
    public static let shared = GitScanService()

    private let gitService = GitService.shared
    private let persistence = PersistenceService.shared

    private init() {}

    /// Scan workspace for git repositories and persist commits
    /// - Parameters:
    ///   - settings: App settings containing workspace path and scan preferences
    ///   - maxDepth: Maximum directory depth to scan (default: 3)
    ///   - daysSince: Number of days back to fetch commits (default: 30)
    ///   - commitLimit: Maximum commits per repository (default: 100)
    /// - Returns: GitScanResult with statistics and any errors
    public func scanWorkspace(
        settings: AppSettings,
        maxDepth: Int = 3,
        daysSince: Int = 30,
        commitLimit: Int = 100
    ) async -> GitScanResult {
        let startTime = Date()
        var errors: [String] = []

        print("GitScanService: Starting workspace scan")

        // Validate workspace path
        guard let workspacePath = settings.workspacePath, !workspacePath.isEmpty else {
            print("GitScanService: No workspace path configured")
            return GitScanResult(
                repositoriesFound: 0,
                commitsFound: 0,
                newCommitsAdded: 0,
                scanDuration: Date().timeIntervalSince(startTime),
                errors: ["No workspace path configured"]
            )
        }

        // Verify path exists
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: workspacePath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            print("GitScanService: Workspace path does not exist or is not a directory: \(workspacePath)")
            return GitScanResult(
                repositoriesFound: 0,
                commitsFound: 0,
                newCommitsAdded: 0,
                scanDuration: Date().timeIntervalSince(startTime),
                errors: ["Workspace path does not exist: \(workspacePath)"]
            )
        }

        // Step 1: Scan for repositories
        print("GitScanService: Scanning for repositories in: \(workspacePath)")
        let repoPaths = gitService.scanRepositories(in: [workspacePath], maxDepth: maxDepth)

        guard !repoPaths.isEmpty else {
            print("GitScanService: No repositories found")
            return GitScanResult(
                repositoriesFound: 0,
                commitsFound: 0,
                newCommitsAdded: 0,
                scanDuration: Date().timeIntervalSince(startTime),
                errors: []
            )
        }

        print("GitScanService: Found \(repoPaths.count) repositories")

        // Step 2: Get current git user name for filtering
        let currentUser = gitService.getCurrentUserName()
        if let user = currentUser {
            print("GitScanService: Filtering commits by author: \(user)")
        } else {
            print("GitScanService: Warning - Could not determine git user name, will fetch all commits")
        }

        // Step 3: Fetch commits from each repository
        let sinceDate = Calendar.current.date(byAdding: .day, value: -daysSince, to: Date()) ?? Date.distantPast
        var totalCommitsFound = 0
        var newCommitsAdded = 0

        for repoPath in repoPaths {
            print("GitScanService: Fetching commits from: \(repoPath)")

            let commits = gitService.fetchCommits(
                from: repoPath,
                since: sinceDate,
                limit: commitLimit,
                author: currentUser
            )

            totalCommitsFound += commits.count

            // Step 4: Persist commits (avoid duplicates)
            do {
                let addedCount = try await persistCommits(commits)
                newCommitsAdded += addedCount
                print("GitScanService: Added \(addedCount) new commits from \(repoPath)")
            } catch {
                let errorMsg = "Failed to persist commits from \(repoPath): \(error.localizedDescription)"
                print("GitScanService: \(errorMsg)")
                errors.append(errorMsg)
            }
        }

        // Step 5: Update last scan time
        do {
            settings.lastGitScanTime = Date()
            try persistence.save()
            print("GitScanService: Updated lastGitScanTime")
        } catch {
            let errorMsg = "Failed to update lastGitScanTime: \(error.localizedDescription)"
            print("GitScanService: \(errorMsg)")
            errors.append(errorMsg)
        }

        let duration = Date().timeIntervalSince(startTime)
        let result = GitScanResult(
            repositoriesFound: repoPaths.count,
            commitsFound: totalCommitsFound,
            newCommitsAdded: newCommitsAdded,
            scanDuration: duration,
            errors: errors
        )

        print("GitScanService: Scan complete - \(result.summary) in \(String(format: "%.2f", duration))s")
        return result
    }

    /// Persist commits to SwiftData, checking for duplicates by commitHash
    /// - Parameter commits: Array of GitActivity commits to persist
    /// - Returns: Number of new commits added
    private func persistCommits(_ commits: [GitActivity]) async throws -> Int {
        guard !commits.isEmpty else { return 0 }

        var addedCount = 0

        // Fetch existing commit hashes to check for duplicates
        let commitHashes = commits.map { $0.commitHash }
        let existingHashes = try fetchExistingCommitHashes(commitHashes)

        for commit in commits {
            // Skip if already exists
            if existingHashes.contains(commit.commitHash) {
                continue
            }

            // Insert new commit
            persistence.context.insert(commit)
            addedCount += 1
        }

        // Save if we added any commits
        if addedCount > 0 {
            try persistence.save()
        }

        return addedCount
    }

    /// Fetch existing commit hashes from the database
    /// - Parameter hashes: Array of commit hashes to check
    /// - Returns: Set of commit hashes that already exist
    private func fetchExistingCommitHashes(_ hashes: [String]) throws -> Set<String> {
        // Create a predicate to fetch commits with matching hashes
        let predicate = #Predicate<GitActivity> { activity in
            hashes.contains(activity.commitHash)
        }

        let descriptor = FetchDescriptor<GitActivity>(predicate: predicate)
        let existing = try persistence.context.fetch(descriptor)

        return Set(existing.map { $0.commitHash })
    }

    /// Check if auto-scan should run based on settings
    /// - Parameter settings: App settings with scan preferences
    /// - Returns: True if enough time has passed since last scan
    public func shouldAutoScan(settings: AppSettings) -> Bool {
        guard settings.autoScanEnabled else {
            return false
        }

        guard let lastScan = settings.lastGitScanTime else {
            // Never scanned before
            return true
        }

        let hoursSinceLastScan = Date().timeIntervalSince(lastScan) / 3600
        let shouldScan = hoursSinceLastScan >= Double(settings.gitScanFrequencyHours)

        if shouldScan {
            print("GitScanService: Auto-scan triggered (last scan: \(String(format: "%.1f", hoursSinceLastScan)) hours ago)")
        }

        return shouldScan
    }

    /// Get recent git activities from the database
    /// - Parameters:
    ///   - days: Number of days back to fetch
    ///   - limit: Maximum number of activities to return
    /// - Returns: Array of GitActivity sorted by date (newest first)
    public func fetchRecentActivities(days: Int = 7, limit: Int = 50) throws -> [GitActivity] {
        let sinceDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast

        let predicate = #Predicate<GitActivity> { activity in
            activity.date >= sinceDate
        }

        let descriptor = FetchDescriptor<GitActivity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        var fetchDescriptor = descriptor
        fetchDescriptor.fetchLimit = limit

        return try persistence.context.fetch(fetchDescriptor)
    }

    /// Get git activities for a specific date
    /// - Parameter date: The date to fetch activities for
    /// - Returns: Array of GitActivity for that day
    public func fetchActivities(for date: Date) throws -> [GitActivity] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let predicate = #Predicate<GitActivity> { activity in
            activity.date >= startOfDay && activity.date < endOfDay
        }

        let descriptor = FetchDescriptor<GitActivity>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try persistence.context.fetch(descriptor)
    }

    /// Get statistics about git activity
    /// - Parameter days: Number of days back to calculate stats
    /// - Returns: GitRepoStats with aggregated statistics
    public func getActivityStats(days: Int = 30) throws -> GitRepoStats {
        let activities = try fetchRecentActivities(days: days, limit: 1000)
        return gitService.getAggregatedStats(from: activities)
    }
}
