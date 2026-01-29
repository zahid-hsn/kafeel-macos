import Foundation
import PDFKit
import AppKit
import SwiftUI
import SwiftData

/// Service for generating PDF reports of productivity analytics
@MainActor
public final class PDFExportService {
    public static let shared = PDFExportService()

    private init() {}

    // MARK: - Public API

    /// Generates a PDF report with analytics data
    /// - Parameters:
    ///   - dailyScores: Array of DailyScore objects for the time range
    ///   - focusScore: Current focus score
    ///   - productiveSeconds: Total productive time in seconds
    ///   - distractingSeconds: Total distracting time in seconds
    ///   - neutralSeconds: Total neutral time in seconds
    ///   - appUsageStats: Top apps by usage time
    ///   - gitActivities: Git commit activity (optional)
    ///   - browsingActivities: Browsing history (optional)
    ///   - timeFilter: Time range filter
    ///   - selectedDate: Reference date for the report
    /// - Returns: PDF data ready to save or share
    public func generateReport(
        dailyScores: [DailyScore],
        focusScore: Double,
        productiveSeconds: Int,
        distractingSeconds: Int,
        neutralSeconds: Int,
        appUsageStats: [AppUsageStat],
        gitActivities: [GitActivity] = [],
        browsingActivities: [BrowsingActivity] = [],
        timeFilter: TimeFilter,
        selectedDate: Date
    ) async throws -> Data {
        let pdfDocument = PDFDocument()

        // Calculate date range
        let (startDate, endDate) = timeFilter.dateRange(from: selectedDate)

        // Create pages
        let page1 = try createTitlePage(
            focusScore: focusScore,
            productiveSeconds: productiveSeconds,
            distractingSeconds: distractingSeconds,
            neutralSeconds: neutralSeconds,
            startDate: startDate,
            endDate: endDate,
            timeFilter: timeFilter
        )
        pdfDocument.insert(page1, at: 0)

        let page2 = try createAppUsagePage(
            appUsageStats: appUsageStats,
            dailyScores: dailyScores,
            startDate: startDate,
            endDate: endDate
        )
        pdfDocument.insert(page2, at: 1)

        if !gitActivities.isEmpty {
            let page3 = try createGitActivityPage(
                gitActivities: gitActivities,
                startDate: startDate,
                endDate: endDate
            )
            pdfDocument.insert(page3, at: 2)
        }

        if !browsingActivities.isEmpty {
            let page4 = try createBrowsingActivityPage(
                browsingActivities: browsingActivities,
                startDate: startDate,
                endDate: endDate
            )
            pdfDocument.insert(page4, at: pdfDocument.pageCount)
        }

        // Add achievements page
        let achievementsPage = try createAchievementsPage(
            dailyScores: dailyScores,
            focusScore: focusScore
        )
        pdfDocument.insert(achievementsPage, at: pdfDocument.pageCount)

        guard let data = pdfDocument.dataRepresentation() else {
            throw PDFExportError.failedToGeneratePDF
        }

        return data
    }

    /// Saves PDF data to a file URL
    public func saveReport(data: Data, to url: URL) throws {
        try data.write(to: url)
    }

    // MARK: - Page Creation

    private func createTitlePage(
        focusScore: Double,
        productiveSeconds: Int,
        distractingSeconds: Int,
        neutralSeconds: Int,
        startDate: Date,
        endDate: Date,
        timeFilter: TimeFilter
    ) throws -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter

