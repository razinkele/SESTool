// Debug logging utility - only logs when debug mode is enabled
// Set window.__DEBUG = true in browser console to enable debug output
var __dbg = function() {
  if (window.__DEBUG) {
    console.log.apply(console, arguments);
  }
};

// This file will contain custom JavaScript for the MarineSABRES SES Toolbox.

// CRITICAL: Check for language change IMMEDIATELY (before document.ready)
// This ensures the overlay appears as soon as possible on the new page
(function() {
  var isChangingLanguage = sessionStorage.getItem('language_changing');

  if (isChangingLanguage === 'true') {
    __dbg('[JS] IMMEDIATE: Language change detected, creating overlay NOW');

    // Record when overlay was shown
    window.languageChangeStartTime = Date.now();
    __dbg('[JS] Overlay display started at:', window.languageChangeStartTime);

    // Create overlay HTML immediately
    var overlayHTML = '<div id="language-loading-overlay" class="active" style="position:fixed;top:0;left:0;width:100%;height:100%;background-color:rgba(44,62,80,0.95);z-index:999999;display:flex;flex-direction:column;justify-content:center;align-items:center;">' +
      '<div class="loading-spinner" style="font-size:48px;color:#3498db;margin-bottom:20px;"><i class="fa fa-spinner fa-spin"></i></div>' +
      '<div class="loading-message" style="font-size:24px;color:#ffffff;font-weight:600;margin-bottom:10px;text-align:center;"><i class="fa fa-globe"></i> ' +
      (sessionStorage.getItem('language_loading_message') || 'Changing language...') + '</div>' +
      '<div class="loading-submessage" style="font-size:14px;color:#bdc3c7;text-align:center;">Please wait while the application reloads...</div>' +
      '</div>';

    // Insert at start of body (or create body if it doesn't exist yet)
    if (document.body) {
      document.body.insertAdjacentHTML('afterbegin', overlayHTML);
    } else {
      // If body doesn't exist yet, wait for it
      document.addEventListener('DOMContentLoaded', function() {
        document.body.insertAdjacentHTML('afterbegin', overlayHTML);
      });
    }
  }
})();

// On page load, check if language needs to be set from localStorage
$(document).ready(function() {
  // Check if language is already in URL
  var urlParams = new URLSearchParams(window.location.search);
  var urlLang = urlParams.get('language');

  if (!urlLang) {
    // No language in URL, check localStorage
    var savedLang = localStorage.getItem('marinesabres_language');
    if (savedLang && savedLang !== 'en') {
      // Redirect with language parameter
      window.location.search = '?language=' + savedLang;
    }
  }
});

// Function to save project data to sessionStorage before language reload
// This preserves the user's work (SES creation progress, etc.) across language changes
Shiny.addCustomMessageHandler('saveProjectDataBeforeReload', function(message) {
  __dbg('[JS] Saving project data before language reload...');
  try {
    if (message && message.data) {
      sessionStorage.setItem('marinesabres_project_data_temp', message.data);
      sessionStorage.setItem('marinesabres_restore_after_lang_change', 'true');
      __dbg('[JS] Project data saved to sessionStorage (size: ' + message.data.length + ' chars)');
    }
  } catch (e) {
    console.error('[JS] Failed to save project data:', e);
    // If sessionStorage is full or unavailable, try to continue anyway
  }
});

// Function to save language and reload with query parameter
Shiny.addCustomMessageHandler('saveLanguageAndReload', function(lang) {
  __dbg('[JS] Saving language and reloading:', lang);
  localStorage.setItem('marinesabres_language', lang);

  // Set flag for the new page to know we're changing language
  sessionStorage.setItem('language_changing', 'true');

  // Save the loading message for the new page
  var loadingMessage = $('#language-loading-overlay .loading-message').text();
  if (loadingMessage) {
    sessionStorage.setItem('language_loading_message', loadingMessage);
  }

  __dbg('[JS] Setting URL to: ?language=' + lang);
  window.location.search = '?language=' + lang;
});

