# Translation Extraction Summary

## Overview
Extracted and translated hard-coded English strings from three modules in parallel.

**Date:** 2025-11-02
**Total Strings Extracted:** 259 unique translation keys
**Languages:** 7 (en, es, fr, de, lt, pt, it)
**Total Translations Generated:** 1,813 (259 keys × 7 languages)

---

## Module 1: pims_module.R

**File:** `modules/pims_module.R`
**Strings Extracted:** 37 keys
**Translation File:** `pims_module_translations.json`
**Merge Script:** `merge_pims_module.R`

### Module Description
PIMS (Process & Information Management System) module with placeholder implementations for:
- Project Setup (name, demonstration area, focal issue, definition statement)
- System Scope (temporal scale, spatial scale, system in focus)
- Stakeholder Management
- Resources & Risks
- Data Management
- Evaluation

### String Categories Extracted
- **Headers & Titles:** "Project Setup", "Stakeholder Management", "Resources & Risks", "Data Management", "Evaluation"
- **Form Labels:** "Project Name:", "Demonstration Area:", "Focal Issue:", "Definition Statement:"
- **Placeholders:** "Enter project name...", "Describe the main issue...", "Project definition and objectives..."
- **Buttons:** "Save", "Add Stakeholder"
- **Notifications:** "Project information saved", "Add stakeholder functionality to be implemented"
- **Dropdown Options:** "Daily", "Monthly", "Yearly", "Decadal"
- **Tab Labels:** "Resources", "Risks"
- **Status Messages:** "Current Status", "Resource management to be implemented"

### Key Translation Examples
- `pims_project_setup`: "Project Setup" → ES: "Configuración del Proyecto", FR: "Configuration du Projet", DE: "Projekteinrichtung"
- `pims_temporal_scale`: "Temporal Scale:" → LT: "Laiko Skalė:", PT: "Escala Temporal:", IT: "Scala Temporale:"

---

## Module 2: ai_isa_assistant_module.R

**File:** `modules/ai_isa_assistant_module.R`
**Strings Extracted:** 67 keys
**Translation File:** `ai_isa_assistant_module_translations.json`
**Merge Script:** `merge_ai_isa_assistant_module.R`

### Module Description
AI-Assisted ISA Creation module - fully implemented interactive guide for building DAPSI(W)R(M) models with:
- Step-by-step conversation interface
- Session management (save/load)
- Connection review system
- Example templates (overfishing, pollution, tourism, climate change)
- Model preview and export to ISA Data Entry

### String Categories Extracted
- **Main UI Elements:**
  - Title: "AI-Assisted ISA Creation"
  - Subtitle: "Let me guide you step-by-step through building your DAPSI(W)R(M) model."
  - Progress indicators: "Your SES Model Progress"

- **Framework Elements:**
  - "Drivers:", "Activities:", "Pressures:", "State Changes:", "Impacts:", "Welfare:", "Responses:", "Measures:"
  - "Elements Created:", "Framework Flow:", "Current Framework:"

- **Session Management:**
  - "Save Progress", "Load Saved", "Auto-saved", "Not yet saved"
  - "Session saved successfully!", "Session restored successfully!"
  - Time indicators: "seconds ago", "minutes ago"

- **User Interactions:**
  - "Type your answer here...", "Submit Answer", "Quick options (click to add):"
  - "Review Suggested Connections", "Approve All", "Finish & Continue"
  - "Approve", "Reject", "All connections approved!"

- **Template System:**
  - "Load Example Template", "Choose a pre-built scenario:"
  - "Overfishing in Coastal Waters", "Marine Pollution & Plastics"
  - "Coastal Tourism Impacts", "Climate Change & Coral Reefs"

- **Modal Dialogs:**
  - "Restore Previous Session?", "Found a saved session from"
  - "Confirm Start Over", "Are you sure you want to start over?"
  - "Your DAPSI(W)R(M) Model Preview"

- **Buttons & Actions:**
  - "Preview Model", "Save to ISA Data Entry", "Start Over"
  - "Yes, Restore", "Cancel", "Close"

### Key Translation Examples
- `ai_isa_title`: "AI-Assisted ISA Creation" → ES: "Creación de ISA Asistida por IA", FR: "Création ISA Assistée par IA"
- `ai_isa_session_management`: "Session Management" → LT: "Sesijos Valdymas", PT: "Gestão de Sessão", IT: "Gestione Sessione"
- `ai_isa_model_saved`: "Model saved! Navigate to 'ISA Data Entry' to see your elements." (Full sentence translations provided for all languages)

---

## Module 3: pims_stakeholder_module.R

**File:** `modules/pims_stakeholder_module.R`
**Strings Extracted:** 155 keys
**Translation File:** `pims_stakeholder_module_translations.json`
**Merge Script:** `merge_pims_stakeholder_module.R`

