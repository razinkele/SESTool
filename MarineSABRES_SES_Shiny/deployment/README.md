# MarineSABRES SES Tool - Deployment Package

This directory contains all necessary files for deploying the MarineSABRES Social-Ecological Systems Analysis Tool to production servers.

## 📋 Pre-Deployment Check

**NEW:** Before deploying, run the validation script:

```bash
cd deployment
Rscript pre-deploy-check.R
```

This validates:
- All required files and directories
- Translation JSON validity
- R package dependencies
- R syntax in core files
- Common deployment issues

## Quick Start

### Docker Deployment (Recommended)

```bash
cd deployment
./deploy.sh --docker
```

Access at: http://localhost:3838

### Shiny Server Deployment

```bash
cd deployment
sudo ./deploy.sh --shiny-server
```

Access at: http://your-server:3838/marinesabres

## Package Contents

```
deployment/
├── README.md                      # This file
├── DEPLOYMENT_GUIDE.md            # Comprehensive deployment documentation
├── TROUBLESHOOTING.md             # Deployment troubleshooting guide (NEW)
├── pre-deploy-check.R             # Pre-deployment validation script
├── validate-deployment.sh         # Post-deployment validation
├── check-deployment-status.sh     # Deployment diagnostics (NEW)
├── force-restart-shiny.sh         # Force restart with cache clearing (NEW)
├── Dockerfile                     # Docker container configuration
├── docker-compose.yml             # Docker Compose orchestration
├── shiny-server.conf              # Shiny Server configuration
├── install_dependencies.R         # R package installation script
└── deploy.sh                      # Automated deployment script
```

## File Descriptions

### pre-deploy-check.R
Validation script that checks:
- Required files (app.R, global.R, functions/translation_loader.R)
- Required directories (modules, functions, www, data, translations, scripts)
- **Modular translation system** (common/, modules/, ui/, data/ subdirectories)
- Reverse key mapping file (deprecated but validated)
- R package dependencies
- R syntax validity
- Large files and temporary files

Run this before every deployment to catch issues early.

### check-deployment-status.sh (NEW)
Diagnostic script that helps troubleshoot deployment issues:
- Compares source vs deployed file timestamps
- Checks Shiny Server and R process status
- Validates modular translation system deployment
- Verifies scripts directory (required for translations)
- Shows recent application logs
- Provides actionable recommendations

### force-restart-shiny.sh (NEW)
Force restart script that resolves "old version" issues:
- Kills all Shiny R processes
- Clears Shiny Server cache directories
- Removes stale translation caches
- Full stop/start cycle (not just restart)
- Verifies clean restart

### validate-deployment.sh
Post-deployment validation script that checks:
- All required files and directories copied
- Modular translation structure present
- SES template JSON files
- Permissions correctly set
- Shiny Server running
- Network access working

### TROUBLESHOOTING.md (NEW)
Comprehensive troubleshooting guide covering:
- "Server serving old version" solutions
- Common deployment issues
- Diagnostic tools usage
- Browser cache problems
- Process and cache management
- Complete reset procedures

### Dockerfile
Docker image definition for containerized deployment. Includes:
- R 4.4.1 base image
- All system dependencies
- All R package dependencies
- Application files (including translations)
- Shiny Server configuration

### docker-compose.yml
Docker Compose configuration for easy container orchestration:
- Port mapping (3838)
- Volume mounts for data persistence
- Health checks
- Automatic restart policy

### shiny-server.conf
Shiny Server configuration file with:
- Application path settings
- Timeout configurations
- Logging setup
- Security settings

### install_dependencies.R
R script that installs all required packages:
- Core Shiny packages
- Data manipulation (tidyverse, DT, openxlsx)
- Network visualization (igraph, visNetwork)
- Time series (dygraphs, xts)
- Reporting (rmarkdown)

### deploy.sh (UPDATED)
Automated deployment script supporting:
- Docker deployment
- Shiny Server deployment
- **Automatic process killing** before deployment
- **Cache clearing** (Shiny Server and translation caches)
- **Full stop/start cycle** (not just restart)
- Scripts directory copying (required for modular translations)
- Dependency installation
- Configuration management
- Health checks
- **Browser cache reminder** in output

### DEPLOYMENT_GUIDE.md
Comprehensive 350+ line guide covering:
- System requirements
- Multiple deployment options
- Step-by-step instructions
- Configuration details
- Troubleshooting
- Maintenance procedures
- Security recommendations

## Deployment Methods

### 1. Docker (Production Ready)

**Pros:**
- Isolated environment
- Easy updates and rollbacks
- Portable across systems
- Includes all dependencies

**Steps:**
```bash
docker-compose build
docker-compose up -d
docker-compose logs -f  # View logs
```

### 2. Shiny Server (Traditional)

**Pros:**
- Native R environment
- Fine-grained control
- Direct file system access

**Steps:**
```bash
sudo Rscript install_dependencies.R
sudo bash deploy.sh --shiny-server
```

### 3. ShinyApps.io (Cloud Hosting)

**Pros:**
- Managed hosting
- No server maintenance
- Automatic scaling

**Steps:**
```r
library(rsconnect)
rsconnect::deployApp(appDir = "..")
```

## System Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 4 GB
- Disk: 2 GB
- OS: Ubuntu 20.04+, Debian 10+, or Windows Server 2019+

**Recommended:**
- CPU: 4 cores
- RAM: 8 GB
- Disk: 10 GB SSD
- OS: Ubuntu 22.04 LTS

