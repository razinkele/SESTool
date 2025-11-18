# MarineSABRES SES Tool - Deployment Framework Update

**Date**: November 17, 2025  
**Version**: 1.0 with Responses Framework

## Summary of Updates

The deployment framework has been updated to reflect the current application structure, including all new features and dependencies added since the initial deployment setup.

## Updated Components

### 1. Dockerfile
**Changes:**
- Added missing R packages: `shinyBS`, `shiny.i18n`, `digest`, and expanded tidyverse packages
- Updated COPY commands to include new directories:
  - `io.R` - I/O operations
  - `utils.R` - Utility functions
  - `VERSION` and `VERSION_INFO.json` - Version management
  - `version_manager.R` - Version control
  - `server/` directory - Server logic modules
  - `scripts/` directory - Helper scripts

**Impact:** Container will now include all application files required for production deployment.

### 2. docker-compose.yml
**Changes:**
- Added commented volume mounts for hot-reload during development
- Maintained persistent volumes for data and translations
- Kept health check and network configuration

**Impact:** Supports both production deployment and development workflows.

### 3. install_dependencies.R
**Changes:**
- Added `digest` package (required for ISA change detection)
- Expanded tidyverse component packages explicitly listed
- Maintained all network analysis and visualization packages

**Impact:** Complete dependency installation for all application features.

### 4. pre-deploy-check.R
**Changes:**
- Added validation for new core files:
  - `io.R`, `utils.R`, `VERSION`, `VERSION_INFO.json`, `version_manager.R`
- Added `server/` directory to required directories check
- Expanded package validation list to include all dependencies

**Impact:** More thorough pre-deployment validation catches missing files or packages.

### 5. .dockerignore
**Changes:**
- Excluded development files: `test_*.R`, `run_app_dev.R`, `install_packages.R`, `update_polarities.R`
- Excluded documentation directories: `docs/`, `Documents/`
- Excluded test directories: `tests/`, `scripts/`
- Maintained exclusion of temporary files and IDE configs

**Impact:** Smaller Docker images, faster builds, excludes unnecessary development files.

## Application Structure Reference

```
MarineSABRES_SES_Shiny/
├── app.R                    # Main application entry point
├── global.R                 # Global variables and package loading
├── run_app.R               # App launcher
├── constants.R             # Application constants
├── io.R                    # I/O operations
├── utils.R                 # Utility functions
├── VERSION                 # Version number
├── VERSION_INFO.json       # Version metadata
├── version_manager.R       # Version management
├── modules/                # Shiny modules
├── functions/              # Helper functions
├── server/                 # Server logic
├── www/                    # Static web assets
├── data/                   # Data files and templates
├── translations/           # i18n translation files
└── deployment/            # Deployment configuration
    ├── Dockerfile
    ├── docker-compose.yml
    ├── deploy.sh
    ├── install_dependencies.R
    └── pre-deploy-check.R
```

## Key Dependencies

### Core Shiny Stack
- shiny, shinydashboard, shinyWidgets, shinyjs, shinyBS
- shiny.i18n (internationalization)

### Data Manipulation
- tidyverse (dplyr, tidyr, readr, purrr, tibble, stringr, forcats, lubridate)
- DT, openxlsx, jsonlite, digest

### Network Analysis & Visualization
- igraph, visNetwork, ggraph, tidygraph

### Plotting & Time Series
- ggplot2, plotly, dygraphs, xts, timevis

### Export & Reporting
- rmarkdown, htmlwidgets, knitr

## New Features Supported

### 1. Management Responses Framework (DAPSIWRM)
- All 6 templates now include responses with connection matrices
- Response nodes positioned in CLD visualization
- Response-specific matrices: gb_r, r_d, r_a, r_p

### 2. Enhanced CLD Visualization
- Multi-line label wrapping for long node names
- Improved node positioning and spacing
- Legend includes all element types including Responses

### 3. Template Data Clearing
- Loading a template now completely clears previous ISA data
- Prevents data mixing between templates or manual entries

### 4. Version Management
- VERSION and VERSION_INFO.json track application version
- Version manager for programmatic version control

## Deployment Workflow

### Quick Start (Docker)
```bash
cd deployment
docker-compose up -d
```

### Manual Shiny Server
```bash
cd deployment
sudo ./deploy.sh --shiny-server
```

### Pre-Deployment Validation
```bash
cd deployment
Rscript pre-deploy-check.R
```

### Install Dependencies Only
```bash
cd deployment
Rscript install_dependencies.R
```

## Testing the Deployment

After deployment, verify:

1. **Application loads**: Navigate to http://localhost:3838
2. **Templates load**: Try loading Offshore Wind or other templates
3. **CLD renders**: Check that network visualization displays correctly
4. **Responses work**: Verify response nodes appear in CLD
5. **Data clears**: Load different templates and confirm old data doesn't persist
6. **Translations work**: Switch between languages
7. **Export works**: Try exporting project to JSON/Excel

## Docker Image Details

- **Base Image**: rocker/shiny-verse:4.4.1
- **Exposed Port**: 3838
- **Working Directory**: /srv/shiny-server/marinesabres
- **User**: shiny
- **Persistent Volumes**: 
  - data/ (project data)
  - translations/ (live translation updates)
  - logs/ (application logs)

## Environment Variables

```yaml
APPLICATION_LOGS_TO_STDOUT=true  # Send logs to stdout
SHINY_LOG_STDERR=1               # Log errors to stderr
```

## Health Check

Docker container includes health check:
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3
- **Start Period**: 40 seconds

## Production Recommendations

1. **Data Backup**: Regularly backup the `data/` volume
2. **Log Rotation**: Configure log rotation for `logs/` volume
3. **Resource Limits**: Set memory/CPU limits in docker-compose.yml
4. **HTTPS**: Use reverse proxy (nginx/traefik) for HTTPS
5. **Monitoring**: Add application monitoring (Prometheus/Grafana)
6. **Updates**: Test updates in staging before production

## Troubleshooting

### Container Won't Start
```bash
docker-compose logs marinesabres-shiny
```

### Missing Dependencies
```bash
docker-compose exec marinesabres-shiny R -e "installed.packages()[,'Package']"
```

### Permission Issues
```bash
docker-compose exec marinesabres-shiny chown -R shiny:shiny /srv/shiny-server/marinesabres
```

### Network Issues
```bash
docker-compose down
docker-compose up -d
```

## Next Steps

1. Review `DEPLOYMENT_GUIDE.md` for detailed deployment instructions
2. Check `DEPLOYMENT_CHECKLIST.md` before production deployment
3. Configure reverse proxy for HTTPS (see deployment/nginx-example.conf)
4. Set up automated backups for data/ directory
5. Configure monitoring and alerting

## Version History

- **1.0** (Nov 2025): Initial deployment framework with full DAPSIWRM support
  - 6 templates with management responses
  - Enhanced CLD visualization
  - Complete i18n support (7 languages)
  - Version management system
  - Template data clearing fix

## Contact

For deployment issues or questions, refer to:
- `deployment/DEPLOYMENT_GUIDE.md` - Complete deployment guide
- `deployment/README.md` - Quick reference
- Project documentation in `docs/` directory