### Module Description
Comprehensive PIMS Stakeholder Management module with NO existing i18n - extracted EVERYTHING from:
- **Tab 1: Stakeholder Register** - Add and manage stakeholder information
- **Tab 2: Power-Interest Analysis** - Visualize stakeholders on power-interest grid
- **Tab 3: Engagement Planning** - Plan and track engagement activities
- **Tab 4: Communication Plan** - Manage stakeholder communications
- **Tab 5: Analysis & Reports** - Statistics, charts, and export options

### String Categories Extracted

#### Main UI
- **Page Title:** "PIMS: Stakeholder Identification and Engagement"
- **Subtitle:** "Identify, analyze, and manage stakeholders for your marine social-ecological system project."
- **Tab Names:** "Stakeholder Register", "Power-Interest Analysis", "Engagement Planning", "Communication Plan", "Analysis & Reports"

#### Stakeholder Register (Tab 1)
- **Form Labels:**
  - "Stakeholder Name/Organization:", "Stakeholder Type:", "Primary Sector:"
  - "Contact Person/Details:", "Key Interests/Concerns:", "Role in System:"
  - "Power/Influence:", "Interest/Impact:", "Current Attitude:", "Engagement Level:"

- **Stakeholder Types (9 options):**
  - "Resource Users", "Industry/Business", "Government/Regulators"
  - "NGO/Civil Society", "Scientific/Academic", "Local Communities"
  - "Indigenous Groups", "Other"

- **Sectors (11 options):**
  - "Fisheries", "Aquaculture", "Tourism", "Shipping", "Energy"
  - "Conservation", "Research", "Policy/Management", "Multiple", "Other"

- **Rating Scales:**
  - Power/Interest: "High", "Medium", "Low"
  - Attitude: "Supportive", "Neutral", "Resistant", "Unknown"
  - Engagement: "Inform", "Consult", "Involve", "Collaborate", "Empower"

- **Placeholders:**
  - "e.g., Local Fishers Association"
  - "What does this stakeholder care about in the marine system?"
  - "What is their role? Decision-maker, user, affected party, etc."

#### Power-Interest Analysis (Tab 2)
- **Grid Labels:**
  - "Stakeholder Power-Interest Grid"
  - "Power-Interest Grid Classification"
  - Four quadrants with full descriptions:
    - "High Power, High Interest (Key Players): Engage closely and make greatest efforts to satisfy"
    - "High Power, Low Interest (Keep Satisfied): Keep satisfied but avoid excessive communication"
    - "Low Power, High Interest (Keep Informed): Keep informed and talk to regarding their interests"
    - "Low Power, Low Interest (Monitor): Monitor with minimum effort"

- **Summary Panel:**
  - "Grid Summary", "Clicked Stakeholder"
  - "Total Stakeholders:", "Key Players:", "Keep Satisfied:", "Keep Informed:", "Monitor:"

#### Engagement Planning (Tab 3)
- **Engagement Methods (11 options):**
  - "Workshop", "Interview", "Survey", "Focus Group"
  - "Public Meeting", "Advisory Committee", "Email/Newsletter"
  - "One-on-One Meeting", "Site Visit", "Other"

- **Form Fields:**
  - "Select Stakeholder:", "Engagement Method:", "Planned/Completed Date:"
  - "Engagement Objectives:", "Outcomes/Notes:", "Status:", "Facilitator/Contact:"

- **Status Options:**
  - "Planned", "Completed", "Cancelled", "Ongoing"

- **Placeholders:**
  - "What do you want to achieve?"
  - "What was achieved or learned?"
  - "Who is leading this?"

#### Communication Plan (Tab 4)
- **Audience Types (8 options):**
  - "All Stakeholders", "Key Players", "Government", "Industry"
  - "NGOs", "Local Communities", "Scientific Community", "Specific Stakeholder"

- **Communication Types (9 options):**
  - "Report", "Newsletter", "Presentation", "Website Update"
  - "Press Release", "Social Media", "Email", "Meeting Notes", "Other"

- **Frequency Options:**
  - "One-time", "Weekly", "Monthly", "Quarterly", "Annual", "As Needed"

- **Form Fields:**
  - "Target Audience:", "Communication Type:", "Date:", "Frequency:"
  - "Key Message/Content:", "Responsible Person:"

#### Analysis & Reports (Tab 5)
- **Chart Titles:**
  - "Stakeholder Statistics", "Engagement Coverage"
  - "Stakeholder Types Distribution", "Sector Distribution"

- **Export Options:**
  - "Download Full Report (Excel)"
  - "Download Power-Interest Grid (PNG)"
  - "Download Summary (PDF)"

#### Help Modal
- **Guide Sections:**
  - "PIMS: Stakeholder Identification and Engagement Guide"
  - "Purpose", "Key Concepts", "Using the Power-Interest Grid"
  - "Engagement Levels (IAP2 Spectrum)", "Workflow"

- **Key Messages:**
  - "Effective stakeholder engagement is critical for marine ecosystem management..."
  - "Remember: Stakeholder engagement is an ongoing process, not a one-time activity."

#### Notifications
- "Stakeholder added successfully!"
- "Deleted [X] stakeholder(s)"
- "No stakeholders selected"
- "Engagement activity added!"
- "Communication added!"

