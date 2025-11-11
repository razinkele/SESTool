# MarineSABRES DSS Improvement Plan
## Based on User Feedback and Testing Sessions

**Date:** November 5, 2025
**Version:** 1.3.0 Base
**Target Version:** 2.0.0 - "User Experience Overhaul"

---

## Executive Summary

User testing has revealed that while the DSS is technically functional, it suffers from significant usability issues that make it inaccessible to the target audience of stakeholders and policymakers. The system is currently optimized for scientists who already understand systems modeling, but not for general end-users.

**Critical Finding:** *"The DSS is not intuitive and requires extensive manual reading before use"*

### Key Problems Identified
1. **Complexity Overload**: Too many options, unclear starting point
2. **Technical Language**: Scientific terminology not accessible to stakeholders
3. **Lack of Guidance**: Insufficient inline help and explanations
4. **Navigation Issues**: Unclear workflow, difficult to correct entries
5. **AI Assistant Failure**: Not producing expected models
6. **Missing Functionality**: Auto-save, proper validation, user-friendly outputs

---

## Priority Matrix

```
┌─────────────────────────────────────────────────────┐
│ CRITICAL (Must Fix)     │ HIGH PRIORITY            │
│ - Auto-save             │ - Guided workflow        │
│ - AI Assistant repair   │ - Terminology simplif.   │
│ - Navigation clarity    │ - Inline help system     │
├─────────────────────────┼──────────────────────────┤
│ MEDIUM PRIORITY         │ LONG-TERM                │
│ - Templates/examples    │ - Template gallery       │
│ - Accessibility         │ - Collaborative editing  │
│ - Output explanations   │ - Mobile responsiveness  │
└─────────────────────────────────────────────────────┘
```

---

## CRITICAL ISSUES (Version 1.4.0 Target)

### 1. Auto-Save Functionality
**Problem:** Users lose work upon disconnection
**Impact:** Data loss, user frustration, trust issues
**Solution:**
- Implement automatic save every 30 seconds
- Add browser localStorage backup
- Show "Last saved: X minutes ago" indicator
- Implement session recovery on reconnection

**Implementation:**
```r
# modules/auto_save_module.R
- Reactive timer (30s intervals)
- saveRDS to temp directory
- localStorage via JavaScript
- Recovery modal on app load
```

**Affected Modules:** All data entry modules
**Effort:** 2 days
**Priority:** CRITICAL

---

### 2. AI Assistant Complete Overhaul
**Problem:**
- Only provides list of elements, not integrated model
- Zero elements in DAPSI(W)R(M) output
- No guidance on next steps
- Bug: adding everything instead of selected items

**Impact:** Core feature completely non-functional
**Solution:**
- Redesign AI workflow to build complete model step-by-step
- Add progress indicator showing: "Building Drivers... (2/7 steps)"
- Generate actual DAPSI(W)R(M) connections, not just lists
- Add validation and user confirmation at each step
- Fix selection bug - only add clicked items

**Implementation:**
```r
# modules/ai_isa_assistant_module.R
Phase 1: Element Generation
- Guide through each DAPSI(W)R(M) level
- Show preview of elements
- Allow edit before adding

Phase 2: Connection Building
- AI suggests connections with explanations
- User approves/rejects each connection
- Visual preview of emerging network

Phase 3: Model Completion
- Generate complete CLD
- Offer refinement options
- Export to Analysis module
```

**Affected Modules:** AI ISA Assistant
**Effort:** 5 days
**Priority:** CRITICAL

---

### 3. Clear Navigation and Workflow
**Problem:**
- Unclear how to go back or correct entries
- Sidebar vs. colored boxes pathways don't match
- Too many options, unclear starting point

**Impact:** Users get lost, abandon tool
**Solution:**
- Implement breadcrumb navigation
- Add "Previous" and "Next" buttons in data entry
- Show progress bar: "Step 2 of 7: Ecosystem Services"
- Add "Edit" option to go back to any completed step
- Consolidate navigation - one clear path

