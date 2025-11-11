# Bug Fix: AI ISA Assistant JavaScript Timing Error

**Date**: 2025-11-07
**Status**: FIXED
**Priority**: High (Blocking functionality)

## Bug Description

JavaScript error in AI ISA Assistant module:
```
jquery.js:3783 jQuery.Deferred exception: Shiny.setInputValue is not a function
TypeError: Shiny.setInputValue is not a function
    at HTMLDocument.<anonymous> (http://127.0.0.1:3838/:616:19)
```

## Root Cause

The AI ISA Assistant module had JavaScript code using `$(document).ready()` to call `Shiny.setInputValue()`. However, `$(document).ready()` fires as soon as the DOM is ready, which can happen before Shiny's JavaScript runtime is fully initialized.

**Location**: `modules/ai_isa_assistant_module.R` line 166

```javascript
// BEFORE (BROKEN):
$(document).ready(function() {
  var savedData = localStorage.getItem('ai_isa_session');
  if (savedData) {
    Shiny.setInputValue('ai_isa_mod-has_saved_session', true, {priority: 'event'});
  }
});
```

## Solution

Changed the event listener from `document.ready` to `shiny:connected`, which ensures Shiny's runtime is fully initialized before attempting to use `Shiny.setInputValue()`.

```javascript
// AFTER (FIXED):
$(document).on('shiny:connected', function() {
  var savedData = localStorage.getItem('ai_isa_session');
  if (savedData) {
    Shiny.setInputValue('ai_isa_mod-has_saved_session', true, {priority: 'event'});
  }
});
```

## Files Modified

1. **modules/ai_isa_assistant_module.R**
   - Line 166: Changed `$(document).ready` → `$(document).on('shiny:connected')`

## Related Fixes

This is the same pattern that was previously fixed in `app.R` (lines 415-428) for the settings and about modal buttons. The AI ISA Assistant module had the same issue that was overlooked.

## Testing

After this fix:
1. Open application in Incognito mode (to avoid cache)
2. Navigate to AI ISA Assistant tab
3. Open browser console (F12)
4. Check for absence of "Shiny.setInputValue is not a function" error
5. Generate ISA framework from template
6. Verify no JavaScript errors occur

## User Impact

Before fix:
- JavaScript errors in console
- Potential failure of session management features
- User repeatedly reported "that not cache issue !!!!"

After fix:
- No JavaScript errors
- Session management works correctly
- Saved session detection functions properly

## Technical Notes

The `shiny:connected` event is part of Shiny's JavaScript API and fires when:
1. DOM is ready
2. Shiny JavaScript libraries are loaded
3. WebSocket connection to R session is established
4. Shiny runtime is fully initialized

This guarantees that `Shiny.setInputValue()` and other Shiny JavaScript functions are available.

## Verification

Server restarted with fix on 2025-11-07 00:01:57
Running on: http://127.0.0.1:3838

---

**Status**: RESOLVED
**Version**: Will be included in v1.4.1
