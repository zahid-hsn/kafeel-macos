# Testing Git Activity Scanning

## Quick Start

### 1. Build and Run
```bash
cd /Users/zahid/workspace/new/kafeel/apps/macos-client
swift build
swift run KafeelClient
```

### 2. Configure Workspace
1. Click "Settings" in the sidebar
2. Scroll to "Workspace Configuration" section
3. Either:
   - Type your workspace path: `/Users/zahid/workspace/new`
   - Or click "Browse" and select the folder
4. Optionally enable "Auto-Scan Git Repositories"

### 3. Scan for Commits
1. Click "Git Activity" in the sidebar
2. Click "Scan Now" button in the top right
3. Watch the console for debug output
4. Wait for scan to complete

### 4. Verify Results
Expected behavior:
- ✅ Status shows "Last scan: [timestamp]"
- ✅ Repository dropdown shows found repos
- ✅ Timeline shows recent commits
- ✅ Stats cards show commit counts
- ✅ Contribution graph displays activity

## Debug Output

When scanning, you should see console output like:

```
GitActivityView: Starting repository scan
GitActivityView: Using workspace path from settings: /Users/zahid/workspace/new
GitService: Starting scan of 1 directories
GitService: Scanning directory: /Users/zahid/workspace/new
GitService: Found git repo at: /Users/zahid/workspace/new/kafeel
GitService: Found git repo at: /Users/zahid/workspace/new/kafeel/apps/macos-client
GitService: Found git repo at: /Users/zahid/workspace/new/kafeel/services/api
GitService: Scan complete. Found 3 repositories
GitActivityView: Found 3 repositories, fetching commits
GitService: Fetching commits from /Users/zahid/workspace/new/kafeel since 2025-10-29
GitService: Running git log --pretty=format:%H|%s|%an|%ad --date=iso-strict --since=2025-10-29 in /Users/zahid/workspace/new/kafeel
GitService: Found 2 commits in /Users/zahid/workspace/new/kafeel
GitService: Successfully parsed 2 commits from /Users/zahid/workspace/new/kafeel
...
GitActivityView: Scan complete. Found 6 total commits from 3 repositories
```

## Test Scenarios

### Test 1: No Workspace Set
**Expected:**
- Warning message: "No workspace folder set..."
- Scan still works, searches common directories
- Shows commits if found in default locations

### Test 2: Invalid Workspace Path
**Steps:**
1. Set workspace to non-existent path: `/invalid/path`
2. Click "Scan Now"

**Expected:**
- Red error banner: "Workspace folder does not exist: /invalid/path"
- No commits shown
- Error dismissible

### Test 3: Valid Workspace with Repos
**Steps:**
1. Set workspace to: `/Users/zahid/workspace/new`
2. Click "Scan Now"

**Expected:**
- Success message with scan time
- All repos found and listed
- Commits displayed in timeline
- Stats cards updated

### Test 4: Empty Workspace
**Steps:**
1. Set workspace to folder with no Git repos
2. Click "Scan Now"

**Expected:**
- Error: "No Git repositories found in the specified locations."
- Empty state with helpful message

### Test 5: Repository Filter
**Steps:**
1. Complete successful scan
2. Select specific repo from dropdown

**Expected:**
- Timeline shows only commits from selected repo
- Stats update accordingly

### Test 6: Time Range Filter
**Steps:**
1. Complete successful scan
2. Change time range (Today/Week/Month/All)

**Expected:**
- Timeline filters commits by date
- Stats recalculate for range

## Troubleshooting

### Issue: No commits showing
**Check:**
- Console logs for errors
- Workspace path is correct
- Repos have commits in last 3 months
- Git is installed: `which git` should show `/usr/bin/git`

### Issue: Scan button disabled
**Solution:** Wait for current scan to complete

### Issue: Date parsing errors
**Check console for:**
```
GitService: Failed to parse date: [datestring]
```
This should now be rare with improved parsing.

### Issue: Can't find .git folders
**Check:**
- Folder permissions
- Not using network drives (may be slow)
- Console shows scanning correct directory

## Manual Verification

### Check Git Commands Work
```bash
cd /Users/zahid/workspace/new/kafeel
git log --pretty=format:"%H|%s|%an|%ad" --date=iso-strict --since=2025-01-01 | head -5
```

Should output pipe-delimited commit data.

### Count Repositories
```bash
find /Users/zahid/workspace/new -name ".git" -type d
```

Should list all .git folders.

## Performance

Expected scan times:
- Single repo: < 1 second
- 10 repos: 2-5 seconds
- 50 repos: 10-20 seconds

Large monorepos may take longer for stat calculation.

## Success Criteria

✅ User can set workspace path via text field or file picker
✅ Scan button triggers repository search
✅ Found repositories are listed in dropdown
✅ Commits appear in timeline with correct data
✅ Stats cards show accurate counts
✅ Errors display helpful messages
✅ Console logs show detailed debug info
✅ Last scan time is recorded and displayed
✅ Empty states guide user to take action