**Implementation:**
```r
# app.R - Navigation Enhancement
- Add breadcrumb UI component
- Implement navigation state management
- Add step validation before proceeding
- Enable edit mode for completed steps
- Add "Start Here" highlighted button on landing page
```

**UI Mockup:**
```
┌──────────────────────────────────────────────────┐
│ Home > Create SES > Standard Entry > Step 2 of 7 │
│ ←Back     Ecosystem Services    Next→           │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│ Progress: ████████░░░░░░░░░░░░░░░░░░ 30%       │
└──────────────────────────────────────────────────┘
```

**Affected Modules:** All modules
**Effort:** 3 days
**Priority:** CRITICAL

---

## HIGH PRIORITY (Version 1.5.0 Target)

### 4. Inline Help System ("i" Buttons Everywhere)
**Problem:** Technical terms unexplained, users don't know what to do
**Impact:** Confusion, errors, frustration
**Solution:**
- Add info icon (ⓘ) next to every technical term
- Create tooltip/popover explanations in plain language
- Include examples and context
- Make explanations available in all 7 languages

**Terms Requiring Explanation:**
- Edge, Node
- ISA, DAPSI(W)R(M)
- Page Rank, Centrality metrics
- BoolNet ready
- Acute/Chronic hazards
- All analytical terms

**Implementation:**
```r
# Create help content database
help_content <- list(
  edge = list(
    term = "Edge",
    simple = "Connection or relationship between two elements",
    detailed = "An edge represents how one element influences another...",
    example = "e.g., 'Fishing' → 'Fish stocks' shows fishing affects fish",
    icon = "arrow-right"
  ),
  # ... 100+ terms
)

# Add to every UI element
infoButton("edge", help_content$edge)
```

**Affected Modules:** All modules
**Effort:** 4 days
**Priority:** HIGH

---

### 5. Language Simplification and Glossary
**Problem:** Too scientific, not accessible to stakeholders
**Impact:** Users don't understand what they're doing
**Solution:**
- Replace scientific terms with plain language where possible
- Create visual glossary accessible from any page
- Add "Simple" / "Technical" language toggle
- Provide explanations in context

**Terminology Changes:**
| Current (Scientific) | Proposed (Simple) | Context |
|---------------------|-------------------|---------|
| Edge | Connection | "Add a connection between..." |
| Node | Element | "System element" |
| DAPSI(W)R(M) | Framework Levels | "Environmental Framework" |
| Page Rank | Influence Score | "How influential is this element?" |
| Betweenness | Bridge Score | "Does this connect different parts?" |
| ISA | Systems Analysis | "Analyze your system" |
| BoolNet ready | Simulation ready | "Ready for scenario testing" |

**Implementation:**
```r
# global.R - Language modes
LANGUAGE_MODE <- reactiveVal("simple")  # or "technical"

# Function to get appropriate term
getTerm <- function(key, mode = LANGUAGE_MODE()) {
  terms[[key]][[mode]]
}

# UI usage
h4(getTerm("edge"))  # Shows "Connection" in simple mode
```

**Affected Modules:** All modules
**Effort:** 3 days
**Priority:** HIGH

---

### 6. Guided Workflow with Progressive Disclosure
**Problem:** Too many options visible at once
**Impact:** Overwhelming, unclear where to start
**Solution:**
- Implement step-by-step wizard interface
- Show only relevant options at each step
- Add "Getting Started" tutorial on first use
- Use progressive disclosure: reveal advanced features only when needed

**Implementation:**
```r
# New module: guided_workflow_module.R
Onboarding Flow:
1. Welcome screen: "What would you like to do?"
   → Build a new model (Recommended)
   → Use a template
   → Import existing work
   → Learn about the system

2. If "Build new":
   → Simple questions (like EP but simplified)
   → Guided through each DAPSI(W)R(M) level
   → Only 3-4 fields visible at a time
   → Clear "Why am I doing this?" explanations

3. Progressive complexity:
   → Basic mode: Core features only
   → Advanced mode: All features
   → Expert mode: Full control
```