## Network Configuration

**Ports:**
- 3838: Shiny Server (HTTP)
- 443: HTTPS (if using reverse proxy)

**Firewall Rules:**
```bash
sudo ufw allow 3838/tcp
sudo ufw allow 443/tcp  # For HTTPS
```

## Environment Variables

Optional configuration via `.Renviron`:

```bash
MARINESABRES_ENV=production
MARINESABRES_LOG_LEVEL=INFO
SHINY_SESSION_TIMEOUT=3600
```

## Monitoring

**Docker:**
```bash
docker-compose ps
docker-compose logs -f
docker stats
```

**Shiny Server:**
```bash
sudo systemctl status shiny-server
sudo tail -f /var/log/shiny-server.log
```

## Updates

**Docker:**
```bash
git pull
docker-compose build
docker-compose up -d
```

**Shiny Server:**
```bash
git pull
sudo cp -r ../* /srv/shiny-server/marinesabres/
sudo systemctl restart shiny-server
```

## Backup

**Data files:**
```bash
tar -czf marinesabres-backup-$(date +%Y%m%d).tar.gz \
  /srv/shiny-server/marinesabres/data
```

**Docker volumes:**
```bash
docker run --rm \
  -v marinesabres_data:/data \
  -v $(pwd):/backup \
  ubuntu tar czf /backup/backup.tar.gz /data
```

## Security Checklist

- [ ] Use HTTPS in production
- [ ] Implement user authentication
- [ ] Regular security updates
- [ ] Firewall configuration
- [ ] Limit file upload sizes
- [ ] Input validation enabled
- [ ] Regular backups configured
- [ ] Access logs monitored

## Troubleshooting

### ⚠️ Server Serving Old Version After Deployment (COMMON ISSUE)

**Quick Fix:**
```bash
# Step 1: Force restart with cache clearing
sudo deployment/force-restart-shiny.sh

# Step 2: Clear your browser cache
# Chrome/Firefox: Ctrl+Shift+R (or Cmd+Shift+R on Mac)
# Or open in Incognito/Private mode
```

**Diagnose the Issue:**
```bash
# Check what's wrong
sudo deployment/check-deployment-status.sh
```

**Why This Happens:**
1. **Browser cache** (most common) - Browser caches old JavaScript/CSS
2. **Active R processes** - Old R sessions still running
3. **Shiny Server cache** - Cached application state
4. **Soft restart** - Processes not killed properly

**Prevention:**
- The updated `deploy.sh` now automatically handles all of these
- Always clear browser cache after deployment
- Use force-restart-shiny.sh if issues persist

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for complete guide.

### Application won't start
```bash
# Check logs
docker-compose logs -f  # Docker
sudo tail -f /var/log/shiny-server/marinesabres.log  # Shiny Server

# Verify R packages
Rscript -e "library(shiny); library(visNetwork)"

# Check permissions
ls -la /srv/shiny-server/marinesabres

# Test if app loads
sudo -u shiny Rscript /srv/shiny-server/marinesabres/app.R
```

### Port already in use
```bash
# Find process using port 3838
sudo lsof -i :3838

# Kill process
sudo kill -9 <PID>
```

### Translation errors after deployment
```bash
# Check modular translation structure
ls -la /srv/shiny-server/marinesabres/translations/

# Verify scripts directory exists
ls -la /srv/shiny-server/marinesabres/scripts/

# Remove stale translation cache
sudo rm -f /srv/shiny-server/marinesabres/translations/_merged_translations.json
sudo deployment/force-restart-shiny.sh
```

### Performance issues
```bash
# Increase memory limit in app
# Add to global.R:
options(shiny.maxRequestSize = 100*1024^2)

# Monitor resources
htop
docker stats
```

## Support Resources

**Documentation:**
- Full Guide: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- App Documentation: [../www/user_guide.html](../www/user_guide.html)

**Links:**
- Shiny Server: https://posit.co/products/open-source/shinyserver/
- Docker: https://docs.docker.com/
- ShinyApps.io: https://www.shinyapps.io/

**Contact:**
- GitHub Issues: [repository]/issues
- Email: support@marinesabres.eu

## License

This deployment package is part of the MarineSABRES SES Tool.
See main LICENSE file for details.

## Version

- **Package Version**: 1.2
- **Last Updated**: 2025-12-01
- **R Version**: 4.4.1+
- **Shiny Server**: 1.5.21+
- **Docker**: 20.10+

## Recent Updates

### v1.2 (2025-12-01)
- ✅ **NEW:** Modular translation system support
- ✅ **NEW:** Automatic cache clearing in deployment
- ✅ **NEW:** Force restart script (force-restart-shiny.sh)
- ✅ **NEW:** Deployment diagnostics script (check-deployment-status.sh)
- ✅ **NEW:** Comprehensive troubleshooting guide (TROUBLESHOOTING.md)
- ✅ **FIXED:** "Server serving old version" issue
- ✅ **IMPROVED:** Full stop/start cycle instead of restart
- ✅ **IMPROVED:** Scripts directory now included in deployment
- ✅ **IMPROVED:** Browser cache reminder in deployment output
- ✅ **IMPROVED:** Pre-deploy validation for modular translations

### v1.1 (2024-11-17)
- Added pre-deployment validation script
- Updated framework validation
- Enhanced error reporting

### v1.0 (2024-10-21)
- Initial deployment package
- Docker and Shiny Server support
- Automated deployment scripts
