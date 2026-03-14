# Tutorial System Integration Guide

This guide explains how to add feature-specific tutorials throughout the MarineSABRES SES Toolbox application.

## 📚 Table of Contents

1. [Overview](#overview)
2. [Basic Usage](#basic-usage)
3. [Integration Examples](#integration-examples)
4. [Testing Tutorials](#testing-tutorials)
5. [Adding New Tutorials](#adding-new-tutorials)
6. [Customization](#customization)

---

## Overview

The tutorial system provides **context-sensitive, one-time help dialogs** that guide users through different features. Tutorials:

- ✅ Show **only once** per user (tracked via localStorage)
- ✅ Auto-dismiss after a configurable timeout
- ✅ Can highlight specific UI elements
- ✅ Support HTML formatting
- ✅ Are fully customizable per feature

---

## Basic Usage

### Step 1: Call `show_tutorial()` in your module

```r
# In any module server function
show_tutorial(
  session = session,
  feature_id = "my_feature",      # Unique ID for this tutorial
  title = get_tutorial_content("my_feature")$title,
  message = get_tutorial_content("my_feature")$message,
  position = "center"              # top, bottom, left, right, center
)
```

### Step 2: Add tutorial content to `config/tutorial_content.R`

```r
# In get_tutorial_content() function, add:
my_feature = list(
  title = "Welcome to My Feature!",
  message = "<p>This feature does XYZ...</p>",
  position = "center",
  auto_dismiss_ms = 12000
)
```

---

## Integration Examples

### Example 1: ISA Data Entry Module

Show tutorial when user first navigates to ISA data entry:

```r
# In modules/isa_data_entry_module.R

isa_data_entry_server <- function(id, project_data, i18n, ...) {
  moduleServer(id, function(input, output, session) {

    # Show tutorial on first visit
    observeEvent(once = TRUE, {
      # Get tutorial content
      tutorial <- get_tutorial_content("isa_data_entry")

      # Show tutorial after brief delay
      later::later(function() {
        show_tutorial(
          session = session,
          feature_id = "isa_data_entry",
          title = tutorial$title,
          message = tutorial$message,
          position = tutorial$position,
          auto_dismiss_ms = tutorial$auto_dismiss_ms
        )
      }, delay = 1)  # 1 second delay
    })

    # Rest of module logic...
  })
}
```

### Example 2: AI Assistant Modal

Show tutorial when AI assistant modal opens for the first time:

```r
# In modules/ai_isa_assistant_module.R

observeEvent(input$open_ai_assistant, {
  # Show AI assistant modal
  showModal(modalDialog(
    title = "AI ISA Assistant",
    # ... modal content
  ))

  # Show tutorial on first open
  tutorial <- get_tutorial_content("ai_assistant")
  show_tutorial(
    session = session,
    feature_id = "ai_assistant",
    title = tutorial$title,
    message = tutorial$message,
    target_selector = ".modal-content",  # Highlight the modal
    position = "center",
    auto_dismiss_ms = tutorial$auto_dismiss_ms
  )
})
```

### Example 3: CLD Generation (with Confetti!)

Show celebratory tutorial when CLD is first generated:

```r
# After CLD generation completes

observeEvent(event_bus$cld_changed(), {
  # Check if this is first CLD generation
  if (is.null(isolate(last_cld_generated))) {
    last_cld_generated <<- TRUE

    tutorial <- get_tutorial_content("cld_generation")
    show_tutorial(
      session = session,
      feature_id = "cld_generation",
      title = tutorial$title,
      message = tutorial$message,
      target_selector = "#cld_plot",  # Highlight the CLD plot
      position = "top",
      auto_dismiss_ms = tutorial$auto_dismiss_ms,
      show_confetti = TRUE  # 🎉 Celebrate the achievement!
    )
  }
})
```

### Example 4: Loop Detection Results

Show tutorial when feedback loops are first detected:

```r
# In loop analysis output

observe({
  loops <- detected_loops()

  if (!is.null(loops) && nrow(loops) > 0) {
    # Show tutorial on first loop detection
    tutorial <- get_tutorial_content("loop_detection")
    show_tutorial(
      session = session,
      feature_id = "loop_detection",
      title = tutorial$title,
      message = tutorial$message,
      target_selector = "#loop_results_table",
      position = "center",
      auto_dismiss_ms = tutorial$auto_dismiss_ms
    )
  }
})
```

### Example 5: Template Import

Show tutorial when template import section is first viewed:

```r
# In template import UI

observeEvent(input$sidebar_menu, {
  if (input$sidebar_menu == "template_import") {
    tutorial <- get_tutorial_content("template_import")
    later::later(function() {
      show_tutorial(
        session = session,
        feature_id = "template_import",
        title = tutorial$title,
        message = tutorial$message,
        position = "center",
        auto_dismiss_ms = tutorial$auto_dismiss_ms
      )
    }, delay = 0.5)
  }
})
```

### Example 6: File Upload

Show tutorial when file input is clicked:

```r
# On file input focus

observeEvent(input$file_upload_click, {
  tutorial <- get_tutorial_content("file_upload")
  show_tutorial(
    session = session,
    feature_id = "file_upload",
    title = tutorial$title,
    message = tutorial$message,
    target_selector = "#file_upload_input",
    position = "bottom",
    auto_dismiss_ms = tutorial$auto_dismiss_ms
  )
})
```

---

## Testing Tutorials

### Reset All Tutorials (Show Again)

In R Console or browser JavaScript console:

```r
# R (sends message to clear all tutorials)
reset_tutorial(session, feature_id = "all")

# Or specific tutorial
reset_tutorial(session, feature_id = "isa_data_entry")
```

```javascript
// Browser Console
// Clear all tutorials
Object.keys(localStorage).forEach(key => {
  if (key.startsWith('marinesabres_tutorial_seen_')) {
    localStorage.removeItem(key);
  }
});

// Clear specific tutorial
localStorage.removeItem('marinesabres_tutorial_seen_isa_data_entry');
```

### Check if Tutorial Has Been Seen

```javascript
// Browser Console
localStorage.getItem('marinesabres_tutorial_seen_isa_data_entry');
// Returns: "true" if seen, null if not
```

---

## Adding New Tutorials

### Step 1: Add Tutorial Content

Edit `config/tutorial_content.R`:

```r
# In get_tutorial_content() function
my_new_feature = list(
  title = "Feature Title",
  message = paste(
    "<p><strong>Welcome!</strong> This feature does...</p>",
    "<ul>",
    "<li>Point 1</li>",
    "<li>Point 2</li>",
    "</ul>",
    "<p>💡 <strong>Tip:</strong> Try doing X!</p>"
  ),
  position = "center",
  auto_dismiss_ms = 12000,
  show_confetti = FALSE
)
```

### Step 2: Add to Icon Mapping

In `modules/tutorial_system.R`, find `getIconForFeature()` function:

```javascript
function getIconForFeature(featureId) {
  var icons = {
    'isa_data_entry': '📊',
    'my_new_feature': '🎨',  // Add your icon
    // ... other icons
  };
  return icons[featureId] || '💡';
}
```

### Step 3: Integrate into Module

```r
# In your module server function
tutorial <- get_tutorial_content("my_new_feature")
show_tutorial(
  session = session,
  feature_id = "my_new_feature",
  title = tutorial$title,
  message = tutorial$message,
  position = tutorial$position,
  auto_dismiss_ms = tutorial$auto_dismiss_ms
)
```

---

## Customization

### Positioning Options

| Position | Description |
|----------|-------------|
| `center` | Middle of screen (default) |
| `top` | Top center |
| `bottom` | Bottom center |
| `left` | Left center |
| `right` | Right center |

### Auto-Dismiss Timing

```r
auto_dismiss_ms = 0       # Never auto-dismiss
auto_dismiss_ms = 5000    # 5 seconds
auto_dismiss_ms = 12000   # 12 seconds (default)
auto_dismiss_ms = 20000   # 20 seconds (for complex features)
```

### Highlighting Elements

```r
# Highlight a specific element
show_tutorial(
  # ...
  target_selector = "#my_element_id"   # jQuery selector
)

# Multiple selectors
target_selector = ".my-class, #my-id"

# Complex selectors
target_selector = "div.container > .specific-element"
```

### HTML Formatting

Tutorials support full HTML:

```r
message = paste(
  "<h4>Heading</h4>",
  "<p><strong>Bold</strong> and <em>italic</em></p>",
  "<ul style='padding-left: 20px;'>",
  "  <li>Bullet point 1</li>",
  "  <li>Bullet point 2</li>",
  "</ul>",
  "<p style='color: #ff0000;'>Red warning text</p>",
  "<a href='#' onclick='doSomething()'>Clickable link</a>"
)
```

### Celebration Effects

```r
# Show confetti when tutorial appears
show_tutorial(
  # ...
  show_confetti = TRUE  # 🎉
)
```

---

## Best Practices

1. **Show at the right moment**
   - When feature first becomes visible
   - After a brief delay (0.5-1 second)
   - Not on every interaction

2. **Keep messages concise**
   - 2-4 short paragraphs maximum
   - Use bullet points
   - Highlight key actions with **bold**

3. **Use appropriate icons**
   - 📊 Data/Analytics
   - 🤖 AI/Automation
   - 🕸️ Networks/Connections
   - 📈 Charts/Graphs
   - 🔄 Loops/Cycles

4. **Set reasonable timeouts**
   - Simple features: 10-12 seconds
   - Complex features: 15-18 seconds
   - Critical info: 20+ seconds or 0 (manual dismiss only)

5. **Test thoroughly**
   - Clear localStorage and test first-time experience
   - Verify tutorial doesn't block critical workflows
   - Check mobile/tablet responsiveness

---

## Available Features

Currently implemented tutorials:

- `isa_data_entry` - ISA framework introduction
- `ai_assistant` - AI ISA Assistant guide
- `cld_generation` - CLD creation celebration
- `network_analysis` - Network analysis tools
- `loop_detection` - Feedback loop explanation
- `template_import` - Template usage guide
- `file_upload` - File upload instructions
- `mode_badge` - Auto-save mode toggle help
- `ses_creation` - SES creation methods
- `export_report` - Export options overview

---

## Troubleshooting

**Tutorial doesn't appear:**
- Check browser console for errors
- Verify `tutorial_ui()` is in `app.R`
- Ensure `global.R` sources tutorial files
- Clear localStorage to reset "seen" flags

**Tutorial appears every time:**
- Check if `feature_id` is unique
- Verify localStorage is enabled in browser
- Check for duplicate `show_tutorial()` calls

**Tutorial appears in wrong position:**
- Try different position values
- Check z-index conflicts with other elements
- Verify target element exists when tutorial shows

**Content doesn't display properly:**
- Validate HTML syntax
- Check for unescaped quotes
- Test message in isolation

---

## Future Enhancements

Potential additions:

- Multi-step tutorials (wizard-style)
- Video tutorials (embedded)
- Interactive tutorials (click to proceed)
- Tutorial progress tracking
- Analytics (which tutorials are most useful)
- Admin panel to manage tutorials
- A/B testing different tutorial content

---

**Questions or issues?** Check the browser console for `[TUTORIAL]` log messages.
