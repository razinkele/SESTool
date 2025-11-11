# Settings & User Levels - Implementation Summary

**Status:** Ready to implement
**Estimated Time:** 2-3 hours
**Complexity:** High

---

## What Will Be Implemented

### 1. **Settings Dropdown Menu** (Header Consolidation)

**Current Header:**
```
[🌐 Language] [❓ Help] [ℹ️ About] [👤 User]
```

**New Header:**
```
[⚙️ Settings ▼] [❓ Help] [👤 User]
   ├─ Language Selection
   ├─ User Experience Level
   └─ About
```

### 2. **User Experience Levels**

Three levels with different menu visibility and terminology:

#### 🟢 **Beginner Mode**
- **Target:** First-time users, policy makers, non-technical stakeholders
- **Shows:** Essential tools only (Getting Started, AI Assistant, Basic Visualization)
- **Hides:** PIMS, Advanced Analysis, Technical Tools
- **Terminology:** "Impact Chain" instead of "DAPSI(W)R(M)", "Elements" instead of "Nodes"

#### 🟡 **Intermediate Mode** (DEFAULT)
- **Target:** Regular users, marine managers, researchers
- **Shows:** Most features (current experience)
- **Hides:** Only most advanced technical tools
- **Terminology:** Standard with tooltips

#### 🔴 **Expert Mode**
- **Target:** Advanced users, modelers, data scientists
- **Shows:** ALL features and advanced options
- **Hides:** Nothing
- **Terminology:** Full technical terminology

---

## Implementation Steps

### ✅ Step 1: Translation Keys (56 new translations)
Add 8 new keys × 7 languages to `translations/translation.json`:
- `settings`
- `user_level`
- `user_level_beginner`
- `user_level_intermediate`
- `user_level_expert`
- `user_level_description_beginner`
- `user_level_description_intermediate`
- `user_level_description_expert`

### ✅ Step 2: CSS Styles
Add to `www/custom.css`:
- Settings dropdown menu styles
- User level selector styles
- Badges for experience levels (colored icons)

### ✅ Step 3: Header Redesign
Modify `app.R` header (lines 238-286):
- Remove separate Language/About buttons
- Create Settings dropdown with 3 menu items
- Keep Help and User Info buttons

### ✅ Step 4: User Level State Management
Add to `app.R` server section:
- `user_level <- reactiveVal("intermediate")` (default)
- Load from localStorage on startup
- Save to localStorage on change

### ✅ Step 5: User Level Modal
Create modal dialog with:
- Radio button selector (Beginner/Intermediate/Expert)
- Description cards for each level
- Preview of visible menu items
- Apply button (reloads app with new level)

### ✅ Step 6: Menu Filtering Logic
Modify `generate_sidebar_menu()` function:
- Add `should_show_item(item_name, user_level)` helper
- Filter menu items based on user level
- Define visibility rules per the matrix below

### ✅ Step 7: Testing
- Test all three user levels
- Verify localStorage persistence
- Check menu filtering
- Verify translations

---

## Menu Visibility Matrix

| Menu Item                     | Beginner | Intermediate | Expert |
|-------------------------------|----------|--------------|--------|
| Getting Started               | ✅       | ✅           | ✅     |
| Dashboard                     | ✅       | ✅           | ✅     |
| **PIMS Module**               | ❌       | ✅           | ✅     |
| - Project Setup               | ❌       | ✅           | ✅     |
| - Stakeholders                | ❌       | ✅           | ✅     |
| - Resources & Risks           | ❌       | ✅           | ✅     |
| - Data Management             | ❌       | ✅           | ✅     |
| - Evaluation                  | ❌       | ✅           | ✅     |
| **Create SES**                | Partial  | ✅           | ✅     |
| - Choose Method               | ❌       | ✅           | ✅     |
| - Standard Entry              | ❌       | ✅           | ✅     |
| - AI Assistant                | ✅       | ✅           | ✅     |
| - Excel Upload                | ❌       | ✅           | ✅     |
| **ISA Data Entry**            | ✅       | ✅           | ✅     |
| **Response Measures**         | ❌       | ✅           | ✅     |
| **Scenario Builder**          | ❌       | ✅           | ✅     |
| **Analysis Tools**            | ❌       | Partial      | ✅     |
| - Network Metrics             | ❌       | ✅           | ✅     |
| - Deleted Nodes               | ❌       | ❌           | ✅     |
| - Intervention Analysis       | ❌       | ✅           | ✅     |
| **Visualization**             | ✅       | ✅           | ✅     |
| **Export/Import**             | ❌       | ✅           | ✅     |

---

## Files That Will Be Modified

1. **translations/translation.json** (~50 lines added)
2. **www/custom.css** (~100 lines added)
3. **app.R** (~300 lines modified/added)
   - Header section (lines 238-286)
   - `generate_sidebar_menu()` function (lines 33-236)
   - Server section (add user level logic)

---

## Risks & Considerations

### ⚠️ **Potential Issues:**
1. **Menu filtering complexity** - Need careful testing for each level
2. **localStorage persistence** - Must handle missing/corrupted values
3. **Translation coverage** - All 56 new translations must be accurate
4. **Backward compatibility** - Existing users default to "intermediate" (current experience)

### ✅ **Mitigations:**
1. Comprehensive testing checklist
2. Default fallback to "intermediate" if localStorage fails
3. Gradual rollout (can be hidden behind feature flag if needed)
4. No breaking changes - purely additive feature

---

## User Experience Flow

### First-Time User:
1. Sees default "Intermediate" level
2. Clicks Settings → "User Experience Level"
3. Modal shows three options with descriptions
4. Selects "Beginner" → App reloads
5. Menu now shows simplified interface

### Returning User:
1. App loads with previously selected level (from localStorage)
2. Can change anytime via Settings menu
3. Preference persists across sessions

---

## Next Phase (Phase 2 - Future)

### Terminology Adaptation (Not in this implementation)
- Create `t_level()` function for level-aware translations
- Add beginner-friendly term mappings:
  - "DAPSI(W)R(M)" → "Impact Chain"
  - "Node" → "Element"
  - "Edge" → "Connection"
  - "Centrality" → "Importance"
- Implement throughout all modules

### Contextual Help (Not in this implementation)
- Add inline help that adapts to user level
- Beginner: More detailed explanations
- Expert: Concise technical notes

---

## Decision Required

Given the complexity (2-3 hours, ~450 lines of code), would you like me to:

1. **✅ PROCEED** with full implementation as planned
2. **⏸️ PAUSE** - Show you a working prototype of just the Settings dropdown first
3. **📝 MODIFY** - Adjust the plan based on specific requirements

Please confirm to proceed, or let me know if you'd like any modifications to the plan.