**UI Design:**
```
┌────────────────────────────────────────────────────┐
│  Getting Started                                   │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━  │
│                                                    │
│  Let's build your social-ecological system model  │
│                                                    │
│  Step 1: What is the main issue you want to       │
│  address? (e.g., declining fish stocks, water     │
│  pollution, coastal erosion)                       │
│                                                    │
│  [________________________________]                │
│                                                    │
│  ⓘ This will be the starting point for your      │
│     analysis                                       │
│                                                    │
│  [Skip Tutorial]              [Next Step →]       │
└────────────────────────────────────────────────────┘
```

**Affected Modules:** All modules
**Effort:** 5 days
**Priority:** HIGH

---

### 7. Persistent AI Chat Bot
**Problem:** No continuous guidance available
**Impact:** Users stuck without help
**Solution:**
- Add always-visible chat icon in bottom-right corner
- AI assistant can:
  - Explain any term
  - Guide through current step
  - Answer "What should I do next?"
  - Provide examples
  - Troubleshoot issues

**Implementation:**
```r
# modules/ai_chatbot_module.R
Features:
- Context-aware responses (knows what page user is on)
- Natural language queries
- Can execute actions: "Add this element for me"
- Learning mode: tracks common questions
- Multilingual support

UI:
- Floating chat icon (💬)
- Expandable chat window
- Quick actions: "Explain this page", "What's next?", "Show example"
```

**Technology:**
- Integration with OpenAI/Claude API
- Context injection from current page state
- Predefined responses for common questions
- Escalation to documentation links

**Affected Modules:** All modules
**Effort:** 6 days
**Priority:** HIGH

---

## MEDIUM PRIORITY (Version 1.6.0 Target)

### 8. Template System and Examples
**Problem:** Starting from scratch is overwhelming
**Impact:** Users don't know what a "good" model looks like
**Solution:**
- Provide 5-10 pre-built example models from different DAs
- Allow users to start with a template and modify
- Include completed Excel spreadsheet examples
- Add "Load example" button on every data entry page

**Templates to Include:**
1. Fisheries Management (Baltic Sea)
2. Coastal Pollution (Mediterranean)
3. Marine Protected Areas (Atlantic)
4. Aquaculture Impacts (North Sea)
5. Tourism vs. Conservation (Adriatic)
6. Climate Change Adaptation (Various)

**Implementation:**
```r
# data/templates/
- template_fisheries_baltic.rds
- template_pollution_mediterranean.rds
- ... etc

# modules/template_selector_module.R
UI:
- Template gallery with previews
- Filter by: region, issue type, complexity
- "Use this template" → loads into current project
- "View only" mode to explore without commitment
```

**Affected Modules:** Create SES, Template module
**Effort:** 4 days
**Priority:** MEDIUM

---

### 9. Simplified DTU Tool with Explanations
**Problem:**
- Tool too complex for policymakers
- Outputs not explained
- Results can be illogical
- Users worry about responsibility for wrong outputs

**Impact:** Tool not trusted, not used
**Solution:**
- Add prominent disclaimer about model limitations
- Explain every output metric in plain language
- Add "What does this mean?" button on results
- Implement sanity checks for illogical results
- Add confidence intervals and uncertainty visualization

**Implementation:**
```r
# modules/dtu_tool_module.R
Enhancements:

1. Disclaimer Modal (first use):
   "This tool provides scenario analysis based on your
   model structure. Results should be validated with
   domain experts and real-world data."

2. Output Explanations:
   - Each metric has "What is this?" tooltip
   - Results formatted as: "Intervention X may lead to
     Y% increase in fish stocks (Medium confidence)"
   - Color coding: Green (likely), Yellow (uncertain),
     Red (needs validation)

3. Sanity Checks:
   if (pollution_increase && wellbeing_increase) {
     showWarning("This result seems counterintuitive.
                 Please review your model connections.")
   }

4. Guided Management Measures:
   - Wizard for creating interventions
   - Examples of typical interventions
   - Impact prediction with uncertainty ranges
```

