// This file will contain custom JavaScript for the MarineSABRES SES Toolbox.

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
  localStorage.setItem('marinesabres_language', lang);
  window.location.search = '?language=' + lang;
});

// Settings dropdown functionality
$(document).ready(function() {
  // Settings dropdown toggle
  $('#settings_dropdown_toggle').on('click', function(e) {
    e.preventDefault();
    $('.settings-dropdown').toggleClass('open');
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
function saveUserLevel(level) {
  localStorage.setItem('marinesabres_user_level', level);
  window.location.search = '?user_level=' + level;
}

$(document).ready(function() {
  // Add tooltips to menu items using data-tooltip attributes
  // This ensures tooltips work even after dynamic updates
  Shiny.addCustomMessageHandler('updateTooltips', function(message) {
    $('.sidebar-menu li a[data-toggle="tooltip"]').tooltip();
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
    // Remove any existing overlay
    $('#language-loading-overlay').remove();

    // Create new overlay
    var overlay = $('<div id="language-loading-overlay" class="active">' +
      '<div class="loading-spinner"><i class="fa fa-spinner fa-spin"></i></div>' +
      '<div class="loading-message"><i class="fa fa-globe"></i> ' + message.text + '</div>' +
      '<div class="loading-submessage">Please wait while the application reloads...</div>' +
      '</div>');

    // Append to body
    $('body').append(overlay);
  });
});


