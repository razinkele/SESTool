# Tutorial System - Quick Reference

## 🚀 Quick Start (Copy & Paste)

### Basic Tutorial (Most Common)

```r
# Step 1: Get tutorial content
tutorial <- get_tutorial_content("your_feature_id")

# Step 2: Show tutorial
show_tutorial(
  session = session,
  feature_id = "your_feature_id",
  title = tutorial$title,
  message = tutorial$message,
  position = tutorial$position,
  auto_dismiss_ms = tutorial$auto_dismiss_ms
)
```

---

## 📋 Common Patterns

### Pattern 1: On First Tab Visit

```r
observeEvent(input$sidebar_menu, {
  if (input$sidebar_menu == "my_tab") {
    tutorial <- get_tutorial_content("my_feature")
    later::later(function() {
      show_tutorial(
        session = session,
        feature_id = "my_feature",
        title = tutorial$title,
        message = tutorial$message,
        position = "center",
        auto_dismiss_ms = 12000
      )
    }, delay = 0.5)
  }
})
```

### Pattern 2: On Module Load (Once)

```r
moduleServer(id, function(input, output, session) {
  observeEvent(once = TRUE, {
    later::later(function() {
      tutorial <- get_tutorial_content("my_feature")
      show_tutorial(
        session = session,
        feature_id = "my_feature",
        title = tutorial$title,
        message = tutorial$message,
        position = "center"
      )
    }, delay = 1)
  })
})
```

### Pattern 3: On Button Click (First Time)

```r
first_click <- TRUE

observeEvent(input$my_button, {
  if (first_click) {
    first_click <<- FALSE
    tutorial <- get_tutorial_content("my_feature")
    show_tutorial(
      session = session,
      feature_id = "my_feature",
      title = tutorial$title,
      message = tutorial$message,
      target_selector = "#my_button",
      position = "bottom"
    )
  }
})
```

### Pattern 4: On Data Generated (Celebration)

```r
observe({
  data <- generated_data()

  if (!is.null(data) && nrow(data) > 0) {
    tutorial <- get_tutorial_content("my_feature")
    show_tutorial(
      session = session,
      feature_id = "my_feature",
      title = tutorial$title,
      message = tutorial$message,
      position = "top",
      show_confetti = TRUE  # 🎉
    )
  }
})
```

---

## ⚙️ Tutorial Content Template

### In `config/tutorial_content.R`:

```r
your_feature_name = list(
  title = "Feature Name",
  message = paste(
    "<p><strong>Introduction sentence.</strong></p>",
    "<p><strong>What you can do:</strong></p>",
    "<ul style='margin: 10px 0; padding-left: 20px;'>",
    "<li>Action 1</li>",
    "<li>Action 2</li>",
    "<li>Action 3</li>",
    "</ul>",
    "<p>💡 <strong>Tip:</strong> Helpful tip here!</p>"
  ),
  position = "center",
  auto_dismiss_ms = 12000,
  show_confetti = FALSE
)
```

---

## 🎨 Position Options

| Code | Result |
|------|--------|
| `position = "center"` | Middle of screen |
| `position = "top"` | Top center |
| `position = "bottom"` | Bottom center |
| `position = "left"` | Left side |
| `position = "right"` | Right side |

---

## ⏱️ Timing Guidelines

| Feature Complexity | Recommended Time |
|-------------------|------------------|
| Simple | 10,000 ms (10s) |
| Medium | 12,000 ms (12s) |
| Complex | 15,000 ms (15s) |
| Very Complex | 18,000 ms (18s) |
| No auto-dismiss | 0 ms |

---

## 🎯 Element Highlighting

```r
# Highlight specific element
target_selector = "#element_id"

# Highlight by class
target_selector = ".my-class"

# Highlight button
target_selector = "button[data-value='my_value']"

# Highlight modal
target_selector = ".modal-content"

# No highlighting
target_selector = NULL  # or omit parameter
```

---

## 🧪 Testing Commands

### Reset Specific Tutorial
```r
reset_tutorial(session, "your_feature_id")
```

### Reset All Tutorials
```r
reset_tutorial(session, "all")
```

### Browser Console (JavaScript)
```javascript
// Clear specific
localStorage.removeItem('marinesabres_tutorial_seen_your_feature_id');

// Clear all
Object.keys(localStorage).forEach(key => {
  if (key.startsWith('marinesabres_tutorial_seen_')) {
    localStorage.removeItem(key);
  }
});
```

---

## 📝 Message Formatting

### Basic HTML

```r
message = paste(
  "<p>Paragraph with <strong>bold</strong> and <em>italic</em></p>",
  "<ul>",
  "<li>Bullet 1</li>",
  "<li>Bullet 2</li>",
  "</ul>"
)
```

### With Icons

```r
message = paste(
  "<p>📊 Data analysis tools</p>",
  "<p>🤖 AI assistance available</p>",
  "<p>💡 <strong>Tip:</strong> Try the templates!</p>"
)
```

### Multi-Step

```r
message = paste(
  "<p><strong>Step 1:</strong> Do this first</p>",
  "<p><strong>Step 2:</strong> Then do this</p>",
  "<p><strong>Step 3:</strong> Finally do this</p>"
)
```

---

## 🔍 Debugging

### Check if Tutorial Shown

```javascript
// Browser console
console.log(localStorage.getItem('marinesabres_tutorial_seen_my_feature'));
// null = not shown, "true" = already shown
```

### Watch Tutorial Events

```javascript
// Browser console - shows all tutorial events
// Already implemented in tutorial_system.R
```

### Check Tutorial Content

```r
# R console
tutorial <- get_tutorial_content("my_feature")
cat(tutorial$message)
```

---

## 🎭 Available Feature IDs

```
isa_data_entry
ai_assistant
cld_generation
network_analysis
loop_detection
template_import
file_upload
mode_badge
ses_creation
export_report
```

---

## ⚡ Pro Tips

1. **Delay before showing**: Use `later::later(function() { ... }, delay = 0.5)`
2. **Once per session**: Use `observeEvent(once = TRUE, { ... })`
3. **Test first-time UX**: Clear localStorage frequently during development
4. **Keep it short**: 2-4 bullet points maximum
5. **Highlight key elements**: Use `target_selector` to draw attention
6. **Celebrate milestones**: Use `show_confetti = TRUE` for achievements

---

## 🐛 Common Mistakes

❌ **Don't**: Call `show_tutorial()` on every reactive update
✅ **Do**: Use `once = TRUE` or track with a flag

❌ **Don't**: Show immediately on page load
✅ **Do**: Delay 0.5-1 seconds with `later::later()`

❌ **Don't**: Use non-unique `feature_id`
✅ **Do**: Use descriptive, unique IDs like `"network_analysis_loops"`

❌ **Don't**: Forget to add content to `tutorial_content.R`
✅ **Do**: Always define content before calling `show_tutorial()`

---

## 📞 Need Help?

- Check: `Documents/TUTORIAL_INTEGRATION_GUIDE.md` for detailed examples
- Console logs: Look for `[TUTORIAL]` messages
- Test mode: `reset_tutorial(session, "all")` to re-show tutorials

---

_Last updated: 2025-12-28_
