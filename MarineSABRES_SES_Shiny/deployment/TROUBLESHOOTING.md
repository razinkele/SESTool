# Deployment Troubleshooting Guide

## Problem: Server Serving Old Version After Deployment

If after running `sudo ./deploy.sh --shiny-server` the server is still serving an old version of the app, follow these steps:

### Quick Fix (Try This First)

1. **Clear browser cache** - This is the #1 cause of "old version" issues
   ```bash
   # In your browser:
   # Chrome/Firefox: Ctrl+Shift+R (Windows/Linux) or Cmd+Shift+R (Mac)
   # Or: Open in Incognito/Private browsing mode
   ```

2. **Force restart Shiny Server**
   ```bash
   sudo deployment/force-restart-shiny.sh
   ```

### Diagnostic Tools

#### Check Deployment Status
```bash
sudo deployment/check-deployment-status.sh
```

This script will:
- Check if Shiny Server is running
- Compare file timestamps between source and deployed files
- Verify translation system is deployed correctly
- Check for cache directories
- Show recent application logs

#### Check Application Logs
```bash
# View real-time logs
sudo tail -f /var/log/shiny-server/marinesabres.log

# Or check systemd logs
sudo journalctl -u shiny-server -n 50
```

### Common Causes and Solutions

#### 1. Browser Cache (Most Common)
**Symptom**: Files are deployed correctly but browser shows old UI

**Solution**:
- Hard refresh: Ctrl+Shift+R (or Cmd+Shift+R)
- Use Incognito/Private mode
- Clear browser cache completely

#### 2. Active R Processes Not Killed
**Symptom**: Old R processes still running with old code

**Solution**:
```bash
# Kill all Shiny R processes
sudo pkill -9 -f 'shiny.*R'

# Restart Shiny Server
sudo systemctl restart shiny-server
```

#### 3. Shiny Server Cache
**Symptom**: Shiny Server caching old application state

**Solution**:
```bash
# Clear Shiny Server cache
sudo rm -rf /var/lib/shiny-server/bookmarks/*
sudo rm -rf /tmp/shiny-server/*

# Restart
sudo systemctl restart shiny-server
```

#### 4. Incomplete Deployment
**Symptom**: Some files not copied or outdated

**Solution**:
```bash
# Check deployment status
sudo deployment/check-deployment-status.sh

# Re-deploy
sudo deployment/deploy.sh --shiny-server
```

#### 5. Stale Translation Cache
**Symptom**: Old translations showing up

**Solution**:
```bash
# Remove stale merged translations
sudo rm -f /srv/shiny-server/marinesabres/translations/_merged_translations.json

# Restart
sudo deployment/force-restart-shiny.sh
```

### Complete Reset (Nuclear Option)

If nothing else works:

```bash
# 1. Stop Shiny Server
sudo systemctl stop shiny-server

# 2. Kill ALL R processes
sudo pkill -9 -f 'R'

# 3. Clear all caches
sudo rm -rf /var/lib/shiny-server/bookmarks/*
sudo rm -rf /tmp/shiny-server/*
sudo rm -rf /srv/shiny-server/marinesabres/translations/_merged_translations.json

# 4. Wait a moment
sleep 5

# 5. Start Shiny Server
sudo systemctl start shiny-server

# 6. Check status
sudo systemctl status shiny-server

# 7. Clear browser cache completely
```

### Verify Deployment Success

After fixing the issue, verify the deployment:

1. **Check file timestamps**:
   ```bash
   sudo deployment/check-deployment-status.sh | grep -A 3 "File Modification"
   ```

2. **Check version**:
   ```bash
   cat /srv/shiny-server/marinesabres/VERSION
   ```

3. **Check logs for errors**:
   ```bash
   sudo tail -50 /var/log/shiny-server/marinesabres.log | grep -i error
   ```

4. **Access application**: Open in Incognito mode
   ```
   http://YOUR_SERVER_IP:3838/marinesabres
   ```

### Prevention

The updated `deploy.sh` script now automatically:
- ✅ Kills old R processes before deploying
- ✅ Clears Shiny Server cache
- ✅ Removes stale translation caches
- ✅ Performs full stop/start cycle (not just restart)
- ✅ Reminds you to clear browser cache

### Still Not Working?

If you've tried all of the above:

1. Check if files are actually being copied:
   ```bash
   ls -la /srv/shiny-server/marinesabres/
   ```

2. Check permissions:
   ```bash
   ls -la /srv/shiny-server/marinesabres/ | grep shiny
   ```
   All files should be owned by `shiny:shiny`

3. Check if Shiny Server config is correct:
   ```bash
   cat /etc/shiny-server/shiny-server.conf | grep marinesabres
   ```

4. Test if app loads at all:
   ```bash
   curl http://localhost:3838/marinesabres/
   ```

5. Check for R errors in the app:
   ```bash
   sudo -u shiny Rscript /srv/shiny-server/marinesabres/app.R
   ```

## New Deployment Scripts

### force-restart-shiny.sh
Forcefully restarts Shiny Server and clears all caches.
```bash
sudo deployment/force-restart-shiny.sh
```

### check-deployment-status.sh
Diagnoses deployment issues by comparing source and deployed files.
```bash
sudo deployment/check-deployment-status.sh
```

### Updated deploy.sh
Now includes:
- Automatic process killing
- Cache clearing
- Full stop/start cycle
- Browser cache reminder
- Links to diagnostic tools

## Translation System Specific Issues

The new modular translation system requires:
1. ✅ `scripts/` directory deployed (contains `reverse_key_mapping.json`)
2. ✅ `translations/` subdirectories: `common/`, `modules/`, `ui/`, `data/`
3. ✅ `functions/translation_loader.R` present

These are now automatically validated by `pre-deploy-check.R` and `validate-deployment.sh`.
