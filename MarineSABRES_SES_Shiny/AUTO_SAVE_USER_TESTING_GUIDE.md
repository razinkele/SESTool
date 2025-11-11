# Auto-Save Feature - User Testing Guide

**Version:** 1.4.0-beta (Fixed)
**Date:** November 6, 2025
**Testing Duration:** 15-30 minutes
**Application URL:** http://127.0.0.1:3838

---

## Status Update: Critical Bug Fixed ✅

**IMPORTANT:** A critical infinite loop bug was discovered and fixed during initial testing. The auto-save module was triggering 4000+ saves per minute instead of the intended 1 save every 30 seconds.

**Fix Applied:** Added `isolate()` wrappers to break reactive dependencies
**Status:** Verified working at correct 30-second interval
**Safe to Test:** Yes ✅

---

## Before You Begin

### Application Status

✅ **App is running** at: http://127.0.0.1:3838
✅ **Auto-save fixed** and verified
✅ **Console monitoring** active for any issues

### What You're Testing

The auto-save feature prevents data loss by automatically saving your work every 30 seconds. You'll verify:

1. **Visual indicator** appears and updates correctly
2. **Automatic saving** happens at 30-second intervals
3. **Session recovery** works after unexpected closure
4. **Performance** remains smooth during saves
5. **No errors** or unexpected behavior

---

## Test Suite

### Test 1: Visual Indicator Presence (5 minutes)

**Objective:** Verify the auto-save indicator appears and is positioned correctly

#### Steps:

1. **Open browser** to http://127.0.0.1:3838
2. **Look at bottom-right corner** of the screen
3. **Find the save indicator:**
   - Should have an icon (💾, 🔄, or ✓)
   - Should show status text ("Auto-save enabled", "Saving...", or "All changes saved")
   - Should be fixed position (stays visible when scrolling)
   - Should have subtle shadow and border

#### Expected Results:

| Element | Expected | Pass/Fail |
|---------|----------|-----------|
| Indicator visible | Bottom-right corner, z-index 9999 | ⬜ |
| Icon present | One of: 💾 🔄 ✓ ⚠ | ⬜ |
| Status text | Human-readable message | ⬜ |
| Timestamp | "Last saved X seconds ago" (after first save) | ⬜ |
| Styling | White background, subtle shadow, rounded corners | ⬜ |

#### Screenshot Location:

📸 Take a screenshot of the indicator and save as: `screenshots/auto-save-indicator.png`

---

### Test 2: Automatic Save Timing (10 minutes)

**Objective:** Verify auto-save triggers at correct 30-second intervals

#### Steps:

1. **Create or modify data:**
   - Navigate to "Create SES" → "AI ISA Assistant"
   - Click "Start New Model"
   - Add a few elements (drivers, activities, etc.)
   - OR use any other data entry page

2. **Monitor the save indicator:**
   - Watch for status changes
   - Note the exact times when it shows "Saving..."
   - Verify it changes to "All changes saved" quickly

3. **Wait for 3 save cycles** (approximately 90 seconds)
   - Note the time of each save
   - Verify consistent 30-second intervals

#### Expected Results:

| Save # | Time | Interval from Previous | Status |
|--------|------|----------------------|--------|
| 1 | ___:___ | N/A (first save) | ⬜ |
| 2 | ___:___ | ~30 seconds | ⬜ |
| 3 | ___:___ | ~30 seconds | ⬜ |

**Acceptance Criteria:**
- ✅ Saves occur approximately every 30 seconds (±2 seconds tolerance)
- ✅ Indicator shows "Saving..." briefly during save
- ✅ Indicator shows "All changes saved" after save completes
- ✅ Timestamp updates after each save

---

### Test 3: Session Recovery (10 minutes)

**Objective:** Verify data recovery works after unexpected browser closure

#### Part A: Create Data and Close Browser

1. **Create substantial data:**
   - Add at least 5-10 elements to your SES model
   - Add several connections between elements
   - Wait for auto-save to trigger (check indicator says "All changes saved")

2. **Note your data:**
   - Count of drivers: _____
   - Count of activities: _____
   - Count of connections: _____
   - Any specific element names to verify later: _________________

3. **Close browser tab** (without using "Save" or "Export" buttons)
   - Just close the tab or window
   - Do NOT use application's save features

#### Part B: Reopen and Recover

4. **Reopen application:**
   - Navigate to http://127.0.0.1:3838 in a new browser tab
   - Wait for page to load

5. **Look for recovery modal:**
   - Should appear automatically
   - Should show title: "Unsaved Work Detected" or similar
   - Should display timestamp of last auto-save
   - Should offer two buttons: "Recover Data" and "Start Fresh"

6. **Click "Recover Data"**

