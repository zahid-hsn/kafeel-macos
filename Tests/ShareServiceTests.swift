import XCTest
import Foundation
@testable import KafeelCore

@MainActor
final class ShareServiceTests: XCTestCase {
    func testGenerateTextSummary() {
        let service = ShareService.shared

        let appUsageStats = [
            AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200),
            AppUsageStat(bundleIdentifier: "com.google.Chrome", appName: "Chrome", totalSeconds: 3600),
            AppUsageStat(bundleIdentifier: "com.apple.Safari", appName: "Safari", totalSeconds: 1800)
        ]

        let summary = service.generateTextSummary(
            appUsageStats: appUsageStats,
            focusScore: 75.5,
            productiveSeconds: 7200,
            distractingSeconds: 1800,
            neutralSeconds: 3600,
            totalSeconds: 12600,
            gitCommitsCount: 5,
            timeFilter: .day,
            selectedDate: Date()
        )

        XCTAssertTrue(summary.contains("Productivity Report"))
        XCTAssertTrue(summary.contains("Focus Score: 76/100"))
        XCTAssertTrue(summary.contains("Xcode"))
        XCTAssertTrue(summary.contains("Chrome"))
        XCTAssertTrue(summary.contains("5 commits"))
        XCTAssertTrue(summary.contains("Great productivity"))
    }

    func testGenerateJSONExport() throws {
        let service = ShareService.shared

        let appUsageStats = [
            AppUsageStat(bundleIdentifier: "com.apple.Xcode", appName: "Xcode", totalSeconds: 7200)
        ]

        let jsonData = try service.generateJSONExport(
            appUsageStats: appUsageStats,
            focusScore: 80.0,
            productiveSeconds: 7200,
            distractingSeconds: 1800,
            neutralSeconds: 3600,
            totalSeconds: 12600,
            gitCommitsCount: 3,
            timeFilter: .day,
            selectedDate: Date()
        )

        // Parse JSON to verify structure
        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertNotNil(json?["metadata"])
        XCTAssertNotNil(json?["summary"])
        XCTAssertNotNil(json?["app_usage"])

        let summary = json?["summary"] as? [String: Any]
        XCTAssertEqual(summary?["focus_score"] as? Double, 80.0)
        XCTAssertEqual(summary?["git_commits_count"] as? Int, 3)
    }

    func testCopyToClipboard() {
        let service = ShareService.shared
        let testText = "Test clipboard content"

        service.copyToClipboard(testText)

        // Verify clipboard content
        let pasteboard = NSPasteboard.general
        let clipboardContent = pasteboard.string(forType: .string)
        XCTAssertEqual(clipboardContent, testText)
    }

    func testFocusScoreDescriptions() {
        let service = ShareService.shared

        let testCases: [(score: Double, expectedKeyword: String)] = [
            (95, "Exceptional"),
            (80, "Great"),
            (65, "Good"),
            (50, "Moderate"),
            (30, "Below average"),
            (10, "Low")
        ]

        for testCase in testCases {
            let summary = service.generateTextSummary(
                appUsageStats: [],
                focusScore: testCase.score,
                productiveSeconds: 0,
                distractingSeconds: 0,
                neutralSeconds: 0,
                totalSeconds: 0,
                gitCommitsCount: 0,
                timeFilter: .day,
                selectedDate: Date()
            )

            XCTAssertTrue(
                summary.contains(testCase.expectedKeyword),
                "Score \(testCase.score) should contain '\(testCase.expectedKeyword)'"
            )
        }
    }

    func testTimeFilterDateRanges() {
        let service = ShareService.shared
        let testDate = Date()

        // Test day filter
        let daySummary = service.generateTextSummary(
            appUsageStats: [],
            focusScore: 75,
            productiveSeconds: 0,
            distractingSeconds: 0,
            neutralSeconds: 0,
            totalSeconds: 0,
            gitCommitsCount: 0,
            timeFilter: .day,
            selectedDate: testDate
        )
        XCTAssertTrue(daySummary.contains("Period: Day"))

        // Test week filter
        let weekSummary = service.generateTextSummary(
            appUsageStats: [],
            focusScore: 75,
            productiveSeconds: 0,
            distractingSeconds: 0,
            neutralSeconds: 0,
            totalSeconds: 0,
            gitCommitsCount: 0,
            timeFilter: .week,
            selectedDate: testDate
        )
        XCTAssertTrue(weekSummary.contains("Period: Week"))

        // Test year filter
        let yearSummary = service.generateTextSummary(
            appUsageStats: [],
            focusScore: 75,
            productiveSeconds: 0,
            distractingSeconds: 0,
            neutralSeconds: 0,
            totalSeconds: 0,
            gitCommitsCount: 0,
            timeFilter: .year,
            selectedDate: testDate
        )
        XCTAssertTrue(yearSummary.contains("Period: Year"))
    }
}
