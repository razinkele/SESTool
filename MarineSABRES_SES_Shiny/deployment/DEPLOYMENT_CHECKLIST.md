# MarineSABRES SES Tool - Deployment Checklist

Use this checklist before deploying to production or updating an existing deployment.

## 📋 Pre-Deployment (Run These First)

### 1. Code Quality
- [ ] Run `Rscript deployment/pre-deploy-check.R`
- [ ] All R syntax checks pass
- [ ] No duplicate translations detected
- [ ] All required files present

### 2. Dependencies
- [ ] R version 4.4.1+ installed
- [ ] All R packages installed (`Rscript deployment/install_dependencies.R`)
- [ ] Docker installed (if using Docker deployment)
- [ ] Sufficient disk space (minimum 2 GB free)

### 3. Translation Updates
- [ ] Check `translations/translation.json` is valid JSON
- [ ] No duplicate entries in translation.json
- [ ] All 7 languages present (en, es, fr, de, lt, pt, it)
- [ ] Recent i18n fixes applied (auto-save status, menu items)

### 4. Clean Up
- [ ] Remove temporary files (*.tmp, *.log, .Rhistory, .RData)
- [ ] Remove test data and development files
- [ ] Remove backup files (*.backup, *_old.R)
- [ ] Verify .dockerignore excludes unnecessary files

## 🚀 Deployment Steps

### Docker Deployment

- [ ] Navigate to deployment directory: `cd deployment`
- [ ] Build Docker image: `docker-compose build`
- [ ] Start containers: `docker-compose up -d`
- [ ] Wait 30 seconds for startup
- [ ] Verify container is running: `docker-compose ps`
- [ ] Check logs for errors: `docker-compose logs`

### Shiny Server Deployment

- [ ] Navigate to deployment directory: `cd deployment`
- [ ] Run deployment script: `sudo ./deploy.sh --shiny-server`
- [ ] Verify Shiny Server is running: `sudo systemctl status shiny-server`
- [ ] Check application logs: `sudo tail -f /var/log/shiny-server/marinesabres/*.log`

## ✅ Post-Deployment Verification

### 1. Basic Functionality
- [ ] Application loads at deployment URL
- [ ] Home page displays correctly
- [ ] No JavaScript errors in browser console
- [ ] Dashboard shows placeholder data

### 2. Translation System
- [ ] Open Settings menu in header
- [ ] "Settings", "Application Settings", "About" are translated
- [ ] Change language to Spanish (es)
- [ ] Menu items translate correctly
- [ ] Change back to English (en)

### 3. Auto-Save Feature
- [ ] Navigate to Dashboard
- [ ] Check auto-save indicator in bottom-right
- [ ] Should show "Auto-save disabled" by default
- [ ] Open settings, enable auto-save
- [ ] Indicator should change to "Auto-save enabled"
- [ ] Disable auto-save
- [ ] Indicator should change to "Auto-save disabled"

### 4. Core Modules
- [ ] **Getting Started** - Entry point loads
- [ ] **Dashboard** - Summary boxes display
- [ ] **Create SES** - Can access Choose Method
- [ ] **AI Assistant** - AI-Assisted ISA Creation loads
- [ ] **Template-Based** - Template selection shows
- [ ] **SES Visualization** - Visualization module accessible
- [ ] **Analysis Tools** - Network Metrics accessible

### 5. Data Persistence
- [ ] Create test project with sample data
- [ ] Save project (sidebar button)
- [ ] Reload browser
- [ ] Load saved project
- [ ] Data persists correctly

### 6. Export Functionality
- [ ] Navigate to Export Data module
- [ ] Verify export options display
- [ ] Test Excel export (if data present)
- [ ] Verify file downloads

## 🐛 Troubleshooting

### Application Won't Start

**Docker:**
```bash
docker-compose logs
docker-compose down
docker-compose up -d
```

**Shiny Server:**
```bash
sudo journalctl -u shiny-server -n 50
sudo systemctl restart shiny-server
```

### Translations Not Working
1. Check `translations/translation.json` is valid: `cat translations/translation.json | jq length`
2. Verify translations directory mounted (Docker): `docker exec marinesabres-ses-tool ls /srv/shiny-server/marinesabres/translations`
3. Check for duplicate entries: `Rscript deployment/pre-deploy-check.R`

### Auto-Save Status Bug
- Verify `modules/auto_save_module.R` has updated logic (checks `auto_save$is_enabled`)
- Check translation for "Auto-save disabled" exists
- Restart application

### Menu Not Translated
- Verify `functions/ui_header.R` uses `i18n$t()` for all menu strings
- Check translations exist: "Settings", "Application Settings", "About", "Bookmark"
- Clear browser cache and reload

## 📊 Performance Monitoring

### After Deployment
- [ ] Monitor memory usage: `docker stats` (Docker) or `htop` (Shiny Server)
- [ ] Check response times (should be < 2 seconds for page loads)
- [ ] Monitor log file sizes: `/var/log/shiny-server/`
- [ ] Set up automated backups for data directory

### Weekly Checks
- [ ] Review error logs
- [ ] Check disk space
- [ ] Verify auto-save creating backups
- [ ] Test restore from backup

## 📝 Documentation Updates

After successful deployment:
- [ ] Update VERSION file with deployment date
- [ ] Update CHANGELOG.md with deployed changes
- [ ] Document any environment-specific configurations
- [ ] Note performance benchmarks

## 🔐 Security Considerations

- [ ] Change default ports if needed
- [ ] Configure firewall rules
- [ ] Set up HTTPS/SSL (production)
- [ ] Restrict file permissions
- [ ] Configure backup retention policy
- [ ] Set up monitoring/alerting

## 📞 Support Contacts

**Deployment Issues:**
- Check logs first
- Review DEPLOYMENT_GUIDE.md
- Run pre-deploy-check.R
- Contact: MarineSABRES technical team

**Translation Issues:**
- See translations/README.md
- Run duplicate detection
- Contact: i18n team

---

**Last Updated:** 2025-11-17  
**Version:** 1.4.0+i18n-fix  
**Branch:** refactor/i18n-fix