7. **Verify data restoration:**
   - Navigate to the page where you created data
   - Count elements and verify they match your notes
   - Check specific element names you noted

#### Expected Results:

| Element | Expected | Pass/Fail |
|---------|----------|-----------|
| Recovery modal appears | Yes, automatically | ⬜ |
| Modal shows timestamp | Yes, recent time | ⬜ |
| "Recover Data" button | Present and clickable | ⬜ |
| Data restored | Matches pre-closure state | ⬜ |
| Element count correct | Drivers: ___ Activities: ___ | ⬜ |
| No data loss | All elements and connections present | ⬜ |

---

### Test 4: "Start Fresh" Option (5 minutes)

**Objective:** Verify "Start Fresh" clears auto-save and starts new session

#### Steps:

1. **Close browser** (if continuing from Test 3)
2. **Reopen application** at http://127.0.0.1:3838
3. **Wait for recovery modal** to appear
4. **Click "Start Fresh"** button
5. **Verify:**
   - Modal closes
   - Application starts with empty/default data
   - No previous data visible

#### Expected Results:

| Element | Expected | Pass/Fail |
|---------|----------|-----------|
| Modal closes | Yes, immediately | ⬜ |
| Data cleared | No previous data visible | ⬜ |
| Clean start | Application in default state | ⬜ |

---

### Test 5: Performance and Responsiveness (5 minutes)

**Objective:** Verify auto-save doesn't impact application performance

#### Steps:

1. **Perform normal operations:**
   - Navigate between pages
   - Add/edit multiple elements
   - Click buttons and interact with UI
   - Do this while auto-save is running (watch for indicator)

2. **Monitor for issues:**
   - UI freezing or lag
   - Delayed button responses
   - Jerky animations or transitions
   - Console errors (check browser developer tools F12)

3. **Check save indicator during heavy use:**
   - Add 10+ elements rapidly
   - Verify saves still occur at 30-second intervals
   - Verify no extra saves triggered

#### Expected Results:

| Metric | Expected | Pass/Fail |
|--------|----------|-----------|
| UI responsiveness | Smooth, no lag | ⬜ |
| Navigation | Instant page changes | ⬜ |
| Button clicks | Immediate response | ⬜ |
| Auto-save timing | Still 30 seconds, not faster | ⬜ |
| Console errors | None related to auto-save | ⬜ |

---

### Test 6: Multilingual Support (5 minutes)

**Objective:** Verify auto-save UI updates when changing language

#### Steps:

1. **Change application language:**
   - Look for language selector (usually in header or sidebar)
   - Try switching to: Spanish, French, German, or Lithuanian

2. **Observe save indicator:**
   - Status text should translate
   - "Saving..." → "Guardando..." (Spanish)
   - "All changes saved" → "Todos los cambios guardados" (Spanish)
   - "Last saved" → "Último guardado" (Spanish)

3. **Check recovery modal:**
   - Close and reopen browser
   - Modal title and buttons should be translated

#### Expected Results:

| Language | Indicator Translated | Recovery Modal Translated | Pass/Fail |
|----------|---------------------|--------------------------|-----------|
| Spanish | Yes | Yes | ⬜ |
| French | Yes | Yes | ⬜ |
| German | Yes | Yes | ⬜ |
| Other | Yes | Yes | ⬜ |

---

### Test 7: Long-Running Session (Optional, 15 minutes)

**Objective:** Verify auto-save remains stable over extended use

#### Steps:

1. **Keep application open** for 15 minutes
2. **Monitor save indicator:**
   - Count number of saves
   - Should be approximately 30 saves in 15 minutes
3. **Check for memory leaks:**
   - Open browser Task Manager (Shift+Esc in Chrome)
   - Monitor memory usage of tab
   - Should remain relatively stable (not constantly increasing)

#### Expected Results:

| Metric | Expected | Actual | Pass/Fail |
|--------|----------|--------|-----------|
| Saves in 15 min | ~30 saves | _____ | ⬜ |
| Memory usage | Stable (< 500 MB) | _____ MB | ⬜ |
| No console errors | 0 errors | _____ | ⬜ |

---

## Known Issues & Limitations

### Fixed Issues ✅

- ✅ **Infinite loop bug** - Was saving 4000+ times/minute, now fixed to 30-second interval
- ✅ **Reactive dependency leak** - Fixed with `isolate()` wrappers

### Current Limitations

1. **No manual save button** - Auto-save is automatic only, no "Save Now" button
   - **Impact:** Low - saves occur every 30 seconds automatically
   - **Future:** Manual save button planned for v1.4.1

2. **Recovery modal on every start** - If auto-save file exists, modal shows every time
   - **Impact:** Low - can click "Start Fresh" to dismiss
   - **Future:** "Don't ask again" preference planned

