# AI ISA Assistant Module - Internationalization Analysis

## Current Status
- Line 14: `shiny.i18n::usei18n(i18n)` already added
- Function signature: `ai_isa_assistant_ui <- function(id)` - NEEDS i18n parameter
- Function signature: `ai_isa_assistant_server <- function(id, project_data_reactive)` - NEEDS i18n parameter

## Hard-Coded Strings to Extract

### UI Section (Lines 178-280)

#### Main Header (178-180)
- "AI-Assisted ISA Creation"
- "Let me guide you step-by-step through building your DAPSI(W)R(M) model."

#### Progress Panel (211-236)
- "Your SES Model Progress"
- "Elements Created:"
- "Framework Flow:"
- "Current Framework:"
- "Drivers: "
- "Activities: "
- "Pressures: "
- "State Changes: "
- "Impacts: "
- "Welfare: "
- "Responses: "
- "Measures: "

#### Session Management (241-276)
- "Session Management"
- "Save Progress"
- "Save your current progress to browser storage"
- "Load Saved"
- "Restore your last saved session"
- "Preview Model"
- "Save to ISA Data Entry"
- "Load Example Template"
- "Start Over"

### Server Section - QUESTION_FLOW (Lines 322-412)

#### Step Titles
- "Welcome & Introduction"
- "Ecosystem Context"
- "Main Issue Identification"
- "Drivers - Societal Needs"
- "Activities - Human Actions"
- "Pressures - Environmental Stressors"
- "State Changes - Ecosystem Effects"
- "Impacts - Effects on Ecosystem Services"
- "Welfare - Human Well-being Effects"
- "Responses - Management Actions"
- "Measures - Policy Instruments"
- "Connection Review"

#### Questions (Long text - need translation keys)
1. "Hello! I'm your AI assistant for creating a DAPSI(W)R(M) model. I'll guide you through a series of questions to build your social-ecological system model. Let's start with the basics: What is the name or location of your marine project or study area?"
2. "Great! Now, what type of marine ecosystem are you studying?"
3. "What is the main environmental or management issue you're addressing?"
4. "Let's identify the DRIVERS - these are the basic human needs or societal demands driving activities in your area. What are the main societal needs? (e.g., Food security, Economic development, Recreation, Energy needs)"
5. "Now let's identify ACTIVITIES - the human actions taken to meet those needs. What activities are happening in your marine area? (e.g., Fishing, Aquaculture, Shipping, Tourism)"
6. "What PRESSURES do these activities put on the marine environment? (e.g., Overfishing, Pollution, Habitat destruction)"
7. "How do these pressures change the STATE of the marine ecosystem? (e.g., Declining fish stocks, Loss of biodiversity, Degraded water quality)"
8. "What are the IMPACTS on ecosystem services and benefits? How do these changes affect what the ocean provides? (e.g., Reduced fish catch, Loss of tourism revenue)"
9. "How do these impacts affect human WELFARE and well-being? (e.g., Loss of livelihoods, Health impacts, Reduced quality of life)"
10. "What RESPONSES or management actions are being taken (or could be taken) to address these issues? (e.g., Marine protected areas, Fishing quotas, Pollution regulations)"
11. "Finally, what specific MEASURES or policy instruments support these responses? (e.g., Laws, Economic incentives, Education programs)"
12. "Great! Now I'll suggest logical connections between the elements you've identified. These connections represent causal relationships in your social-ecological system. You can review and approve/reject each suggestion."

#### Example Options (Lines 332, 348, 356, 364, 372, 380, 388, 396, 404)
Ecosystem types:
- "Coastal waters", "Open ocean", "Estuaries", "Coral reefs", "Mangroves", "Seagrass beds", "Deep sea", "Other"

Drivers examples:
- "Food security", "Economic development", "Recreation and tourism", "Energy needs", "Coastal protection", "Cultural heritage"

Activities examples:
- "Commercial fishing", "Recreational fishing", "Aquaculture", "Shipping/Transport", "Tourism", "Coastal development", "Renewable energy (wind/wave)", "Oil & gas extraction"

Pressures examples:
- "Overfishing", "Bycatch", "Physical habitat damage", "Pollution (nutrients, chemicals)", "Noise pollution", "Marine litter/plastics", "Temperature changes", "Ocean acidification"

