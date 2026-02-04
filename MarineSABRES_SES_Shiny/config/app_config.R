# config/app_config.R
# Application Configuration via Environment Variables
#
# All configurable settings are read from environment variables with sensible defaults.
# This allows deployment-specific configuration without code changes.
#
# Usage: Set environment variables before starting the app, e.g.:
#   Sys.setenv(APP_DEBUG = "true")
#   Sys.setenv(APP_MAX_UPLOAD_MB = "100")

# ============================================================================
# APPLICATION SETTINGS
# ============================================================================

# Debug mode - enables verbose logging
# Already defined in global.R via MARINESABRES_DEBUG, referenced here for documentation
# DEBUG_MODE <- (Sys.getenv("MARINESABRES_DEBUG", "FALSE") == "TRUE")

# Maximum file upload size (MB)
APP_MAX_UPLOAD_MB <- as.numeric(Sys.getenv("APP_MAX_UPLOAD_MB", "50"))
options(shiny.maxRequestSize = APP_MAX_UPLOAD_MB * 1024^2)

# Session timeout (minutes, 0 = no timeout)
APP_SESSION_TIMEOUT <- as.numeric(Sys.getenv("APP_SESSION_TIMEOUT", "0"))

# Default language
APP_DEFAULT_LANGUAGE <- Sys.getenv("APP_DEFAULT_LANGUAGE", "en")

# Port for Shiny (used in deployment)
APP_PORT <- as.integer(Sys.getenv("APP_PORT", "3838"))

# Host binding (0.0.0.0 for Docker, 127.0.0.1 for local)
APP_HOST <- Sys.getenv("APP_HOST", "127.0.0.1")

# ============================================================================
# FEATURE FLAGS
# ============================================================================

# Enable/disable AI ISA Assistant (requires API key)
FEATURE_AI_ASSISTANT <- Sys.getenv("FEATURE_AI_ASSISTANT", "true") == "true"

# Enable/disable SES Models loading
FEATURE_SES_MODELS <- Sys.getenv("FEATURE_SES_MODELS", "true") == "true"

# Enable/disable local storage (File System Access API)
FEATURE_LOCAL_STORAGE <- Sys.getenv("FEATURE_LOCAL_STORAGE", "true") == "true"

# ============================================================================
# API CONFIGURATION
# ============================================================================

# OpenAI API key for AI features (if applicable)
AI_API_KEY <- Sys.getenv("AI_API_KEY", "")

# API base URL (for custom API endpoints)
AI_API_BASE_URL <- Sys.getenv("AI_API_BASE_URL", "")
