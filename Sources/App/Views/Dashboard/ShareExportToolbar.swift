import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers
import KafeelCore

struct ShareExportToolbar: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var isExporting = false
    @State private var showShareMenu = false
    @State private var showSuccessAlert = false
    @State private var alertMessage = ""

    var body: some View {
        HStack(spacing: 12) {
            // Export PDF Button
            Button {
                Task {
                    await exportPDF()
                }
            } label: {
                HStack(spacing: 6) {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "doc.fill")
                    }
                    Text("Export PDF")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)

            // Share Menu
            Menu {
                Button {
                    copyToClipboard()
                } label: {
                    Label("Copy Summary to Clipboard", systemImage: "doc.on.clipboard")
                }

                Button {
                    showShareSheet()
                } label: {
                    Label("Share...", systemImage: "square.and.arrow.up")
                }

                Divider()

                Button {
                    exportJSON()
                } label: {
                    Label("Export as JSON", systemImage: "curlybraces")
                }

                Button {
                    emailSummary()
                } label: {
                    Label("Email Summary", systemImage: "envelope")
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                        .font(.system(size: 13, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .disabled(isExporting)
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Export PDF

    private func exportPDF() async {
        isExporting = true
        defer { isExporting = false }

        do {
            // Fetch daily scores for the time range
            let (startDate, endDate) = appState.selectedTimeFilter.dateRange(from: appState.selectedDate)
            let scoreDescriptor = FetchDescriptor<DailyScore>(
                predicate: #Predicate<DailyScore> { score in
                    score.date >= startDate && score.date < endDate
                }
            )
            let dailyScores = try modelContext.fetch(scoreDescriptor)

            // Generate PDF data
            let pdfData = try await PDFExportService.shared.generateReport(
                dailyScores: dailyScores,
                focusScore: appState.focusScore,
                productiveSeconds: appState.productiveSeconds,
                distractingSeconds: appState.distractingSeconds,
                neutralSeconds: appState.neutralSeconds,
                appUsageStats: appState.appUsageStats,
                gitActivities: appState.recentGitActivity,
                browsingActivities: appState.browsingActivities,
                timeFilter: appState.selectedTimeFilter,
                selectedDate: appState.selectedDate
            )

            // Show save panel
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.pdf]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            panel.title = "Export Dashboard as PDF"
            panel.message = "Choose where to save your productivity report"
            panel.nameFieldStringValue = generateFilename()

            let response = await panel.begin()

            if response == .OK, let url = panel.url {
                // Save PDF to selected location
                try PDFExportService.shared.saveReport(data: pdfData, to: url)

                // Show success notification
                alertMessage = "PDF exported successfully to \(url.lastPathComponent)"
                showSuccessAlert = true
            }
        } catch {
            alertMessage = "Failed to export PDF: \(error.localizedDescription)"
            showSuccessAlert = true
        }
    }

    private func generateFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: appState.selectedDate)

        let filterName = appState.selectedTimeFilter.rawValue.capitalized
        return "Kafeel-\(filterName)-Report-\(dateString).pdf"
    }

    // MARK: - Copy to Clipboard

    private func copyToClipboard() {
        let summary = ShareService.shared.generateTextSummary(
            appUsageStats: appState.appUsageStats,
            focusScore: appState.focusScore,
            productiveSeconds: appState.productiveSeconds,
            distractingSeconds: appState.distractingSeconds,
            neutralSeconds: appState.neutralSeconds,
            totalSeconds: appState.totalSeconds,
            gitCommitsCount: appState.recentGitActivity.count,
            timeFilter: appState.selectedTimeFilter,
            selectedDate: appState.selectedDate
        )

        ShareService.shared.copyToClipboard(summary)

        alertMessage = "Summary copied to clipboard"
        showSuccessAlert = true
    }

    // MARK: - Share Sheet

    private func showShareSheet() {
        let summary = ShareService.shared.generateTextSummary(
            appUsageStats: appState.appUsageStats,
            focusScore: appState.focusScore,
            productiveSeconds: appState.productiveSeconds,
            distractingSeconds: appState.distractingSeconds,
            neutralSeconds: appState.neutralSeconds,
            totalSeconds: appState.totalSeconds,
            gitCommitsCount: appState.recentGitActivity.count,
            timeFilter: appState.selectedTimeFilter,
            selectedDate: appState.selectedDate
        )

        // Get the current window to anchor the share sheet
        guard let window = NSApplication.shared.keyWindow,
              let contentView = window.contentView else { return }

        ShareService.shared.showShareSheet(
            items: [summary],
            from: contentView
        )
    }

    // MARK: - Export JSON

    private func exportJSON() {
        do {
            let jsonData = try ShareService.shared.generateJSONExport(
                appUsageStats: appState.appUsageStats,
                focusScore: appState.focusScore,
                productiveSeconds: appState.productiveSeconds,
                distractingSeconds: appState.distractingSeconds,
                neutralSeconds: appState.neutralSeconds,
                totalSeconds: appState.totalSeconds,
                gitCommitsCount: appState.recentGitActivity.count,
                timeFilter: appState.selectedTimeFilter,
                selectedDate: appState.selectedDate,
                activities: appState.todayActivities,
                gitActivities: appState.recentGitActivity
            )

            // Show save panel
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.canCreateDirectories = true
            panel.isExtensionHidden = false
            panel.title = "Export Data as JSON"
            panel.message = "Choose where to save your data"
            panel.nameFieldStringValue = generateJSONFilename()

            Task {
                let response = await panel.begin()

                if response == .OK, let url = panel.url {
                    try? jsonData.write(to: url)

                    alertMessage = "JSON exported successfully to \(url.lastPathComponent)"
                    showSuccessAlert = true
                }
            }
        } catch {
            alertMessage = "Failed to export JSON: \(error.localizedDescription)"
            showSuccessAlert = true
        }
    }

    private func generateJSONFilename() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: appState.selectedDate)

        return "Kafeel-Data-\(dateString).json"
    }

    // MARK: - Email Summary

    private func emailSummary() {
        let summary = ShareService.shared.generateTextSummary(
            appUsageStats: appState.appUsageStats,
            focusScore: appState.focusScore,
            productiveSeconds: appState.productiveSeconds,
            distractingSeconds: appState.distractingSeconds,
            neutralSeconds: appState.neutralSeconds,
            totalSeconds: appState.totalSeconds,
            gitCommitsCount: appState.recentGitActivity.count,
            timeFilter: appState.selectedTimeFilter,
            selectedDate: appState.selectedDate
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dateString = dateFormatter.string(from: appState.selectedDate)

        let subject = "Productivity Report - \(dateString)"

        ShareService.shared.shareViaEmail(
            summary: summary,
            subject: subject
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ActivityLog.self, AppCategory.self, AppSettings.self,
        configurations: config
    )

    let appState = AppState(modelContext: container.mainContext)

    ShareExportToolbar()
        .environment(appState)
        .padding()
        .frame(width: 400)
}