**Affected Modules:** DTU Tool, Response Measures
**Effort:** 5 days
**Priority:** MEDIUM

---

### 10. Enhanced Entry Point Questions
**Problem:**
- Too human-centric, missing nature/biodiversity questions
- Activity sectors need examples
- Hazards terms too technical
- Missing economic and socio-cultural hazards

**Impact:** Users can't properly define their system
**Solution:**
- Rebalance questions to include ecosystem perspective
- Add examples and descriptions for all sectors
- Simplify hazard terminology
- Add missing hazard categories

**Implementation:**
```r
# modules/entry_point_module.R

Enhanced Questions:

1. System Focus (NEW):
   [ ] Human activities and impacts
   [ ] Ecosystem health and biodiversity
   [ ] Integrated (human + nature)
   ⓘ Choose what aspect you want to focus on

2. Activity Sectors (ENHANCED):
   Each sector now has:
   - Description: "Commercial fishing involves..."
   - Examples: "Trawling, longlining, purse seining"
   - Icon for visual recognition
   Remove "multiple-mixed use" (redundant)

3. Risks and Hazards (SIMPLIFIED):
   Current: "Acute physical/chemical hazards"
   New: "Sudden events (storms, spills, etc.)"

   Add missing categories:
   - Economic risks (market crashes, job losses)
   - Social/cultural impacts (community displacement)
   - Ecosystem risks (species loss, habitat destruction)
```

**Affected Modules:** Entry Point
**Effort:** 3 days
**Priority:** MEDIUM

---

### 11. Improved Analysis Tool Functionality
**Problem:**
- Analytical functions not working (loop detection, metrics)
- Difficult to unselect links
- Can't see what changed (ID not dramatic enough)
- Can't edit node category or information
- No instruction that double-click is needed

**Impact:** Core analysis features unusable
**Solution:**
- Fix all broken analytical functions
- Add clear interaction instructions
- Improve visual feedback
- Enable full editing capabilities

**Implementation:**
```r
# modules/cld_visualization_module.R

Fixes:

1. Repair Functions:
   - Debug loop detection algorithm
   - Fix network metrics calculation
   - Test with various network sizes

2. Interaction Improvements:
   - Add persistent instruction panel:
     "Click: Select | Double-click: Edit | Right-click: Menu"
   - Single click to unselect
   - Hover tooltip: "Double-click to edit this element"

3. Visual Feedback:
   - Changed elements highlighted in yellow for 3 seconds
   - Before/after comparison view
   - Undo/redo functionality clearly visible

4. Editing Enhancements:
   - Right-click context menu: Edit, Delete, View details
   - Modal for editing all properties:
     - Name
     - Category (with validation)
     - Description
     - Metadata
   - Batch edit multiple nodes

5. Zoom Control:
   - Set minimum zoom level to prevent "lost graph"
   - Add "Fit to screen" button
   - Remember user's preferred zoom level
```

**Affected Modules:** CLD Visualization, Analysis Tools
**Effort:** 4 days
**Priority:** MEDIUM

---

### 12. Accessibility and UI Improvements
**Problem:**
- Small labels and fonts
- Poor color contrast
- Missing keyboard navigation
- Not screen-reader friendly

**Impact:** Excludes users with visual impairments
**Solution:**
- Increase base font size
- Improve color contrast ratios
- Add keyboard shortcuts
- Implement ARIA labels

