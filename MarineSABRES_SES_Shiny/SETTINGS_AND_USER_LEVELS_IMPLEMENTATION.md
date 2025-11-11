# Settings Menu & User Experience Levels - Implementation Plan

**Date:** 2025-11-08
**Feature:** Settings Dropdown + User Experience Levels (Beginner/Intermediate/Expert)
**Status:** Planning Phase

---

## 1. Overview

Consolidate app settings into a single Settings dropdown menu in the top bar that contains:
- Language selection (existing)
- About dialog (existing)
- **NEW:** User Experience Level selector (Beginner/Intermediate/Expert)

The user experience level will:
- Filter which sidebar menu items are visible
- Adjust terminology complexity throughout the app

---

## 2. Header Redesign

### Current Structure
```
[Globe + Language] [Help] [About] [User Info]
```

### New Structure
```
[Settings ▼] [Help] [User Info]
  └─ Language Selection
  └─ User Level Selection
  └─ About
```

---

## 3. User Experience Levels

### Level Definitions

#### 🟢 Beginner
**Target User:** First-time users, non-technical stakeholders, policy makers
**Menu Items Visible:**
- Getting Started ✅
- Dashboard ✅
- Create SES > AI Assistant ✅ (ONLY AI Assistant, hide others)
- ISA Data Entry (Simplified) ✅
- Visualization ✅

**Terminology:**
- Use simple, plain language
- Avoid acronyms (spell out DAPSI(W)R(M) as "Impact Chain")
- Use "Elements" instead of "Nodes"
- Use "Connections" instead of "Edges"
- Use "Impact Chain" instead of "DAPSI(W)R(M)"

#### 🟡 Intermediate
**Target User:** Regular users, marine managers, researchers
**Menu Items Visible:**
- Getting Started ✅
- Dashboard ✅
- PIMS Module (all subitems) ✅
- Create SES (all methods) ✅
- ISA Data Entry (all exercises) ✅
- Response Measures ✅
- Scenario Builder ✅
- Analysis Tools (basic tools only) ✅
- Visualization ✅
- Export/Import ✅

**Terminology:**
- Use standard terminology
- Show abbreviated acronyms with tooltips (e.g., "DAPSI(W)R(M)")
- Use "Nodes" and "Edges"
- Balance technical and accessible language

#### 🔴 Expert
**Target User:** Advanced users, modelers, data scientists
**Menu Items Visible:**
- ALL menu items ✅ (no filtering)

**Terminology:**
- Use full technical terminology
- Show all advanced options
- Use "Nodes", "Edges", "Centrality metrics", etc.
- No simplification

---

## 4. Implementation Steps

### Step 1: Create User Level State Management
- Add `user_level` reactiveVal (default: "intermediate")
- Persist in localStorage (`marinesabres_user_level`)
- Load on app startup

### Step 2: Modify Header
- Replace separate Language + About buttons with Settings dropdown
- Create dropdown menu with 3 items:
  - Language (opens language modal)
  - User Level (opens user level modal)
  - About (opens about modal)

### Step 3: Create User Level Modal
- Radio buttons for Beginner/Intermediate/Expert
- Description of each level
- Preview of what menu items will be visible
- Apply button (saves to localStorage and reloads)

### Step 4: Modify `generate_sidebar_menu()` Function
- Add logic to filter menu items based on `user_level`
- Create helper function: `should_show_menu_item(item_name, user_level)`
- Define menu visibility rules for each level

### Step 5: Terminology System (Phase 2)
- Create terminology mapping function
- Add alternative translation keys for beginner mode
- Examples:
  - `i18n$t("node", level = user_level)` → "Element" (beginner) or "Node" (expert)
  - `i18n$t("edge", level = user_level)` → "Connection" (beginner) or "Edge" (expert)

---

## 5. Menu Visibility Matrix

| Menu Item                  | Beginner | Intermediate | Expert |
|----------------------------|----------|--------------|--------|
| Getting Started            | ✅       | ✅           | ✅     |
| Dashboard                  | ✅       | ✅           | ✅     |
| PIMS Module                | ❌       | ✅           | ✅     |
| Create SES > Choose Method | ❌       | ✅           | ✅     |
| Create SES > Standard      | ❌       | ✅           | ✅     |
| Create SES > AI Assistant  | ✅       | ✅           | ✅     |
| Create SES > Excel Upload  | ❌       | ✅           | ✅     |
| ISA Data Entry             | ✅ (simplified) | ✅    | ✅     |
| Response Measures          | ❌       | ✅           | ✅     |
| Scenario Builder           | ❌       | ✅           | ✅     |
| Analysis Tools             | ❌       | ✅ (basic)   | ✅ (all) |
| Visualization              | ✅       | ✅           | ✅     |
| Export/Import              | ❌       | ✅           | ✅     |

---

## 6. Translation Keys to Add

```json
{
  "user_level": "User Experience Level",
  "user_level_beginner": "Beginner",
  "user_level_intermediate": "Intermediate",
  "user_level_expert": "Expert",
  "user_level_description_beginner": "Simplified interface for first-time users. Shows essential tools only.",
  "user_level_description_intermediate": "Standard interface for regular users. Shows most tools and features.",
  "user_level_description_expert": "Advanced interface showing all tools, technical terminology, and advanced options.",
  "select_your_experience_level": "Select your experience level with marine ecosystem modeling:",
  "user_level_modal_title": "User Experience Level",
  "user_level_will_reload": "The application will reload to apply the new user experience level.",
  "settings": "Settings"
}
```

---

## 7. Files to Modify

1. **app.R**
   - Header: Lines 238-286 (consolidate into Settings dropdown)
   - `generate_sidebar_menu()`: Lines 33-236 (add filtering logic)
   - Server: Add user_level reactiveVal and modal logic

2. **global.R**
   - Add user level persistence functions (if needed)

3. **translations/translation.json**
   - Add new translation keys (8 keys × 7 languages = 56 translations)

4. **www/custom.css**
   - Add styles for Settings dropdown menu
   - Add styles for user level selector

---

## 8. Testing Checklist

- [ ] Settings dropdown opens correctly
- [ ] Language selection still works
- [ ] About dialog still works
- [ ] User level selector displays correctly
- [ ] Changing to Beginner shows limited menu
- [ ] Changing to Intermediate shows standard menu
- [ ] Changing to Expert shows all menu items
- [ ] User level persists across sessions (localStorage)
- [ ] User level persists across page reloads
- [ ] All translations work correctly
- [ ] Menu items filter correctly for each level

---

## 9. Future Enhancements (Phase 2)

- Terminology adaptation based on user level
- Contextual help that adapts to user level
- Simplified workflows for beginner users
- Advanced analytics for expert users
- User level-specific tutorials

---

**Implementation Priority:** HIGH
**Estimated Complexity:** Medium-High
**Estimated Time:** 2-3 hours
**Dependencies:** None
**Breaking Changes:** None (all changes are additive)
