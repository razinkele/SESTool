// This file will contain custom JavaScript for the MarineSABRES SES Toolbox.

// CRITICAL: Check for language change IMMEDIATELY (before document.ready)
// This ensures the overlay appears as soon as possible on the new page
(function() {
  var isChangingLanguage = sessionStorage.getItem('language_changing');

  if (isChangingLanguage === 'true') {
    console.log('[JS] IMMEDIATE: Language change detected, creating overlay NOW');

    // Record when overlay was shown
    window.languageChangeStartTime = Date.now();
    console.log('[JS] Overlay display started at:', window.languageChangeStartTime);

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

// Function to save language and reload with query parameter
Shiny.addCustomMessageHandler('saveLanguageAndReload', function(lang) {
  console.log('[JS] Saving language and reloading:', lang);
  localStorage.setItem('marinesabres_language', lang);

  // Set flag for the new page to know we're changing language
  sessionStorage.setItem('language_changing', 'true');

  // Save the loading message for the new page
  var loadingMessage = $('#language-loading-overlay .loading-message').text();
  if (loadingMessage) {
    sessionStorage.setItem('language_loading_message', loadingMessage);
  }

  console.log('[JS] Setting URL to: ?language=' + lang);
  window.location.search = '?language=' + lang;
});

// Function to update header translations after language is loaded
Shiny.addCustomMessageHandler('updateHeaderTranslations', function(translations) {
  console.log('[JS] Updating header translations:', translations);

  // Update main dropdown labels
  $('#language_dropdown_toggle span:first').text(translations.language);
  $('#settings_dropdown_toggle span:first').text(translations.settings);
  $('#help_dropdown_toggle span:first').text(translations.help);
  $('#bookmark_btn span').text(translations.bookmark);

  console.log('[JS] Header translations updated');

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

$(document).ready(function() {
  // Initialize Bootstrap tooltips for sidebar menu items
  function initializeMenuTooltips() {
    // Find all sidebar menu links that have a title attribute (native tooltips)
    // We'll enhance them with Bootstrap tooltips for better styling
    var $links = $('.sidebar-menu a[title]');

    if ($links.length > 0) {
      console.log('[TOOLTIPS] Found', $links.length, 'links with title attributes');

      // Destroy any existing Bootstrap tooltips first
      $links.each(function() {
        try {
          $(this).tooltip('dispose');
        } catch(e) {}
      });

      // Initialize Bootstrap tooltips
      $links.tooltip({
        container: 'body',
        placement: 'right',
        delay: { show: 300, hide: 100 },
        trigger: 'hover'
      });

      console.log('[TOOLTIPS] Bootstrap tooltips initialized on', $links.length, 'menu links');
    }

    // Also handle any other elements with data-toggle="tooltip"
    var $otherTooltips = $('[data-toggle="tooltip"]');
    if ($otherTooltips.length > 0) {
      try {
        $otherTooltips.tooltip('dispose');
      } catch(e) {}
      $otherTooltips.tooltip({
        container: 'body',
        placement: 'right',
        delay: { show: 500, hide: 100 }
      });
    }
  }

  // Initialize on page load (with delay for Shiny to render)
  setTimeout(initializeMenuTooltips, 800);

  // Re-initialize when sidebar updates
  $(document).on('shiny:value', function(event) {
    if (event.name === 'dynamic_sidebar') {
      setTimeout(initializeMenuTooltips, 300);
    }
  });

  // Custom message handler for manual trigger
  Shiny.addCustomMessageHandler('updateTooltips', function(message) {
    setTimeout(initializeMenuTooltips, 100);
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
    console.log('[JS] showLanguageLoading called with message:', message.text);

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
    console.log('[JS] Overlay created and appended to body');
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
    console.log('[JS] Shiny connected after language change - waiting for full render');

    // Calculate how long the overlay has been displayed
    var timeElapsed = window.languageChangeStartTime ? Date.now() - window.languageChangeStartTime : 0;
    var MINIMUM_DISPLAY_TIME = 5000; // Minimum 5 seconds display time
    var RENDER_WAIT_TIME = 2500; // Wait 2.5 seconds for UI to render after connection

    console.log('[JS] Time elapsed since overlay appeared:', timeElapsed, 'ms');
    console.log('[JS] Minimum display time:', MINIMUM_DISPLAY_TIME, 'ms');

    // Calculate how much longer we need to wait to meet minimum display time
    var remainingMinimumTime = Math.max(0, MINIMUM_DISPLAY_TIME - timeElapsed - RENDER_WAIT_TIME);

    console.log('[JS] Will wait', RENDER_WAIT_TIME + remainingMinimumTime, 'ms before removing overlay');

    // Wait for Shiny to render
    setTimeout(function() {
      console.log('[JS] Shiny render wait complete, checking minimum display time...');

      // Ensure minimum display time is met
      setTimeout(function() {
        console.log('[JS] NOW removing language loading overlay');

        var totalTimeDisplayed = Date.now() - window.languageChangeStartTime;
        console.log('[JS] Total overlay display time:', totalTimeDisplayed, 'ms');

        // Clear the session storage flags
        sessionStorage.removeItem('language_changing');
        sessionStorage.removeItem('language_loading_message');

        // Fade out and remove the overlay
        $('#language-loading-overlay').fadeOut(800, function() {
          $(this).remove();
          console.log('[JS] Overlay removed - language change complete');
        });
      }, remainingMinimumTime);
    }, RENDER_WAIT_TIME);
  }
});

// Also listen for when Shiny becomes idle (all outputs rendered)
$(document).on('shiny:idle', function() {
  var isChangingLanguage = sessionStorage.getItem('language_changing');

  if (isChangingLanguage === 'true') {
    console.log('[JS] Shiny is now idle after language change');
  }
});