**Implementation:**
```css
/* www/custom.css - Enhanced Accessibility */

:root {
  --base-font-size: 16px;  /* Increased from 14px */
  --min-contrast: 4.5:1;   /* WCAG AA standard */
}

/* Larger clickable areas */
.btn {
  min-height: 44px;
  min-width: 44px;
}

/* Clear focus indicators */
*:focus {
  outline: 3px solid #005fcc;
  outline-offset: 2px;
}
```

```r
# Keyboard shortcuts
shinyjs::runjs("
  document.addEventListener('keydown', function(e) {
    if (e.ctrlKey && e.key === 's') {
      // Trigger save
      Shiny.setInputValue('keyboard_save', true);
    }
    if (e.key === '?') {
      // Show help
      Shiny.setInputValue('keyboard_help', true);
    }
  });
")
```

**Affected Modules:** All modules
**Effort:** 3 days
**Priority:** MEDIUM

---

## TECHNICAL DEBT & BUG FIXES

### 13. Critical Bug Fixes
1. **Deleted nodes keep reappearing in reports**
   - Fix: Proper state management, ensure deletions persist
   - Effort: 1 day

2. **Intervention analysis inconsistent**
   - Fix: Debug state management, add proper validation
   - Effort: 2 days

3. **Translation issues**
   - Fix: Review and complete all translations
   - Add translation QA process
   - Effort: 2 days

4. **Report generation improvements**
   - Current state: "good and informative" ✓
   - Enhancement: Add more export formats (Word, PowerPoint)
   - Effort: 2 days

---

## LONG-TERM ENHANCEMENTS (Version 2.0+)

### 14. Advanced Features
1. **Template Gallery and Community Sharing**
   - Users can share their models (anonymized)
   - Browse models by region, issue type
   - Rating and commenting system
   - Effort: 2 weeks

2. **Real-time Collaborative Editing**
   - Multiple users work on same model
   - See others' cursors and changes
   - Chat integration
   - Effort: 3 weeks

3. **Mobile-Responsive Interface**
   - Adapt layout for tablets and phones
   - Touch-optimized interactions
   - Effort: 3 weeks

4. **Advanced AI Features**
   - Pattern recognition in user models
   - Suggest missing connections
   - Anomaly detection
   - Effort: 4 weeks

5. **Integration with External Tools**
   - Import/export to Vensim, Stella
   - GIS integration for spatial data
   - Statistical analysis integration (R, Python)
   - Effort: 4 weeks

---

## IMPLEMENTATION ROADMAP

### Phase 1: Critical Fixes (v1.4.0) - 2 weeks
**Sprint 1 (Week 1):**
- Day 1-2: Auto-save implementation
- Day 3-5: Navigation improvements (breadcrumbs, progress)

**Sprint 2 (Week 2):**
- Day 1-3: AI Assistant complete overhaul (Phase 1)
- Day 4-5: Bug fixes (deleted nodes, translations)

**Release:** v1.4.0 - "Usability Foundations"

---

### Phase 2: High Priority UX (v1.5.0) - 3 weeks
**Sprint 3 (Week 3):**
- Day 1-4: Inline help system implementation
- Day 5: Language simplification (terminology changes)

**Sprint 4 (Week 4):**
- Day 1-3: AI Assistant overhaul (Phase 2)
- Day 4-5: Guided workflow (Phase 1)

**Sprint 5 (Week 5):**
- Day 1-3: Persistent AI chatbot
- Day 4-5: Guided workflow (Phase 2)

**Release:** v1.5.0 - "User Experience Enhancement"

---

### Phase 3: Medium Priority (v1.6.0) - 3 weeks
**Sprint 6 (Week 6):**
- Day 1-4: Template system and examples
- Day 5: Entry point enhancements

**Sprint 7 (Week 7):**
- Day 1-3: Entry point completion
- Day 4-5: DTU tool simplification (Phase 1)

**Sprint 8 (Week 8):**
- Day 1-3: DTU tool completion
- Day 4-5: Analysis tool fixes, Accessibility improvements

