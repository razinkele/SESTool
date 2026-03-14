# modules/tutorial_system.R
# Generic tutorial system for contextual help across the application
# Provides smart, feature-specific tutorials that appear only once per user

#' Show Tutorial Popup
#'
#' Generic function to display a tutorial popup for any feature
#' Automatically tracks which tutorials have been seen using localStorage
#'
#' @param session Shiny session object
#' @param feature_id Unique identifier for this feature (e.g., "isa_data_entry", "ai_assistant")
#' @param title Tutorial title (e.g., "Welcome to ISA Data Entry!")
#' @param message Tutorial message (HTML supported)
#' @param target_selector jQuery selector for element to highlight (optional)
#' @param position Position of tutorial: "top", "bottom", "left", "right", "center"
#' @param auto_dismiss_ms Auto-dismiss after this many milliseconds (default: 12000 = 12s, 0 = no auto-dismiss)
#' @param show_confetti Show celebration confetti animation (for milestones)
#'
#' @examples
#' show_tutorial(
#'   session = session,
#'   feature_id = "isa_data_entry",
#'   title = "ISA Framework",
#'   message = "Start by adding Drivers, Activities, and Pressures...",
#'   target_selector = "#isa_module",
#'   position = "center"
#' )
show_tutorial <- function(session,
                         feature_id,
                         title,
                         message,
                         target_selector = NULL,
                         position = "center",
                         auto_dismiss_ms = 12000,
                         show_confetti = FALSE) {

  # Send message to JavaScript to show tutorial
  session$sendCustomMessage(
    type = "show_feature_tutorial",
    message = list(
      feature_id = feature_id,
      title = title,
      message = message,
      target_selector = target_selector,
      position = position,
      auto_dismiss_ms = auto_dismiss_ms,
      show_confetti = show_confetti
    )
  )
}

#' Reset Tutorial for Testing
#'
#' Clears the "seen" flag for a specific tutorial
#'
#' @param session Shiny session object
#' @param feature_id Feature to reset, or "all" to reset everything
reset_tutorial <- function(session, feature_id = "all") {
  session$sendCustomMessage(
    type = "reset_tutorial",
    message = list(feature_id = feature_id)
  )
}