3. **Data-change observer disabled** - Saves only on 30-second timer, not on immediate data changes
   - **Impact:** Low - maximum data loss is 30 seconds of work
   - **Future:** Will re-enable with proper `isolate()` in v1.4.1

---

## Console Monitoring Guide

### How to Check Console

1. **Open Developer Tools:**
   - Chrome/Edge: Press `F12` or `Ctrl+Shift+I`
   - Firefox: Press `F12` or `Ctrl+Shift+K`
   - Safari: `Cmd+Option+I` (Mac)

2. **Go to "Console" tab**

3. **Monitor for auto-save messages:**
   - Should see: `[AUTO-SAVE] Saved at HH:MM:SS (Count: N)`
   - Every 30 seconds

### What to Look For

**✅ Good Console Output:**
```
[AUTO-SAVE] Saved at 10:43:33 (Count: 1)
[AUTO-SAVE] Saved at 10:44:03 (Count: 2)
[AUTO-SAVE] Saved at 10:44:33 (Count: 3)
```

**❌ Bad Console Output (Report Immediately):**
```
[AUTO-SAVE] Saved at 10:43:33 (Count: 1)
[AUTO-SAVE] Saved at 10:43:33 (Count: 2)  ← Too fast!
[AUTO-SAVE] Saved at 10:43:33 (Count: 3)  ← Too fast!
[AUTO-SAVE ERROR] ...                      ← Error!
```

**❌ Red Errors:**
- Any error message containing "auto-save", "localStorage", or "RDS"
- JavaScript exceptions
- Shiny reactive errors

---

## Reporting Issues

### If You Find a Problem

**Create an issue report with:**

1. **Test number** where problem occurred
2. **Exact steps** you performed
3. **Expected behavior**
4. **Actual behavior**
5. **Screenshots** if applicable
6. **Console errors** (copy/paste from developer tools)
7. **Browser and version** (e.g., Chrome 120, Firefox 121)
8. **Time** when issue occurred (check app console for timestamps)

### Example Issue Report

```
**Test:** Test 2 - Automatic Save Timing
**Steps:**
1. Opened app
2. Created 5 drivers in AI Assistant
3. Waited for 3 save cycles

**Expected:** Saves every 30 seconds
**Actual:** First save at 10:45:00, second save at 10:45:15 (only 15 seconds!)

**Console Output:**
[AUTO-SAVE] Saved at 10:45:00 (Count: 1)
[AUTO-SAVE] Saved at 10:45:15 (Count: 2)

**Browser:** Chrome 120
**Screenshot:** Attached
```

---

## Test Completion Checklist

After completing all tests, verify:

- ⬜ All tests passed (or issues documented)
- ⬜ No console errors observed
- ⬜ Auto-save timing is correct (30 seconds)
- ⬜ Recovery modal works properly
- ⬜ No performance issues
- ⬜ Translations work in multiple languages
- ⬜ Screenshots taken (if applicable)
- ⬜ Issue reports filed (if problems found)

---

## Quick Reference

| Feature | Expected Behavior |
|---------|------------------|
| **Save Interval** | Every 30 seconds |
| **Indicator Location** | Bottom-right corner |
| **Recovery Modal** | Shows on startup if auto-save exists |
| **Performance** | No UI lag or freezing |
| **Console Output** | `[AUTO-SAVE] Saved at...` every 30 sec |
| **Translations** | All 7 languages supported |

---

## Next Steps After Testing

### If All Tests Pass ✅

1. **Approve for release** - Feature is ready for beta testing
2. **Proceed to Option 2** - Beta release or Option 3 (Continue Priority 1)
3. **Update VERSION_INFO.json** - Mark as v1.4.0-beta (tested)

### If Issues Found ❌

1. **Document all issues** using format above
2. **Prioritize by severity:**
   - Critical: App unusable, data loss, crashes
   - High: Feature doesn't work as intended
   - Medium: Minor bugs, UI glitches
   - Low: Cosmetic issues, suggestions
3. **Decide:** Fix now or defer to v1.4.1

---

## Support

**Questions or Issues?**
- Check [BUG_AUTO_SAVE_INFINITE_LOOP.md](BUG_AUTO_SAVE_INFINITE_LOOP.md) for known fixed bug
- Review [AUTO_SAVE_INTEGRATION_SUMMARY.md](AUTO_SAVE_INTEGRATION_SUMMARY.md) for technical details
- Review [AUTO_SAVE_TEST_RESULTS.md](AUTO_SAVE_TEST_RESULTS.md) for automated test results

**Ready to Test:** The app is running at http://127.0.0.1:3838

**Estimated Time:** 15-30 minutes for all tests

---

**Testing Guide Version:** 1.0
**Date:** November 6, 2025
**Application Version:** 1.4.0-beta (Fixed)
**Status:** Ready for User Acceptance Testing
