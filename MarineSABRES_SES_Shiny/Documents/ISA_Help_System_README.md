# ISA Data Entry Module - Help System Documentation

## Overview

The ISA Data Entry module now includes a comprehensive, multi-layered help system to guide users through the Integrated Systems Analysis process using the DAPSI(W)R(M) framework.

## Help System Components

### 1. In-App Contextual Help Modals

**Location:** Help buttons (?) throughout the ISA Data Entry module

**Features:**
- **Main Framework Guide Button:** Top-right of module header - provides DAPSI(W)R(M) overview
- **Exercise-Specific Help Buttons:** On each of the 13 exercise tabs
- **Large, scrollable modal dialogs** with comprehensive guidance
- **Easy to access:** Single click opens detailed help
- **Easy to dismiss:** Click outside modal or close button

**Content Includes:**
- Purpose and objectives of each exercise
- Step-by-step instructions
- Field-by-field explanations
- Practical examples from marine case studies
- Tips and best practices
- Common pitfalls to avoid
- Links between exercises

**Exercises Covered:**
1. Exercise 0: Unfolding Complexity
2. Exercise 1: Goods & Benefits
3. Exercise 2a: Ecosystem Services
4. Exercise 2b: Marine Processes & Functioning
5. Exercise 3: Pressures
6. Exercise 4: Activities
7. Exercise 5: Drivers
8. Exercise 6: Closing the Loop
9. Exercises 7-9: Causal Loop Diagram Creation (Kumu)
10. Exercises 10-12: Analysis, Metrics, and Validation
11. BOT Graphs: Behaviour Over Time

### 2. Comprehensive User Guide

**File:** `Documents/ISA_User_Guide.md`

**Access:**
- From **Data Management** tab → "Documentation" section → "Open User Guide" button
- Direct file access in Documents folder

**Contents:**
- **Introduction:** What is ISA, who should use it, key features
- **Getting Started:** Interface overview, accessing help
- **DAPSI(W)R(M) Framework:** Complete explanation with diagrams
- **Step-by-Step Workflow:** Recommended sequence, time requirements
- **Exercise-by-Exercise Guide:** Detailed instructions for all 13 exercises
- **Working with Kumu:** Complete Kumu tutorial and styling guide
- **Data Management:** Import/export, saving, collaboration workflows
- **Tips and Best Practices:** General workflow tips, data quality, CLD development
- **Troubleshooting:** Common issues and solutions
- **Glossary:** All technical terms defined
- **Quick Reference Card:** Checklist and shortcuts

**Format:** Markdown (readable in text editors, VS Code, GitHub, etc.)

**Length:** ~900 lines of comprehensive documentation

### 3. Source Documentation

