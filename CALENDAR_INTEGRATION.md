# Calendar Integration Guide

This document describes the Apple Calendar integration for the Kafeel macOS activity tracker.

## Overview

The Calendar integration uses EventKit to fetch events from Apple Calendar and analyze meeting vs focus time patterns.

## Architecture

### Core Components (KafeelCore module)

#### Models
- **CalendarEvent** (`Sources/Core/Models/CalendarEvent.swift`)
  - Wrapper for EKEvent with SwiftUI-friendly properties
  - Provides formatted time, duration, and convenience methods
  - Public API for use across modules

#### Services
- **CalendarService** (`Sources/Core/Services/CalendarService.swift`)
  - Singleton service using EventKit
  - Handles permission requests and event fetching
  - Provides meeting statistics and analytics
  - `@MainActor` for UI-safe operations

### UI Components (KafeelClient module)

#### Views
- **CalendarView** (`Sources/App/Views/Calendar/CalendarView.swift`)
  - Main calendar screen with day/week/month views
  - Integrates all calendar sub-components
  - Handles permission flow

- **CalendarPermissionView** (`Sources/App/Views/Calendar/CalendarPermissionView.swift`)
  - Shown when calendar permission not granted
  - Explains why permission is needed
  - Requests access and links to System Settings

- **DayScheduleView** (`Sources/App/Views/Calendar/DayScheduleView.swift`)
  - Hour-by-hour timeline (6 AM - 10 PM)
  - Visual event blocks with colors
  - Shows all-day events separately

- **WeekOverviewView** (`Sources/App/Views/Calendar/WeekOverviewView.swift`)
  - 7-column week view
  - Meeting load indicators per day
  - Week summary statistics

- **MeetingStatsCard** (`Sources/App/Views/Calendar/MeetingStatsCard.swift`)
  - Meeting statistics dashboard
  - Total meetings, meeting time, focus time
  - Busiest day analysis
  - Meeting load indicator

- **FocusMeetingChart** (`Sources/App/Views/Calendar/FocusMeetingChart.swift`)
  - Pie chart for time distribution
  - Daily bar chart for week view
  - Visual comparison of meeting vs focus time

## Permissions

### Info.plist Configuration

Add these keys to your Info.plist:

```xml
<key>NSCalendarsUsageDescription</key>
<string>Kafeel needs access to your calendar to show meeting times and calculate focus time.</string>

<key>NSCalendarsFullAccessUsageDescription</key>
<string>Kafeel needs full calendar access to analyze meeting patterns and help you optimize your productivity.</string>
```

### Permission Flow

1. On first launch, CalendarView checks authorization status
2. If not determined, automatically requests permission
3. If denied, shows CalendarPermissionView with:
   - Explanation of why permission is needed
   - Button to request permission again
   - Link to System Settings to manually enable

### Checking Status

```swift
let status = CalendarService.shared.authorizationStatus

switch status {
case .notDetermined:
    // Request permission
case .fullAccess:
    // Permission granted
case .denied, .restricted:
    // Show permission view
}
```

## Usage

### Fetching Events

```swift
let calendarService = CalendarService.shared

// Request access first
let granted = await calendarService.requestAccess()

if granted {
    // Fetch events for a date range
    let events = calendarService.fetchEvents(
        from: startDate,
        to: endDate
    )

    // Fetch events for today
    let todayEvents = calendarService.fetchEventsForDay(Date())

    // Fetch events for this week
    let weekEvents = calendarService.fetchEventsForWeek()

    // Fetch events for this month
    let monthEvents = calendarService.fetchEventsForMonth()
}
```

### Getting Meeting Statistics

```swift
// Get stats for a date range
let stats = calendarService.getMeetingStats(
    from: startDate,
    to: endDate
)

print("Total meetings: \(stats.meetingCount)")
print("Meeting time: \(stats.formattedTotalTime)")
print("Focus time: \(stats.formattedFocusTime)")
print("Meeting load: \(Int(stats.meetingPercentage))%")

// Get busiest day of week
if let busiest = calendarService.getBusiestDay(from: startDate, to: endDate) {
    print("Busiest day: \(busiest.day) with \(formatDuration(busiest.duration))")
}
```

### Meeting Time vs Focus Time

```swift
// Get meeting time for today
let meetingTime = calendarService.getMeetingTime(for: Date())

// Get available focus time (work hours - meetings)
let focusTime = calendarService.getFocusTime(for: Date())

// Focus time assumes 10-hour work day (8 AM - 6 PM)
```

## Data Models

### CalendarEvent

```swift
public struct CalendarEvent: Identifiable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let calendarColor: Color
    public let location: String?

    // Computed properties
    public var duration: TimeInterval
    public var formattedTime: String // "9:00 AM - 10:30 AM"
    public var formattedDuration: String // "1h 30m"

    // Methods
    public func overlaps(start: Date, end: Date) -> Bool
    public func isHappening(at date: Date) -> Bool
}
```

### MeetingStats

```swift
public struct MeetingStats {
    public let totalMeetingTime: TimeInterval
    public let averageMeetingDuration: TimeInterval
    public let meetingCount: Int
    public let meetingPercentage: Double // 0-100
    public let focusTime: TimeInterval

    // Formatted properties
    public var formattedTotalTime: String
    public var formattedAverageDuration: String
    public var formattedFocusTime: String
}
```

## View Modes

### Day View
- Hour-by-hour schedule (6 AM - 10 PM)
- Event blocks positioned by time
- All-day events shown separately
- Event list below schedule

### Week View
- 7-column overview (Mon-Sun)
- Meeting load indicators
- Daily breakdown chart
- Week summary statistics

### Month View
- Coming soon
- Event list for selected month

## Integration with Activity Tracking

The calendar integration is designed to work alongside the existing activity tracking:

1. **Compare Scheduled vs Actual**
   - Show calendar meetings vs actual app activity
   - Identify when meetings ran over
   - Track focus time outside of meetings

2. **Context for Focus Scores**
   - Lower focus scores during meeting blocks are expected
   - Highlight productive time outside meetings
   - Analyze distractions during scheduled focus time

3. **Meeting Analysis**
   - Compare meeting time with productive app usage
   - Identify meeting-heavy days
   - Optimize schedule for better focus

## Styling

The calendar views use consistent styling:
- Event colors from calendar settings
- Rounded corners and shadows for cards
- Meeting load indicators (green/yellow/orange/red)
- Swift Charts for data visualization
- Responsive layouts with proper spacing

## Testing

To test the calendar integration:

1. Grant calendar permission when prompted
2. Ensure you have events in Apple Calendar
3. Navigate to Calendar tab in the app
4. Switch between Day/Week/Month views
5. Verify event display and statistics

## Troubleshooting

### Permission Denied
- Check System Settings > Privacy & Security > Calendars
- Ensure Kafeel is enabled
- Click "Open System Settings" button in permission view

### No Events Showing
- Verify events exist in Apple Calendar
- Check date range is correct
- Ensure permission is granted (not just requested)

### Build Errors
- Ensure Info.plist includes permission keys
- Import EventKit in files using calendar features
- Make Core types `public` for cross-module access

## Future Enhancements

Potential improvements:
- Month view implementation
- Activity overlay on schedule (show app usage during meetings)
- Smart scheduling suggestions
- Meeting effectiveness tracking
- Integration with focus score algorithm
- Calendar event creation from app
- Sync with backend API
