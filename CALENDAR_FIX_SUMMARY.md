# Calendar Permission Flow - Debug Enhancement

## Changes Made

### 1. CalendarService.swift
**Location**: `/Users/zahid/workspace/new/kafeel/apps/macos-client/Sources/Core/Services/CalendarService.swift`

Added comprehensive debug logging to `requestAccess()` method:
- Logs when permission request starts
- Logs authorization status before request
- Logs the result of the permission request (granted/denied)
- Logs authorization status after request
- Logs detailed error information if request fails

This helps diagnose:
- If the system permission dialog is being shown
- What the authorization status is at each step
- Any errors that occur during the request

### 2. CalendarPermissionView.swift
**Location**: `/Users/zahid/workspace/new/kafeel/apps/macos-client/Sources/App/Views/Calendar/CalendarPermissionView.swift`

Enhanced `requestPermission()` method:
- Added debug logging at each step of the permission flow
- Added explicit `@MainActor` annotation to Task to ensure UI updates happen on main thread
- Logs when button is clicked
- Logs when service is called
- Logs the result
- Logs when callback is invoked

This helps diagnose:
- If the button click is being registered
- If the async task is executing
- If the callback is being called when permission is granted

### 3. CalendarView.swift
**Location**: `/Users/zahid/workspace/new/kafeel/apps/macos-client/Sources/App/Views/Calendar/CalendarView.swift`

Enhanced `checkPermission()` method:
- Added debug logging for current authorization status
- Added explicit `@MainActor` annotation to Task
- Logs different paths taken based on authorization status

This helps diagnose:
- What the initial authorization status is
- If auto-requesting is being triggered
- If the permission view is being shown correctly

## Info.plist Configuration

Verified that Info.plist contains required keys:
- `NSCalendarsUsageDescription` - Required for calendar access
- `NSCalendarsFullAccessUsageDescription` - Required for full calendar access on macOS 14+

Both keys are properly configured with descriptive messages.

## Testing Instructions

1. Build the app:
   ```bash
   swift build
   ```

2. Run the app:
   ```bash
   swift run KafeelClient
   ```

3. Navigate to the Calendar tab

4. Watch the console output for debug messages:
   ```
   CalendarView: Checking permission, current status = ...
   CalendarPermissionView: requestPermission called
   CalendarService: Requesting calendar access...
   CalendarService: Current status before request: ...
   CalendarService: Access granted = true/false
   ```

5. Expected flow:
   - First time: System dialog should appear asking for calendar permission
   - After granting: Should see "CalendarService: Access granted = true"
   - After granting: Should see calendar events load
   - If denied: Should stay on permission screen with option to open System Settings

## Debugging Tips

If permission is not working:

1. **Check Console Output**: Look for the debug messages to see where the flow stops

2. **Check System Preferences**: 
   - Open System Settings → Privacy & Security → Calendars
   - Verify if KafeelClient appears in the list
   - Check if permission is granted

3. **Reset Permissions** (if needed):
   ```bash
   tccutil reset Calendar com.kafeel.KafeelClient
   ```

4. **Clean Build** (if needed):
   ```bash
   swift package clean
   swift build
   ```

## Known Issues

- The `requestFullAccessToEvents()` API is only available on macOS 14+
- Current code doesn't have fallback for older macOS versions
- If running on macOS < 14, may need to add compatibility code

## Next Steps

If issues persist after these changes:
1. Check the console output to identify where the flow breaks
2. Verify the bundle identifier matches in Info.plist and System Settings
3. Consider adding fallback code for older macOS versions
4. Test on different macOS versions (14.0+)