States examples:
- "Declining fish stocks", "Loss of biodiversity", "Habitat degradation", "Water quality decline", "Altered food webs", "Invasive species", "Loss of ecosystem resilience"

Impacts examples:
- "Reduced fish catch", "Loss of tourism revenue", "Reduced coastal protection", "Loss of biodiversity value", "Reduced water quality for recreation", "Loss of cultural services"

Welfare examples:
- "Loss of livelihoods", "Food insecurity", "Economic losses", "Health impacts", "Loss of cultural identity", "Reduced quality of life", "Social conflicts"

Responses examples:
- "Marine protected areas (MPAs)", "Fishing quotas/limits", "Pollution regulations", "Habitat restoration", "Sustainable fishing practices", "Ecosystem-based management", "Stakeholder engagement", "Monitoring programs"

Measures examples:
- "Environmental legislation", "Marine spatial planning", "Economic incentives (subsidies, taxes)", "Education and awareness programs", "Certification schemes (MSC, etc.)", "International agreements", "Monitoring and enforcement", "Research funding"

### Server Section - UI Messages

#### Session Management (456, 492, 496, 508, 539, 559)
- "Session restored successfully!"
- "Auto-saved "
- " seconds ago"
- " minutes ago"
- "Not yet saved"
- "Session saved successfully!"
- "No saved session found."
- "A previous session was found. Click 'Load Saved' to restore it."

#### Step Navigation (570, 572)
- "Step ", " of ", ": "
- "Complete! Review your model"

#### Connection Review (616-630, 638, 643, 663, 692, 697, 747)
- "Review Suggested Connections"
- "Approve or reject each connection. You can modify the strength and polarity if needed."
- "Approve All"
- "Finish & Continue"
- "Type your answer here..."
- "Submit Answer"
- "No connections to review."
- "Reject"
- "Approve"
- "All connections approved!"

#### Button Labels (771, 779-805)
- "Skip This Question"
- "Continue to Activities"
- "Continue to Pressures"
- "Continue to State Changes"
- "Continue to Impacts"
- "Continue to Welfare"
- "Continue to Responses"
- "Continue to Measures"
- "Continue"
- "Finish"

#### Quick Options (821)
- "Quick options (click to add):"

#### AI Responses (755-757, 893, 905, 1081-1086, 1097)
- "Great! You've approved ", " connections out of ", " suggested connections. These connections will be included in your saved ISA data."
- "✓ Added '", "' (", " ", " total). Click quick options to add more, or click the green button to continue."
- "Thank you! Moving to the next question..."
- Connection suggestion message
- "Excellent work! You've completed your DAPSI(W)R(M) model with connections. Review the summary on the right, and when ready, click 'Save to ISA Data Entry' to transfer your model to the main ISA module."

#### Totals Display (1123)
- "Total elements created"

#### Modal Dialogs (526-534, 1300-1305, 1329-1353)
- "Restore Previous Session?"
- "Found a saved session from ", ". Do you want to restore it?"
- "Yes, Restore"
- "Cancel"
- "Confirm Start Over"
- "Are you sure you want to start over? All current progress will be lost."
- "Yes, Start Over"
- "Load Example Template"
- "Choose a pre-built scenario:"
- "Overfishing in Coastal Waters"
- "Marine Pollution & Plastics"
- "Coastal Tourism Impacts"
- "Climate Change & Coral Reefs"

#### Notifications (1292, 1439, 1528, 1614, 1702, 1998-2000)
- "Model saved! Navigate to 'ISA Data Entry' to see your elements."
- "Overfishing template loaded with example connections! You can now preview or modify it."
- "Marine Pollution template loaded with example connections!"
- "Coastal Tourism template loaded with example connections!"
- "Climate Change template loaded with example connections!"
- "Model saved successfully! ", " elements and ", " connections transferred to ISA Data Entry."

## Total Estimated Strings
- **Approximately 150+ unique strings** requiring translation

## Implementation Strategy
1. Add i18n parameter to both function signatures
2. Wrap all UI strings with i18n$t()
3. Create translation keys for long questions (use abbreviated keys)
4. Extract all strings to JSON file
5. Generate translations for all 7 languages
6. Merge into translation.json
7. Test module with language switching