// On Shiny connected, check if we need to restore project data after language change
$(document).on('shiny:connected', function() {
  var shouldRestore = sessionStorage.getItem('marinesabres_restore_after_lang_change');
  if (shouldRestore === 'true') {
    __dbg('[JS] Detected language change reload, checking for saved project data...');
    var savedData = sessionStorage.getItem('marinesabres_project_data_temp');
    if (savedData) {
      __dbg('[JS] Found saved project data, sending to Shiny for restoration...');
      // Small delay to ensure Shiny is fully ready
      setTimeout(function() {
        Shiny.setInputValue('restore_project_data_from_lang_change', savedData, {priority: 'event'});
        // Clean up sessionStorage
        sessionStorage.removeItem('marinesabres_project_data_temp');
        sessionStorage.removeItem('marinesabres_restore_after_lang_change');
        __dbg('[JS] Project data sent to Shiny, sessionStorage cleaned up');
      }, 500);
    } else {
      __dbg('[JS] No saved project data found');
      sessionStorage.removeItem('marinesabres_restore_after_lang_change');
    }
  }
});

// Function to update header translations after language is loaded
Shiny.addCustomMessageHandler('updateHeaderTranslations', function(translations) {
  __dbg('[JS] Updating header translations:', translations);

  // Update main dropdown labels
  $('#language_dropdown_toggle span:first').text(translations.language);
  $('#settings_dropdown_toggle span:first').text(translations.settings);
  $('#help_dropdown_toggle span:first').text(translations.help);
  $('#bookmark_btn span').text(translations.bookmark);

  __dbg('[JS] Header translations updated');

  // Update dropdown menu items
  $('#open_language_modal span').text(translations.change_language);
  $('#open_settings_modal span').text(translations.application_settings);
  $('#open_user_level_modal span').text(translations.user_experience_level);
  $('#open_manuals_modal span').text(translations.download_manuals);
  $('#open_about_modal span').text(translations.app_info);

  // Update help menu items by finding the correct links
  $('.settings-dropdown-menu a[onclick*="beginner_guide"] span').text("Beginner's Guide"); // Keep as English
  $('.settings-dropdown-menu a[onclick*="step_by_step_tutorial"] span').text(translations.step_by_step_tutorial);
  $('.settings-dropdown-menu a[onclick*="user_guide"] span').text(translations.quick_reference);
});

// Settings dropdown functionality
$(document).ready(function() {
  // Language dropdown toggle
  $('#language_dropdown_toggle').on('click', function(e) {
    e.preventDefault();
    $(this).closest('.settings-dropdown').toggleClass('open');
    // Close other dropdowns
    $('.settings-dropdown').not($(this).closest('.settings-dropdown')).removeClass('open');
  });

  // Settings dropdown toggle
  $('#settings_dropdown_toggle').on('click', function(e) {
    e.preventDefault();
    $(this).closest('.settings-dropdown').toggleClass('open');
    // Close other dropdowns
    $('.settings-dropdown').not($(this).closest('.settings-dropdown')).removeClass('open');
  });

  // Help dropdown toggle
  $('#help_dropdown_toggle').on('click', function(e) {
    e.preventDefault();
    $(this).closest('.settings-dropdown').toggleClass('open');
    // Close other dropdowns
    $('.settings-dropdown').not($(this).closest('.settings-dropdown')).removeClass('open');
  });

  // Close dropdown when clicking outside
  $(document).on('click', function(e) {
    if (!$(e.target).closest('.settings-dropdown').length) {
      $('.settings-dropdown').removeClass('open');
    }
  });

  // Close dropdown when clicking a menu item
  $('.settings-dropdown-menu a').on('click', function() {
    $('.settings-dropdown').removeClass('open');
  });

  // Bookmark button handler
  $('#bookmark_btn').on('click', function(e) {
    e.preventDefault();
    Shiny.setInputValue('trigger_bookmark', Math.random());
  });
});

// Custom message handler for saving user level
Shiny.addCustomMessageHandler('save_user_level', function(message) {
  saveUserLevel(message.level);
});