### Key Translation Examples
- `pims_sh_title`: "PIMS: Stakeholder Identification and Engagement" → Full translations maintaining professional terminology
- `pims_sh_key_players_action`: "Engage closely and make greatest efforts to satisfy" → Context-aware translations for engagement strategies
- `pims_sh_guide_purpose_text`: Full paragraph translation maintaining meaning and professional tone across all 7 languages

---

## Files Created

### Translation JSON Files (3)
1. **pims_module_translations.json** - 37 keys, 259 translations
2. **ai_isa_assistant_module_translations.json** - 67 keys, 469 translations
3. **pims_stakeholder_module_translations.json** - 155 keys, 1,085 translations

### Merge Scripts (3)
1. **merge_pims_module.R** - Merges PIMS module translations into main translation.json
2. **merge_ai_isa_assistant_module.R** - Merges AI ISA Assistant translations
3. **merge_pims_stakeholder_module.R** - Merges PIMS Stakeholder translations

### Utility Scripts (1)
1. **count_translation_keys.R** - Counts translation keys in each JSON file

---

## Translation Quality Standards

All translations follow these principles:

### 1. Professional Terminology
- Marine science terms translated accurately
- Stakeholder management terminology consistent with international standards
- Technical terms (DAPSI(W)R(M), ISA, etc.) maintain clarity

### 2. Context Awareness
- UI labels concise and clear
- Full sentences maintain natural flow
- Placeholders provide helpful examples
- Button text action-oriented

### 3. Consistency
- Same English term → same translation across all modules
- Parallel structure in lists maintained
- Formality level appropriate for scientific tool

### 4. Cultural Adaptation
- Date formats considered (though not modified in strings)
- Measurement systems maintained as scientific standards
- Professional register maintained in all languages

---

## Usage Instructions

### To Merge Translations into Main System:

```r
# Merge PIMS module
source("merge_pims_module.R")

# Merge AI ISA Assistant module
source("merge_ai_isa_assistant_module.R")

# Merge PIMS Stakeholder module
source("merge_pims_stakeholder_module.R")
```

### To Count Translation Keys:

```r
source("count_translation_keys.R")
```

---

## Statistics Summary

| Module | Translation Keys | Total Translations | Lines in JSON |
|--------|-----------------|-------------------|---------------|
| PIMS Module | 37 | 259 | 337 |
| AI ISA Assistant | 67 | 469 | 607 |
| PIMS Stakeholder | 155 | 1,085 | 1,400 |
| **TOTAL** | **259** | **1,813** | **2,344** |

---

## Issues Encountered

**None.** All modules processed successfully with comprehensive string extraction.

---

## Next Steps

1. **Review translations** - Native speakers should review translations for accuracy
2. **Merge into main system** - Run merge scripts to add to main translation.json
3. **Update module code** - Replace hard-coded strings with i18n$t() calls
4. **Test all languages** - Verify UI renders correctly in all 7 languages
5. **Documentation** - Update user documentation with multilingual screenshots

---

## Patterns Identified for Future Extraction

### Common UI Patterns
- Form labels typically end with ":"
- Placeholders use "..." to indicate user input
- Button text is imperative (action verbs)
- Notifications use complete sentences
- Tab names are short noun phrases

### Hard-Coded String Locations
- textInput labels and placeholders
- selectInput choices and labels
- actionButton labels
- modal dialog titles and content
- notification messages
- help text and descriptions
- plot titles and axis labels
- table headers

### Recommended i18n Implementation Pattern
```r
# Before
textInput(ns("project_name"), "Project Name:",
         placeholder = "Enter project name...")

# After
textInput(ns("project_name"), i18n$t("pims_project_name"),
         placeholder = i18n$t("pims_enter_project_name"))
```

---

## Module-Specific Notes

### PIMS Module
- Mostly placeholder implementations
- Focus on project setup and metadata
- Simple structure, few interactive elements
- Translation straightforward

### AI ISA Assistant Module
- Most complex module with rich UI
- Session management strings critical
- Template names should remain recognizable
- Connection review language must be clear

### PIMS Stakeholder Module
- Largest translation set (155 keys)
- Most user-facing content
- Professional stakeholder management terminology
- IAP2 spectrum terminology requires accuracy
- Power-Interest Grid quadrant descriptions are critical
- Help modal content extensive and important

---

## Validation Checklist

- [x] All hard-coded English strings extracted
- [x] Translations provided for all 7 languages (en, es, fr, de, lt, pt, it)
- [x] JSON structure valid and consistent
- [x] Merge scripts created and tested
- [x] Translation keys follow naming convention (module_category_item)
- [x] Placeholders maintain clarity across languages
- [x] Button text remains concise
- [x] Full sentences maintain grammatical structure
- [x] Technical terms handled appropriately
- [x] No duplicate keys between modules

---

**Generated by:** Claude Code AI Assistant
**Project:** MarineSABRES SES Toolbox
**Translation Framework:** shiny.i18n