        // Create PDF data
        let data = NSMutableData()
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.failedToCreateContext
        }

        context.beginPDFPage(nil)

        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext

        // Draw header
        drawHeader(in: pageRect, context: context, title: "Productivity Report")

        // Draw date range
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateRangeText = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
        drawText(dateRangeText, at: CGPoint(x: 50, y: 680), fontSize: 14, color: .gray, context: context)

        // Draw focus score
        let scoreY: CGFloat = 600
        drawSectionTitle("Focus Score", at: CGPoint(x: 50, y: scoreY), context: context)

        let scoreRect = CGRect(x: 50, y: scoreY - 120, width: 512, height: 100)
        drawFocusScoreCard(
            focusScore: focusScore,
            productiveSeconds: productiveSeconds,
            distractingSeconds: distractingSeconds,
            neutralSeconds: neutralSeconds,
            in: scoreRect,
            context: context
        )

        // Draw time breakdown
        let breakdownY: CGFloat = 440
        drawSectionTitle("Time Breakdown", at: CGPoint(x: 50, y: breakdownY), context: context)

        let totalSeconds = productiveSeconds + distractingSeconds + neutralSeconds
        drawTimeBreakdown(
            productiveSeconds: productiveSeconds,
            distractingSeconds: distractingSeconds,
            neutralSeconds: neutralSeconds,
            totalSeconds: totalSeconds,
            at: CGPoint(x: 50, y: breakdownY - 40),
            context: context
        )

        // Draw footer
        drawFooter(in: pageRect, context: context, pageNumber: 1)

        context.endPDFPage()

        // Create PDF page from data
        let pdfPage = PDFPage(image: NSImage(data: data as Data)!) ?? PDFPage()
        return pdfPage
    }

    private func createAppUsagePage(
        appUsageStats: [AppUsageStat],
        dailyScores: [DailyScore],
        startDate: Date,
        endDate: Date
    ) throws -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        // Create PDF data
        let data = NSMutableData()
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.failedToCreateContext
        }

        context.beginPDFPage(nil)

        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext

        // Draw header
        drawHeader(in: pageRect, context: context, title: "App Usage & Trends")

        // Draw top apps
        let topAppsY: CGFloat = 650
        drawSectionTitle("Top Applications", at: CGPoint(x: 50, y: topAppsY), context: context)

        let topApps = Array(appUsageStats.prefix(10))
        drawAppUsageList(topApps, at: CGPoint(x: 50, y: topAppsY - 40), context: context)

        // Draw daily trend
        if !dailyScores.isEmpty {
            let trendY: CGFloat = 300
            drawSectionTitle("Focus Score Trend", at: CGPoint(x: 50, y: trendY), context: context)
            drawFocusTrendChart(dailyScores: dailyScores, at: CGPoint(x: 50, y: trendY - 40), context: context)
        }

        // Draw footer
        drawFooter(in: pageRect, context: context, pageNumber: 2)

        context.endPDFPage()

        let pdfPage = PDFPage(image: NSImage(data: data as Data)!) ?? PDFPage()
        return pdfPage
    }

    private func createGitActivityPage(
        gitActivities: [GitActivity],
        startDate: Date,
        endDate: Date
    ) throws -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        // Create PDF data
        let data = NSMutableData()
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.failedToCreateContext
        }

        context.beginPDFPage(nil)

        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext

        // Draw header
        drawHeader(in: pageRect, context: context, title: "Git Activity")

        // Calculate statistics
        let totalCommits = gitActivities.count
        let totalAdditions = gitActivities.reduce(0) { $0 + $1.additions }
        let totalDeletions = gitActivities.reduce(0) { $0 + $1.deletions }
        let totalFiles = gitActivities.reduce(0) { $0 + $1.filesChanged }

        // Draw summary
        let summaryY: CGFloat = 650
        drawSectionTitle("Summary", at: CGPoint(x: 50, y: summaryY), context: context)

        let summaryStats = [
            ("Commits", "\(totalCommits)"),
            ("Lines Added", "\(totalAdditions)"),
            ("Lines Removed", "\(totalDeletions)"),
            ("Files Changed", "\(totalFiles)")
        ]
        drawStatsList(summaryStats, at: CGPoint(x: 50, y: summaryY - 40), context: context)

        // Draw recent commits
        let commitsY: CGFloat = 500
        drawSectionTitle("Recent Commits", at: CGPoint(x: 50, y: commitsY), context: context)

        let recentCommits = Array(gitActivities.prefix(15))
        drawGitCommitList(recentCommits, at: CGPoint(x: 50, y: commitsY - 40), context: context)

        // Draw footer
        drawFooter(in: pageRect, context: context, pageNumber: 3)

        context.endPDFPage()

        let pdfPage = PDFPage(image: NSImage(data: data as Data)!) ?? PDFPage()
        return pdfPage
    }

    private func createBrowsingActivityPage(
        browsingActivities: [BrowsingActivity],
        startDate: Date,
        endDate: Date
    ) throws -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        // Create PDF data
        let data = NSMutableData()
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.failedToCreateContext
        }

        context.beginPDFPage(nil)

        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext

        // Draw header
        drawHeader(in: pageRect, context: context, title: "Browsing Activity")

        // Calculate statistics
        let totalVisits = browsingActivities.count
        let categories = Dictionary(grouping: browsingActivities) { $0.category }
        let topCategory = categories.max { $0.value.count < $1.value.count }

        // Draw summary
        let summaryY: CGFloat = 650
        drawSectionTitle("Summary", at: CGPoint(x: 50, y: summaryY), context: context)

        let summaryStats = [
            ("Total Visits", "\(totalVisits)"),
            ("Top Category", topCategory?.key.displayName ?? "N/A"),
            ("Unique Domains", "\(Set(browsingActivities.map { $0.domain }).count)")
        ]
        drawStatsList(summaryStats, at: CGPoint(x: 50, y: summaryY - 40), context: context)

        // Draw category breakdown
        let categoryY: CGFloat = 500
        drawSectionTitle("Category Breakdown", at: CGPoint(x: 50, y: categoryY), context: context)
        drawCategoryBreakdown(categories: categories, at: CGPoint(x: 50, y: categoryY - 40), context: context)

        // Draw top domains
        let domainsY: CGFloat = 300
        drawSectionTitle("Top Domains", at: CGPoint(x: 50, y: domainsY), context: context)

        let domainCounts = Dictionary(grouping: browsingActivities) { $0.domain }
            .map { (domain: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }

        let topDomains = Array(domainCounts.prefix(10))
        drawDomainList(topDomains, at: CGPoint(x: 50, y: domainsY - 40), context: context)

        // Draw footer
        drawFooter(in: pageRect, context: context, pageNumber: 4)

        context.endPDFPage()

        let pdfPage = PDFPage(image: NSImage(data: data as Data)!) ?? PDFPage()
        return pdfPage
    }

    private func createAchievementsPage(
        dailyScores: [DailyScore],
        focusScore: Double
    ) throws -> PDFPage {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)

        // Create PDF data
        let data = NSMutableData()
        var mediaBox = pageRect
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFExportError.failedToCreateContext
        }

        context.beginPDFPage(nil)

        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext

        // Draw header
        drawHeader(in: pageRect, context: context, title: "Achievements & Insights")

        // Calculate achievements
        let productiveDays = dailyScores.filter { $0.isProductiveDay }.count
        let currentStreak = calculateStreak(dailyScores: dailyScores)
        let averageScore = dailyScores.isEmpty ? 0 : dailyScores.reduce(0) { $0 + $1.focusScore } / Double(dailyScores.count)
        let bestDay = dailyScores.max { $0.focusScore < $1.focusScore }

        // Draw achievements
        let achievementsY: CGFloat = 650
        drawSectionTitle("Achievements", at: CGPoint(x: 50, y: achievementsY), context: context)

        let achievements = [
            ("🎯", "Productive Days", "\(productiveDays) days"),
            ("🔥", "Current Streak", "\(currentStreak) days"),
            ("📊", "Average Score", String(format: "%.1f", averageScore)),
            ("🏆", "Best Day", bestDay != nil ? String(format: "%.1f", bestDay!.focusScore) : "N/A")
        ]
        drawAchievementsList(achievements, at: CGPoint(x: 50, y: achievementsY - 40), context: context)

        // Draw insights
        let insightsY: CGFloat = 400
        drawSectionTitle("Insights", at: CGPoint(x: 50, y: insightsY), context: context)

        let insights = generateInsights(dailyScores: dailyScores, focusScore: focusScore)
        drawInsightsList(insights, at: CGPoint(x: 50, y: insightsY - 40), context: context)

        // Draw footer
        drawFooter(in: pageRect, context: context, pageNumber: 5)

        context.endPDFPage()

        let pdfPage = PDFPage(image: NSImage(data: data as Data)!) ?? PDFPage()
        return pdfPage
    }

    // MARK: - Drawing Helpers

    private func drawHeader(in rect: CGRect, context: CGContext, title: String) {
        // Draw app logo
        let logoRect = CGRect(x: 50, y: rect.height - 70, width: 40, height: 40)
        drawLogo(in: logoRect, context: context)

        // Draw title
        drawText(title, at: CGPoint(x: 100, y: rect.height - 60), fontSize: 24, bold: true, context: context)

        // Draw separator line
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 50, y: rect.height - 80))
        context.addLine(to: CGPoint(x: rect.width - 50, y: rect.height - 80))
        context.strokePath()
    }

    private func drawFooter(in rect: CGRect, context: CGContext, pageNumber: Int) {
        let footerText = "Generated by Kafeel • Page \(pageNumber) • \(Date().formatted(date: .abbreviated, time: .shortened))"
        drawText(footerText, at: CGPoint(x: 50, y: 30), fontSize: 10, color: .gray, context: context)
    }

    private func drawSectionTitle(_ title: String, at point: CGPoint, context: CGContext) {
        drawText(title, at: point, fontSize: 18, bold: true, context: context)
    }

    private func drawText(
        _ text: String,
        at point: CGPoint,
        fontSize: CGFloat,
        bold: Bool = false,
        color: NSColor = .black,
        context: CGContext
    ) {
        let font = bold ? NSFont.boldSystemFont(ofSize: fontSize) : NSFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(at: point)
    }

    private func drawLogo(in rect: CGRect, context: CGContext) {
        // Draw a simple bar chart icon as logo
        let colors = [
            NSColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1.0),
            NSColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0),
            NSColor(red: 0.6, green: 0.9, blue: 1.0, alpha: 1.0)
        ]

        let barWidth = rect.width / 4
        let barHeights: [CGFloat] = [0.6, 0.8, 0.4]

        for (index, height) in barHeights.enumerated() {
            let x = rect.minX + CGFloat(index) * (barWidth + 2)
            let barHeight = rect.height * height
            let y = rect.minY + (rect.height - barHeight) / 2

            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            context.setFillColor(colors[index].cgColor)
            context.fill(barRect)
        }
    }

    private func drawFocusScoreCard(
        focusScore: Double,
        productiveSeconds: Int,
        distractingSeconds: Int,
        neutralSeconds: Int,
        in rect: CGRect,
        context: CGContext
    ) {
        // Draw background
        context.setFillColor(NSColor(white: 0.95, alpha: 1.0).cgColor)
        context.fill(rect)

        // Draw score
        let scoreText = String(format: "%.1f", focusScore)
        let scoreFont = NSFont.boldSystemFont(ofSize: 48)
        let scoreAttributes: [NSAttributedString.Key: Any] = [
            .font: scoreFont,
            .foregroundColor: scoreColor(for: focusScore)
        ]
        let scoreString = NSAttributedString(string: scoreText, attributes: scoreAttributes)
        let scorePoint = CGPoint(x: rect.midX - 50, y: rect.midY + 10)
        scoreString.draw(at: scorePoint)

        // Draw time stats
        let totalSeconds = productiveSeconds + distractingSeconds + neutralSeconds
        let statsText = "Productive: \(formatDuration(productiveSeconds)) • Total: \(formatDuration(totalSeconds))"
        drawText(statsText, at: CGPoint(x: rect.minX + 20, y: rect.minY + 20), fontSize: 12, color: .gray, context: context)
    }

    private func drawTimeBreakdown(
        productiveSeconds: Int,
        distractingSeconds: Int,
        neutralSeconds: Int,
        totalSeconds: Int,
        at point: CGPoint,
        context: CGContext
    ) {
        guard totalSeconds > 0 else { return }

        let barWidth: CGFloat = 512
        let barHeight: CGFloat = 30
        let barRect = CGRect(x: point.x, y: point.y, width: barWidth, height: barHeight)

        // Draw segments
        var currentX = point.x

        // Productive
        let productiveWidth = barWidth * CGFloat(productiveSeconds) / CGFloat(totalSeconds)
        let productiveRect = CGRect(x: currentX, y: point.y, width: productiveWidth, height: barHeight)
        context.setFillColor(NSColor.green.cgColor)
        context.fill(productiveRect)
        currentX += productiveWidth

        // Distracting
        let distractingWidth = barWidth * CGFloat(distractingSeconds) / CGFloat(totalSeconds)
        let distractingRect = CGRect(x: currentX, y: point.y, width: distractingWidth, height: barHeight)
        context.setFillColor(NSColor.red.cgColor)
        context.fill(distractingRect)
        currentX += distractingWidth

        // Neutral
        let neutralWidth = barWidth * CGFloat(neutralSeconds) / CGFloat(totalSeconds)
        let neutralRect = CGRect(x: currentX, y: point.y, width: neutralWidth, height: barHeight)
        context.setFillColor(NSColor.gray.cgColor)
        context.fill(neutralRect)

        // Draw border
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.stroke(barRect)

        // Draw labels
        let labelY = point.y - 20
        drawText("Productive: \(formatDuration(productiveSeconds))", at: CGPoint(x: point.x, y: labelY), fontSize: 11, color: .green, context: context)
        drawText("Distracting: \(formatDuration(distractingSeconds))", at: CGPoint(x: point.x + 180, y: labelY), fontSize: 11, color: .red, context: context)
        drawText("Neutral: \(formatDuration(neutralSeconds))", at: CGPoint(x: point.x + 360, y: labelY), fontSize: 11, color: .gray, context: context)
    }

    private func drawAppUsageList(_ apps: [AppUsageStat], at point: CGPoint, context: CGContext) {
        var currentY = point.y

        for (index, app) in apps.enumerated() {
            let appText = "\(index + 1). \(app.appName)"
            let durationText = app.formattedDuration

            drawText(appText, at: CGPoint(x: point.x, y: currentY), fontSize: 12, context: context)
            drawText(durationText, at: CGPoint(x: point.x + 300, y: currentY), fontSize: 12, color: .gray, context: context)

            currentY -= 20
        }
    }

    private func drawFocusTrendChart(dailyScores: [DailyScore], at point: CGPoint, context: CGContext) {
        guard !dailyScores.isEmpty else { return }

        let chartWidth: CGFloat = 512
        let chartHeight: CGFloat = 150
        let chartRect = CGRect(x: point.x, y: point.y - chartHeight, width: chartWidth, height: chartHeight)

        // Draw background
        context.setFillColor(NSColor(white: 0.98, alpha: 1.0).cgColor)
        context.fill(chartRect)

        // Draw border
        context.setStrokeColor(NSColor.gray.cgColor)
        context.setLineWidth(1)
        context.stroke(chartRect)

        // Sort by date
        let sortedScores = dailyScores.sorted { $0.date < $1.date }

        // Draw line chart
        guard sortedScores.count > 1 else { return }

        let xStep = chartWidth / CGFloat(sortedScores.count - 1)
        let maxScore: CGFloat = 100

        context.setStrokeColor(NSColor.blue.cgColor)
        context.setLineWidth(2)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        for (index, score) in sortedScores.enumerated() {
            let x = chartRect.minX + CGFloat(index) * xStep
            let y = chartRect.minY + (CGFloat(score.focusScore) / maxScore) * chartHeight

            if index == 0 {
                context.move(to: CGPoint(x: x, y: y))
            } else {
                context.addLine(to: CGPoint(x: x, y: y))
            }
        }
        context.strokePath()

        // Draw axis labels
        drawText("0", at: CGPoint(x: point.x - 15, y: point.y - chartHeight), fontSize: 9, color: .gray, context: context)
        drawText("100", at: CGPoint(x: point.x - 25, y: point.y - 10), fontSize: 9, color: .gray, context: context)
    }

    private func drawStatsList(_ stats: [(String, String)], at point: CGPoint, context: CGContext) {
        var currentY = point.y

        for (label, value) in stats {
            drawText("\(label):", at: CGPoint(x: point.x, y: currentY), fontSize: 12, bold: true, context: context)
            drawText(value, at: CGPoint(x: point.x + 200, y: currentY), fontSize: 12, context: context)
            currentY -= 25
        }
    }

    private func drawGitCommitList(_ commits: [GitActivity], at point: CGPoint, context: CGContext) {
        var currentY = point.y

        for commit in commits {
            let shortHash = commit.shortHash
            let message = commit.message.prefix(60)
            let commitText = "\(shortHash) - \(message)"

            drawText(commitText, at: CGPoint(x: point.x, y: currentY), fontSize: 10, context: context)

            let statsText = "+\(commit.additions) -\(commit.deletions)"
            drawText(statsText, at: CGPoint(x: point.x + 400, y: currentY), fontSize: 10, color: .gray, context: context)

            currentY -= 18
            if currentY < 100 { break } // Don't overflow page
        }
    }

    private func drawCategoryBreakdown(categories: [URLCategory: [BrowsingActivity]], at point: CGPoint, context: CGContext) {
        var currentY = point.y

        let sortedCategories = categories.sorted { $0.value.count > $1.value.count }

        for (category, activities) in sortedCategories {
            let categoryText = category.displayName
            let countText = "\(activities.count) visits"

            drawText(categoryText, at: CGPoint(x: point.x, y: currentY), fontSize: 12, bold: true, context: context)
            drawText(countText, at: CGPoint(x: point.x + 200, y: currentY), fontSize: 12, color: .gray, context: context)

            currentY -= 25
        }
    }

    private func drawDomainList(_ domains: [(domain: String, count: Int)], at point: CGPoint, context: CGContext) {
        var currentY = point.y

        for (index, item) in domains.enumerated() {
            let domainText = "\(index + 1). \(item.domain)"
            let countText = "\(item.count) visits"

            drawText(domainText, at: CGPoint(x: point.x, y: currentY), fontSize: 11, context: context)
            drawText(countText, at: CGPoint(x: point.x + 350, y: currentY), fontSize: 11, color: .gray, context: context)

            currentY -= 20
        }
    }

    private func drawAchievementsList(_ achievements: [(emoji: String, title: String, value: String)], at point: CGPoint, context: CGContext) {
        var currentY = point.y

        for achievement in achievements {
            drawText("\(achievement.emoji) \(achievement.title)", at: CGPoint(x: point.x, y: currentY), fontSize: 14, bold: true, context: context)
            drawText(achievement.value, at: CGPoint(x: point.x + 250, y: currentY), fontSize: 14, context: context)
            currentY -= 35
        }
    }

    private func drawInsightsList(_ insights: [String], at point: CGPoint, context: CGContext) {
        var currentY = point.y

        for insight in insights {
            drawText("• \(insight)", at: CGPoint(x: point.x, y: currentY), fontSize: 12, context: context)
            currentY -= 25
        }
    }

    // MARK: - Helper Functions

    private func scoreColor(for score: Double) -> NSColor {
        switch score {
        case 80...: return .systemGreen
        case 60..<80: return .systemYellow
        case 40..<60: return .systemOrange
        default: return .systemRed
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

    private func calculateStreak(dailyScores: [DailyScore]) -> Int {
        guard !dailyScores.isEmpty else { return 0 }

        let sortedScores = dailyScores.sorted { $0.date > $1.date }
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for score in sortedScores {
            let scoreDate = Calendar.current.startOfDay(for: score.date)
            if scoreDate == currentDate && score.isProductiveDay {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return streak
    }

    private func generateInsights(dailyScores: [DailyScore], focusScore: Double) -> [String] {
        var insights: [String] = []

        if focusScore >= 80 {
            insights.append("Excellent focus score! You're in the top productivity tier.")
        } else if focusScore >= 60 {
            insights.append("Good focus score. Consider reducing distractions to reach 80+.")
        } else {
            insights.append("Focus score needs improvement. Try blocking distracting apps.")
        }

        let productiveDays = dailyScores.filter { $0.isProductiveDay }.count
        let totalDays = dailyScores.count
        if totalDays > 0 {
            let consistency = Double(productiveDays) / Double(totalDays) * 100
            if consistency >= 70 {
                insights.append("Great consistency! \(Int(consistency))% of days were productive.")
            } else {
                insights.append("Consistency could improve. Only \(Int(consistency))% of days were productive.")
            }
        }

        let peakDays = dailyScores.filter { $0.peakHourStart != nil }
        if !peakDays.isEmpty {
            insights.append("You have established peak productivity hours on \(peakDays.count) days.")
        }

        return insights
    }
}

// MARK: - Errors

public enum PDFExportError: Error, LocalizedError {
    case failedToGeneratePDF
    case failedToCreateContext
    case failedToRenderChart

    public var errorDescription: String? {
        switch self {
        case .failedToGeneratePDF:
            return "Failed to generate PDF document"
        case .failedToCreateContext:
            return "Failed to create graphics context"
        case .failedToRenderChart:
            return "Failed to render chart"
        }
    }
}