// Function to save user level and reload
// Note: localStorage persistence removed for consistent fresh-start behavior
// Only URL parameter is set for bookmarking support
function saveUserLevel(level) {
  // localStorage.setItem('marinesabres_user_level', level); // REMOVED
  window.location.search = '?user_level=' + level;
}

// Custom message handler for sidebar tooltip initialization
// This uses Bootstrap 4's native tooltip functionality (not bs4Dash's built-in)
// We use custom implementation to avoid the bs4Dash help toggle in navbar
Shiny.addCustomMessageHandler('initSidebarTooltips', function(data) {
  __dbg('[TOOLTIPS] Initializing sidebar tooltips...');

  var $sidebarLinks = $(data.selector);
  __dbg('[TOOLTIPS] Found', $sidebarLinks.length, 'sidebar links with title attributes');

  if ($sidebarLinks.length > 0) {
    // Process each link
    $sidebarLinks.each(function() {
      var $link = $(this);
      var titleText = $link.attr('title');

      // Only initialize if element has a title attribute
      if (titleText) {
        // Destroy existing tooltip first
        try {
          $link.tooltip('dispose');
        } catch(e) {
          // Ignore if tooltip wasn't initialized
        }

        // Initialize Bootstrap 4 tooltip
        // Title is read from the element's title attribute
        $link.tooltip({
          placement: 'right',
          trigger: 'hover',
          container: 'body',
          delay: { show: 300, hide: 100 }
        });

        // Store original title as data attribute to prevent browser default tooltip
        $link.attr('data-original-title', titleText);
      }
    });

    __dbg('[TOOLTIPS] Sidebar tooltips initialized successfully');
  } else {
    console.warn('[TOOLTIPS] No sidebar links with title attributes found');
  }
});