**Release:** v1.6.0 - "Content and Polish"

---

### Phase 4: Long-term (v2.0.0) - 3 months
- Month 1: Template gallery and community features
- Month 2: Collaborative editing
- Month 3: Mobile responsiveness, advanced AI

**Release:** v2.0.0 - "Next Generation Platform"

---

## SUCCESS METRICS

### Before vs After (Expected Improvements)

| Metric | Current | Target (v1.6.0) |
|--------|---------|-----------------|
| Time to first successful model | 2-3 hours | 30 minutes |
| Users completing tutorial | 30% | 85% |
| Error rate (wrong entries) | High | < 10% |
| User satisfaction (NPS) | Unknown | > 70 |
| Support requests per user | Many | < 2 |
| AI assistant completion rate | 0% | > 75% |
| Feature discovery | 40% | > 80% |

### User Testing Checkpoints

**After v1.4.0:**
- Can users save and recover work? ✓
- Can users navigate back and forth easily? ✓
- Does AI assistant produce complete models? ✓

**After v1.5.0:**
- Do users understand all terminology? ✓
- Can users complete tasks without manual? ✓
- Is the workflow intuitive? ✓

**After v1.6.0:**
- Do templates help users get started? ✓
- Are outputs trusted and understood? ✓
- Is the tool accessible to all users? ✓

---

## RESOURCE REQUIREMENTS

### Team Composition (Recommended)
- 1 UX Designer (full-time)
- 2 R/Shiny Developers (full-time)
- 1 AI/ML Engineer (part-time)
- 1 Technical Writer (part-time)
- 1 QA Tester (part-time)

### Tools and Infrastructure
- User testing platform (UserTesting.com or similar)
- Analytics integration (track user behavior)
- AI API access (OpenAI/Anthropic)
- Translation services for multilingual help content

### Budget Estimate
- Phase 1-3 Development: 8 weeks × €10k/week = €80k
- User testing (4 rounds): €10k
- Infrastructure and tools: €5k
- **Total for v1.6.0: ~€95k**

---

## RISK MITIGATION

### Major Risks

1. **AI Assistant Complexity**
   - Risk: AI overhaul more complex than estimated
   - Mitigation: Start with rule-based system, add AI gradually
   - Fallback: Improve guided workflow as alternative

2. **User Adoption**
   - Risk: Users resistant to change
   - Mitigation: Gradual rollout, keep "classic mode" available
   - Communication: Clear benefits messaging

3. **Technical Debt**
   - Risk: Quick fixes create more problems
   - Mitigation: Code reviews, testing, documentation
   - Allocate 20% time to refactoring

4. **Scope Creep**
   - Risk: Feedback creates infinite feature requests
   - Mitigation: Strict prioritization, version gating
   - Quarterly review of roadmap

---

## CONCLUSION

The MarineSABRES DSS has a solid technical foundation but requires significant UX improvements to reach its target audience. The feedback is clear: simplify, guide, and explain.

**Key Priorities:**
1. **Don't lose user work** (auto-save)
2. **Fix broken features** (AI assistant, analytics)
3. **Guide the user journey** (progressive disclosure, help system)
4. **Speak their language** (plain terms, explanations)
5. **Build trust** (templates, examples, validation)

**Success Indicators:**
- Users can create a basic model in 30 minutes without a manual
- Technical terms are understood or hidden
- AI assistant successfully guides 75%+ of attempts
- Zero data loss incidents
- Positive user feedback: "Finally, I understand what I'm doing!"

**Timeline:** 8 weeks for critical and high priority improvements (v1.4.0 - v1.5.0)

**Next Steps:**
1. Approve improvement plan
2. Allocate resources
3. Begin Phase 1 development
4. Schedule user testing after v1.4.0
5. Iterate based on feedback

---

**Document Version:** 1.0
**Created:** November 5, 2025
**Author:** Based on user feedback compilation
**Status:** DRAFT - Awaiting approval