#' Tutorial UI - Global Tutorial Container
#'
#' Add this ONCE to your main UI (usually in app.R)
#'
#' @return HTML tags for tutorial system
tutorial_ui <- function() {
  tagList(
    # CSS for tutorial system
    tags$style(HTML("
      /* Generic tutorial overlay */
      .feature-tutorial-overlay {
        position: fixed;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background: rgba(0, 0, 0, 0.4);
        z-index: 999998;
        display: none;
        animation: fadeIn 0.3s ease-out;
      }

      .feature-tutorial-overlay.show {
        display: block;
      }

      /* Tutorial popup container */
      .feature-tutorial {
        position: fixed;
        background: white;
        border-radius: 12px;
        box-shadow: 0 8px 32px rgba(0,0,0,0.3);
        z-index: 999999;
        max-width: 450px;
        display: none;
        animation: slideIn 0.4s ease-out;
      }

      .feature-tutorial.show {
        display: block;
      }

      /* Position variants */
      .feature-tutorial.position-center {
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
      }

      .feature-tutorial.position-top {
        top: 80px;
        left: 50%;
        transform: translateX(-50%);
      }

      .feature-tutorial.position-bottom {
        bottom: 80px;
        left: 50%;
        transform: translateX(-50%);
      }

      .feature-tutorial.position-left {
        left: 40px;
        top: 50%;
        transform: translateY(-50%);
      }

      .feature-tutorial.position-right {
        right: 40px;
        top: 50%;
        transform: translateY(-50%);
      }

      /* Tutorial header */
      .feature-tutorial-header {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 16px 20px;
        border-radius: 12px 12px 0 0;
        display: flex;
        align-items: center;
        justify-content: space-between;
      }

      .feature-tutorial-title {
        font-size: 18px;
        font-weight: 600;
        display: flex;
        align-items: center;
        gap: 10px;
      }

      .feature-tutorial-icon {
        font-size: 24px;
      }

      .feature-tutorial-close {
        background: rgba(255,255,255,0.2);
        border: none;
        color: white;
        width: 28px;
        height: 28px;
        border-radius: 50%;
        cursor: pointer;
        font-size: 18px;
        line-height: 1;
        transition: all 0.2s ease;
        padding: 0;
      }

      .feature-tutorial-close:hover {
        background: rgba(255,255,255,0.3);
        transform: rotate(90deg);
      }

      /* Tutorial body */
      .feature-tutorial-body {
        padding: 20px;
        font-size: 14px;
        line-height: 1.6;
        color: #333;
      }

      /* Tutorial footer */
      .feature-tutorial-footer {
        padding: 16px 20px;
        background: #f8f9fa;
        border-radius: 0 0 12px 12px;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .feature-tutorial-progress {
        font-size: 12px;
        color: #666;
      }

      .feature-tutorial-actions {
        display: flex;
        gap: 10px;
      }

      .feature-tutorial-btn {
        padding: 8px 16px;
        border: none;
        border-radius: 6px;
        cursor: pointer;
        font-size: 13px;
        font-weight: 500;
        transition: all 0.2s ease;
      }

      .feature-tutorial-btn-secondary {
        background: #e9ecef;
        color: #495057;
      }

      .feature-tutorial-btn-secondary:hover {
        background: #dee2e6;
      }

      .feature-tutorial-btn-primary {
        background: #667eea;
        color: white;
      }

      .feature-tutorial-btn-primary:hover {
        background: #5568d3;
        transform: translateY(-1px);
      }

      /* Target element highlight */
      .tutorial-highlight {
        position: relative;
        z-index: 999997;
        box-shadow: 0 0 0 4px #667eea, 0 0 0 8px rgba(102, 126, 234, 0.3);
        animation: tutorial-pulse-highlight 2s ease-in-out infinite;
      }

      @keyframes tutorial-pulse-highlight {
        0%, 100% {
          box-shadow: 0 0 0 4px #667eea, 0 0 0 8px rgba(102, 126, 234, 0.3);
        }
        50% {
          box-shadow: 0 0 0 6px #667eea, 0 0 0 12px rgba(102, 126, 234, 0.5);
        }
      }

      /* Animations */
      @keyframes fadeIn {
        from { opacity: 0; }
        to { opacity: 1; }
      }

      @keyframes slideIn {
        from {
          opacity: 0;
          transform: translate(-50%, -50%) scale(0.9);
        }
        to {
          opacity: 1;
          transform: translate(-50%, -50%) scale(1);
        }
      }

      @keyframes slideOut {
        from {
          opacity: 1;
          transform: translate(-50%, -50%) scale(1);
        }
        to {
          opacity: 0;
          transform: translate(-50%, -50%) scale(0.9);
        }
      }

      /* Confetti celebration */
      .tutorial-confetti {
        position: fixed;
        width: 10px;
        height: 10px;
        background: #f0f;
        position: absolute;
        animation: confetti-fall 3s linear forwards;
      }

      @keyframes confetti-fall {
        to {
          transform: translateY(100vh) rotate(360deg);
          opacity: 0;
        }
      }
    ")),

    # Tutorial HTML structure
    tags$div(class = "feature-tutorial-overlay", id = "tutorial_overlay"),
    tags$div(
      class = "feature-tutorial",
      id = "tutorial_container",
      tags$div(
        class = "feature-tutorial-header",
        tags$div(
          class = "feature-tutorial-title",
          tags$span(class = "feature-tutorial-icon", id = "tutorial_icon"),
          tags$span(id = "tutorial_title")
        ),
        tags$button(class = "feature-tutorial-close", id = "tutorial_close", "×")
      ),
      tags$div(
        class = "feature-tutorial-body",
        id = "tutorial_body"
      ),
      tags$div(
        class = "feature-tutorial-footer",
        tags$div(class = "feature-tutorial-progress", id = "tutorial_progress"),
        tags$div(
          class = "feature-tutorial-actions",
          tags$button(
            class = "feature-tutorial-btn feature-tutorial-btn-secondary",
            id = "tutorial_skip",
            "Don't show again"
          ),
          tags$button(
            class = "feature-tutorial-btn feature-tutorial-btn-primary",
            id = "tutorial_got_it",
            "Got it!"
          )
        )
      )
    ),

    # JavaScript for tutorial system
    tags$script(HTML("
      (function() {
        var currentFeatureId = null;
        var currentTarget = null;
        var autoDismissTimer = null;

        // Show tutorial handler
        Shiny.addCustomMessageHandler('show_feature_tutorial', function(data) {
          // Check if tutorial has been seen
          var seenKey = 'marinesabres_tutorial_seen_' + data.feature_id;
          var hasSeen = localStorage.getItem(seenKey);

          if (hasSeen === 'true') {
            console.log('[TUTORIAL] Already seen:', data.feature_id);
            return;
          }

          currentFeatureId = data.feature_id;

          // Set content
          $('#tutorial_icon').text(getIconForFeature(data.feature_id));
          $('#tutorial_title').text(data.title);
          $('#tutorial_body').html(data.message);
          $('#tutorial_progress').text('');

          // Position tutorial
          var container = $('#tutorial_container');
          container.removeClass('position-center position-top position-bottom position-left position-right');
          container.addClass('position-' + data.position);

          // Highlight target element if specified
          if (data.target_selector) {
            currentTarget = $(data.target_selector);
            if (currentTarget.length > 0) {
              currentTarget.addClass('tutorial-highlight');
            }
          }

          // Show overlay and tutorial
          $('#tutorial_overlay').addClass('show');
          container.addClass('show');

          // Show confetti if requested
          if (data.show_confetti) {
            showConfetti();
          }

          // Auto-dismiss timer
          if (data.auto_dismiss_ms > 0) {
            autoDismissTimer = setTimeout(function() {
              dismissTutorial(true);
            }, data.auto_dismiss_ms);
          }

          console.log('[TUTORIAL] Showing:', data.feature_id);
        });

        // Reset tutorial handler
        Shiny.addCustomMessageHandler('reset_tutorial', function(data) {
          if (data.feature_id === 'all') {
            // Clear all tutorial flags
            Object.keys(localStorage).forEach(function(key) {
              if (key.startsWith('marinesabres_tutorial_seen_')) {
                localStorage.removeItem(key);
              }
            });
            console.log('[TUTORIAL] Reset all tutorials');
          } else {
            var seenKey = 'marinesabres_tutorial_seen_' + data.feature_id;
            localStorage.removeItem(seenKey);
            console.log('[TUTORIAL] Reset tutorial:', data.feature_id);
          }
        });

        // Dismiss tutorial function
        function dismissTutorial(markAsSeen) {
          // Clear timer
          if (autoDismissTimer) {
            clearTimeout(autoDismissTimer);
            autoDismissTimer = null;
          }

          // Remove highlight
          if (currentTarget) {
            currentTarget.removeClass('tutorial-highlight');
            currentTarget = null;
          }

          // Hide overlay and tutorial
          $('#tutorial_overlay').removeClass('show');
          $('#tutorial_container').removeClass('show');

          // Mark as seen if requested
          if (markAsSeen && currentFeatureId) {
            var seenKey = 'marinesabres_tutorial_seen_' + currentFeatureId;
            localStorage.setItem(seenKey, 'true');
            console.log('[TUTORIAL] Dismissed and marked as seen:', currentFeatureId);
          }

          currentFeatureId = null;
        }

        // Event handlers
        $('#tutorial_close').on('click', function() {
          dismissTutorial(false);  // Close but don't mark as seen
        });

        $('#tutorial_skip').on('click', function() {
          dismissTutorial(true);  // Don't show again
        });

        $('#tutorial_got_it').on('click', function() {
          dismissTutorial(true);  // Got it, don't show again
        });

        $('#tutorial_overlay').on('click', function(e) {
          if (e.target === this) {
            dismissTutorial(false);  // Click outside to close
          }
        });

        // Get icon for feature
        function getIconForFeature(featureId) {
          var icons = {
            'isa_data_entry': '📊',
            'ai_assistant': '🤖',
            'cld_generation': '🕸️',
            'network_analysis': '📈',
            'loop_detection': '🔄',
            'template_import': '📥',
            'file_upload': '📤',
            'auto_save': '💾',
            'mode_badge': '⚡',
            'ses_creation': '🌊',
            'export_report': '📄'
          };
          return icons[featureId] || '💡';
        }

        // Show confetti animation
        function showConfetti() {
          var colors = ['#ff0000', '#00ff00', '#0000ff', '#ffff00', '#ff00ff', '#00ffff'];
          for (var i = 0; i < 50; i++) {
            setTimeout(function() {
              var confetti = $('<div class=\"tutorial-confetti\"></div>');
              confetti.css({
                left: Math.random() * window.innerWidth + 'px',
                top: '-10px',
                background: colors[Math.floor(Math.random() * colors.length)],
                animationDelay: Math.random() * 0.5 + 's'
              });
              $('body').append(confetti);
              setTimeout(function() { confetti.remove(); }, 3000);
            }, i * 30);
          }
        }
      })();
    "))
  )
}