**MarineSABRES Simple SES DRAFT Guidance PDF**
- **File:** `Documents/MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- **Access:** Via Data Management tab or direct file access
- **Content:** 65-page scientific guidance document
- **Use:** Detailed methodological background, academic references

**Kumu Styling Code**
- **File:** `Documents/Kumu_Code_Style.txt`
- **Access:** Via Data Management tab or direct file access
- **Content:** CSS-style code for Kumu visualization
- **Use:** Copy-paste into Kumu to apply color scheme and styling

### 4. Documentation Access Points

**Within the App:**

1. **Main Framework Guide:** Click "ISA Framework Guide" button at top of module
2. **Exercise Help:** Click "Help" button on any exercise tab
3. **Data Management Tab:** Three documentation buttons:
   - Open User Guide
   - ISA Guidance Document (PDF)
   - Kumu Styling Code

**File System:**
- All documentation in `Documents/` folder
- User guide: `ISA_User_Guide.md`
- Source guidance: `MarineSABRES_Simple_SES_DRAFT_Guidance.pdf`
- Kumu code: `Kumu_Code_Style.txt`
- This README: `ISA_Help_System_README.md`

## How Users Learn the System

### For New Users

**Quick Start (30 minutes):**
1. Click "ISA Framework Guide" to understand DAPSI(W)R(M)
2. Read Exercise 0 help to understand scoping
3. Start entering data, clicking help as needed
4. Use contextual help modals for just-in-time guidance

**Comprehensive Learning (2-3 hours):**
1. Read User Guide introduction and framework sections
2. Review step-by-step workflow
3. Read exercise-by-exercise guide before starting work
4. Refer to User Guide for tips and troubleshooting

**Deep Dive (1 day):**
1. Read complete User Guide
2. Study the 65-page guidance PDF
3. Review Kumu documentation and tutorials
4. Practice with example case study

### For Experienced Users

- **Quick reference:** Use in-app help buttons for reminders
- **Troubleshooting:** Check User Guide troubleshooting section
- **Advanced topics:** Refer to guidance PDF for methodology
- **Kumu styling:** Copy code from Kumu_Code_Style.txt

## Content Source and Accuracy

**All help content is derived from:**
- `MarineSABRES_Simple_SES_DRAFT_Guidance.pdf` (65 pages)
- DAPSI(W)R(M) framework literature
- Kumu documentation and best practices
- Marine SES analysis best practices

**Content covers:**
- Scientific methodology
- Practical implementation
- Software tools (Kumu)
- Data management
- Stakeholder engagement
- Validation approaches

## Help System Features

### Searchability
- User Guide is markdown → searchable with Ctrl+F
- Glossary provides quick term lookup
- Table of contents with section links

### Examples
- Every exercise includes marine case study examples
- Real-world scenarios (Baltic Sea fisheries, coastal tourism, etc.)
- Example data entries with proper formatting

### Progressive Disclosure
- High-level overview at top of module
- Exercise-specific details in modals
- Deep methodology in PDF guidance
- Users choose depth based on needs

### Multiple Learning Styles
- **Visual learners:** Diagrams, flowcharts, Kumu visuals
- **Text learners:** Detailed written explanations
- **Hands-on learners:** Step-by-step instructions
- **Example-based learners:** Extensive marine case examples

## Maintenance and Updates

### Updating Help Content

**In-App Modals:**
- Edit `modules/isa_data_entry_module.R`
- Find `observeEvent(input$help_...)` sections
- Update modal content within `showModal(modalDialog(...))`

**User Guide:**
- Edit `Documents/ISA_User_Guide.md`
- Standard markdown format
- Preview changes in markdown viewer

**Source Documents:**
- Replace PDF and TXT files in `Documents/` folder
- Update file links if filenames change

### Version Control
- User Guide includes version number and date
- Update when making significant changes
- Note version in app.R if needed

## Technical Implementation

### Modal Help System
- Uses Shiny's `modalDialog()` function
- Size: "l" (large) for readability
- easyClose: TRUE (click outside to dismiss)
- Structured with h4, h5, tags$ul, tags$li for clarity

### Documentation Links
- Standard HTML links using `tags$a()`
- Open in new tab: `target = "_blank"`
- Bootstrap button styling for consistency
- Icons from Font Awesome

### File Structure
```
MarineSABRES_SES_Shiny/
├── modules/
│   └── isa_data_entry_module.R  # Contains all help modals
├── Documents/
│   ├── ISA_User_Guide.md        # Main user documentation
│   ├── ISA_Help_System_README.md # This file
│   ├── MarineSABRES_Simple_SES_DRAFT_Guidance.pdf
│   ├── Kumu_Code_Style.txt
│   └── ISA Excel Workbook.xlsx
```

## Help System Statistics

**In-App Help Modals:** 11 comprehensive modals
- Main Framework Guide: ~60 lines
- Exercise 0: ~40 lines
- Exercise 1: ~55 lines
- Exercise 2a: ~50 lines
- Exercise 2b: ~55 lines
- Exercise 3: ~50 lines
- Exercise 4: ~60 lines
- Exercise 5: ~60 lines
- Exercise 6: ~55 lines
- Exercises 7-9: ~65 lines
- Exercises 10-12: ~90 lines
- BOT Graphs: ~70 lines

**User Guide:** ~900 lines, ~10,000 words

**Total Help Content:** ~1,600 lines of documentation

## User Feedback Integration

**Future improvements based on user feedback:**
- Video tutorials (link from User Guide)
- Interactive walkthroughs
- More case study examples
- FAQ section
- Community forum links

## Related Documentation

- **App README:** General application documentation
- **Installation Guide:** Setup and dependencies
- **API Documentation:** For developers extending the tool
- **Training Materials:** Workshop guides and presentations

## Contact and Support

For questions about the help system or suggestions for improvements:
- Contact MarineSABRES project team
- Submit issues via GitHub (if applicable)
- Request training workshops

---

**Document Version:** 1.0
**Last Updated:** October 2025
**Author:** MarineSABRES Development Team