$(document).ready(function() {
  // Log when tooltips are rendered (for debugging)
  $(document).on('shown.bs.tooltip', function(e) {
    __dbg('[TOOLTIPS] Tooltip shown for:', $(e.target).attr('title'));
  });

  // Handle any other elements with data-toggle="tooltip" (non-sidebar)
  function initializeOtherTooltips() {
    var $otherTooltips = $('[data-toggle="tooltip"]').not('.main-sidebar [title]');
    if ($otherTooltips.length > 0) {
      try {
        $otherTooltips.tooltip('dispose');
      } catch(e) {}
      $otherTooltips.tooltip({
        container: 'body',
        placement: 'auto',
        boundary: 'viewport',
        delay: { show: 300, hide: 100 }
      });
      __dbg('[TOOLTIPS] Initialized', $otherTooltips.length, 'non-sidebar tooltips');
    }
  }

  // Initialize non-sidebar tooltips on page load
  setTimeout(initializeOtherTooltips, 1000);

  // Re-initialize non-sidebar tooltips when Shiny becomes idle
  $(document).on('shiny:idle', function() {
    setTimeout(initializeOtherTooltips, 200);
  });

  // ========== DISABLE SIDEBAR HOVER-TO-EXPAND BEHAVIOR ==========
  // Fix issue where hovering over collapsed sidebar causes it to expand and overlap content
  // Only allow toggle via hamburger menu button, not hover
  $(document).ready(function() {
    // Remove AdminLTE's default hover behavior for sidebar
    $('body').removeClass('sidebar-mini-hover');

    // Prevent mouseenter/mouseleave events on sidebar from expanding it
    $('.main-sidebar').off('mouseenter mouseleave');

    // Ensure sidebar only toggles via the pushmenu button (hamburger icon)
    // This keeps the manual toggle working while disabling auto-expand on hover
    $('.sidebar-toggle').on('click', function(e) {
      // Let bs4Dash handle the toggle, just ensure hover class stays off
      setTimeout(function() {
        $('body').removeClass('sidebar-mini-hover');
      }, 100);
    });
  });

  // Open settings modal when clicking the language selector
  $('#open_settings_modal').on('click', function(e) {
    e.preventDefault();
    Shiny.setInputValue('show_settings_modal', Math.random());
  });

  // Open about modal when clicking the about button
  $('#open_about_modal').on('click', function(e) {
    e.preventDefault();
    Shiny.setInputValue('show_about_modal', Math.random());
  });

  // Show persistent loading overlay for language change
  Shiny.addCustomMessageHandler('showLanguageLoading', function(message) {
    __dbg('[JS] showLanguageLoading called with message:', message.text);

    // Remove any existing overlay
    $('#language-loading-overlay').remove();

    // Create new overlay with inline styles to ensure visibility
    var overlay = $('<div id="language-loading-overlay" class="active" style="position:fixed;top:0;left:0;width:100%;height:100%;background-color:rgba(44,62,80,0.95);z-index:999999;display:flex;flex-direction:column;justify-content:center;align-items:center;">' +
      '<div class="loading-spinner" style="font-size:48px;color:#3498db;margin-bottom:20px;"><i class="fa fa-spinner fa-spin"></i></div>' +
      '<div class="loading-message" style="font-size:24px;color:#ffffff;font-weight:600;margin-bottom:10px;text-align:center;"><i class="fa fa-globe"></i> ' + message.text + '</div>' +
      '<div class="loading-submessage" style="font-size:14px;color:#bdc3c7;text-align:center;">Please wait while the application reloads...</div>' +
      '</div>');

    // Append to body
    $('body').append(overlay);
    __dbg('[JS] Overlay created and appended to body');
  });

  // Open report in new window/tab
  Shiny.addCustomMessageHandler('openReport', function(message) {
    // Open the report URL in a new window/tab
    window.open(message.url, '_blank');
  });

  // Focus on a specific button (for connection review navigation)
  Shiny.addCustomMessageHandler('focusButton', function(message) {
    setTimeout(function() {
      var button = document.getElementById(message.id);
      if (button) {
        button.focus();
        // Optionally scroll the button into view
        button.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
    }, 100); // Small delay to ensure DOM is updated
  });
});

// Handle hiding the language loading overlay after Shiny is fully connected AND rendered
$(document).on('shiny:connected', function() {
  // Check if we just finished a language change
  var isChangingLanguage = sessionStorage.getItem('language_changing');

  if (isChangingLanguage === 'true') {
    __dbg('[JS] Shiny connected after language change - waiting for full render');

    // Calculate how long the overlay has been displayed
    var timeElapsed = window.languageChangeStartTime ? Date.now() - window.languageChangeStartTime : 0;
    var MINIMUM_DISPLAY_TIME = 5000; // Minimum 5 seconds display time
    var RENDER_WAIT_TIME = 2500; // Wait 2.5 seconds for UI to render after connection

    __dbg('[JS] Time elapsed since overlay appeared:', timeElapsed, 'ms');
    __dbg('[JS] Minimum display time:', MINIMUM_DISPLAY_TIME, 'ms');

    // Calculate how much longer we need to wait to meet minimum display time
    var remainingMinimumTime = Math.max(0, MINIMUM_DISPLAY_TIME - timeElapsed - RENDER_WAIT_TIME);

    __dbg('[JS] Will wait', RENDER_WAIT_TIME + remainingMinimumTime, 'ms before removing overlay');

    // Wait for Shiny to render
    setTimeout(function() {
      __dbg('[JS] Shiny render wait complete, checking minimum display time...');

      // Ensure minimum display time is met
      setTimeout(function() {
        __dbg('[JS] NOW removing language loading overlay');

        var totalTimeDisplayed = Date.now() - window.languageChangeStartTime;
        __dbg('[JS] Total overlay display time:', totalTimeDisplayed, 'ms');

        // Clear the session storage flags
        sessionStorage.removeItem('language_changing');
        sessionStorage.removeItem('language_loading_message');

        // Fade out and remove the overlay
        $('#language-loading-overlay').fadeOut(800, function() {
          $(this).remove();
          __dbg('[JS] Overlay removed - language change complete');
        });
      }, remainingMinimumTime);
    }, RENDER_WAIT_TIME);
  }
});

// Also listen for when Shiny becomes idle (all outputs rendered)
$(document).on('shiny:idle', function() {
  var isChangingLanguage = sessionStorage.getItem('language_changing');

  if (isChangingLanguage === 'true') {
    __dbg('[JS] Shiny is now idle after language change');
  }
});


