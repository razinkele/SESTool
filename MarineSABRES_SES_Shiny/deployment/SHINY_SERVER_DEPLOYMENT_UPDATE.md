# Non-Docker (Shiny Server) Deployment - Update Summary

**Date**: November 17, 2025  
**Type**: Shiny Server Direct Deployment

## Overview

The non-Docker deployment framework has been thoroughly updated and validated for deploying MarineSABRES SES Tool directly to a Shiny Server installation.

## Updated Files

### 1. deploy.sh
**Location**: `deployment/deploy.sh`

**Key Updates**:
- Fixed function declaration order (moved helper functions before first use)
- Improved file copying logic with explicit file list instead of wildcard
- Added data directory backup/restore during updates
- Fixed working directory handling for `install_dependencies.R`
- Selective file copying to exclude development files:
  - Core files: `app.R`, `global.R`, `run_app.R`, `constants.R`, `io.R`, `utils.R`
  - Version files: `VERSION`, `VERSION_INFO.json`, `version_manager.R`
  - Directories: `modules/`, `functions/`, `server/`, `www/`, `data/`, `translations/`

**Removed Issues**:
- ✓ Fixed "command not found" for print_* functions
- ✓ Prevents copying test files, docs, and development scripts
- ✓ Preserves user data during updates

### 2. validate-deployment.sh (NEW)
**Location**: `deployment/validate-deployment.sh`

**Purpose**: Post-deployment validation script

**Features**:
- Checks Shiny Server service status
- Verifies all application files and directories
- Validates file permissions
- Tests HTTP access to application
- Checks R package dependencies
- Monitors system resources (disk, memory)
- Comprehensive reporting with pass/fail/warning status

**Usage**:
```bash
sudo ./validate-deployment.sh
```

### 3. shiny-server.conf
**Location**: `deployment/shiny-server.conf`

**Configuration**:
- Application path: `/srv/shiny-server/marinesabres`
- Port: 3838
- Timeouts:
  - `app_init_timeout`: 60 seconds
  - `app_idle_timeout`: 3600 seconds (1 hour)
- Reconnect enabled
- Dedicated log directory

**No changes needed** - configuration already optimal.

### 4. SHINY_SERVER_REFERENCE.md (NEW)
**Location**: `deployment/SHINY_SERVER_REFERENCE.md`

**Comprehensive Guide** including:
- Step-by-step installation
- Management commands
- Troubleshooting procedures
- Performance tuning
- HTTPS setup with Nginx
- Backup/restore procedures
- Monitoring setup
- Security recommendations

## Deployment Workflow

### Quick Deployment (Automated)

```bash
cd deployment
sudo ./deploy.sh --shiny-server
```

The script will:
1. Run pre-deployment checks
2. Install Shiny Server (if not present)
3. Install system dependencies
4. Install R package dependencies
5. Deploy application files
6. Configure Shiny Server
7. Restart service
8. Display application URL

### Validation

After deployment:
```bash
cd deployment
sudo ./validate-deployment.sh
```

## Directory Structure on Server

```
/srv/shiny-server/marinesabres/
├── app.R
├── global.R
├── run_app.R
├── constants.R
├── io.R
├── utils.R
├── VERSION
├── VERSION_INFO.json
├── version_manager.R
├── modules/
├── functions/
├── server/
├── www/
├── data/
└── translations/
```

## Key Differences from Docker Deployment

| Aspect | Docker | Shiny Server |
|--------|--------|--------------|
| **Isolation** | Complete container isolation | Shared system resources |
| **Dependencies** | Bundled in image | System-wide installation |
| **Updates** | Rebuild entire image | Update files in place |
| **Portability** | Highly portable | Server-specific |
| **Resource Usage** | Container overhead | Direct execution |
| **Configuration** | docker-compose.yml | shiny-server.conf |
| **Logs** | Docker logs | /var/log/shiny-server/ |
| **Management** | docker-compose commands | systemctl commands |

## Management Commands

### Service Control
```bash
# Status
sudo systemctl status shiny-server

# Start/Stop/Restart
sudo systemctl start shiny-server
sudo systemctl stop shiny-server
sudo systemctl restart shiny-server

# Enable/Disable on boot
sudo systemctl enable shiny-server
sudo systemctl disable shiny-server
```

### View Logs
```bash
# Application log
sudo tail -f /var/log/shiny-server/marinesabres.log

# Server log
sudo tail -f /var/log/shiny-server.log

# System service log
sudo journalctl -u shiny-server -f
```

### Update Application
```bash
# Method 1: Use deploy script (recommended)
cd deployment
sudo ./deploy.sh --shiny-server

# Method 2: Manual update
sudo systemctl stop shiny-server
# Copy new files...
sudo chown -R shiny:shiny /srv/shiny-server/marinesabres
sudo systemctl start shiny-server
```

## Troubleshooting

### Common Issues

**1. Service Won't Start**
```bash
# Check status
sudo systemctl status shiny-server

# Check logs
sudo tail -50 /var/log/shiny-server.log

# Verify configuration
sudo shiny-server -t
```

**2. Missing R Packages**
```bash
cd deployment
Rscript install_dependencies.R
sudo systemctl restart shiny-server
```

**3. Permission Errors**
```bash
sudo chown -R shiny:shiny /srv/shiny-server/marinesabres
sudo chmod -R 755 /srv/shiny-server/marinesabres
sudo systemctl restart shiny-server
```

**4. Port Not Accessible**
```bash
# Check if listening
sudo netstat -tuln | grep 3838

# Check firewall
sudo ufw status
sudo ufw allow 3838/tcp
```

## Performance Tuning

For production deployments, edit `/etc/shiny-server/shiny-server.conf`:

```
location /marinesabres {
  app_dir /srv/shiny-server/marinesabres;
  log_dir /var/log/shiny-server/marinesabres;
  
  # Increase timeouts for long operations
  app_init_timeout 120;
  app_idle_timeout 7200;
  
  # Process management
  app_max_processes 5;
  app_min_processes 1;
  
  # Load balancing
  utilization_scheduler 0.7;
  
  # WebSocket support
  websocket true;
  reconnect true;
}
```

## Security Recommendations

1. **Use HTTPS**: Set up Nginx reverse proxy with SSL
2. **Firewall**: Restrict access to necessary ports only
3. **Updates**: Keep system and R packages updated
4. **Authentication**: Consider adding basic auth or OAuth
5. **Backups**: Regular automated backups of data directory
6. **Monitoring**: Set up health checks and alerting

## HTTPS Setup (Production)

### Using Nginx Reverse Proxy

```bash
# Install Nginx
sudo apt-get install nginx certbot python3-certbot-nginx

# Configure reverse proxy
sudo nano /etc/nginx/sites-available/marinesabres

# Enable site
sudo ln -s /etc/nginx/sites-available/marinesabres /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Setup SSL with Let's Encrypt
sudo certbot --nginx -d your-domain.com
```

See `SHINY_SERVER_REFERENCE.md` for detailed Nginx configuration.

## Backup Strategy

### Automated Backup Script

Create `/usr/local/bin/backup-marinesabres.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/backup/marinesabres"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p "$BACKUP_DIR"
sudo tar -czf "$BACKUP_DIR/data_$DATE.tar.gz" /srv/shiny-server/marinesabres/data
# Keep only last 7 days
find "$BACKUP_DIR" -name "data_*.tar.gz" -mtime +7 -delete
```

### Cron Job for Daily Backups

```bash
# Add to crontab
sudo crontab -e

# Run daily at 2 AM
0 2 * * * /usr/local/bin/backup-marinesabres.sh
```

## Monitoring

### Health Check Script

Create `/usr/local/bin/check-marinesabres.sh`:

```bash
#!/bin/bash
URL="http://localhost:3838/marinesabres/"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$URL")

if [ "$STATUS" != "200" ]; then
    echo "MarineSABRES is down! HTTP Status: $STATUS"
    sudo systemctl restart shiny-server
    # Send alert email
    echo "MarineSABRES was restarted" | mail -s "Alert: MarineSABRES Down" admin@example.com
fi
```

### Systemd Timer

See `SHINY_SERVER_REFERENCE.md` for systemd timer configuration.

## Testing the Deployment

After deployment, verify:

1. **Service Status**: `sudo systemctl status shiny-server`
2. **Application Access**: Browse to http://YOUR_SERVER_IP:3838/marinesabres
3. **Template Loading**: Try loading different templates
4. **CLD Visualization**: Verify network renders correctly
5. **Responses Work**: Check response nodes appear
6. **Data Persistence**: Create project, reload page, verify data persists
7. **Translations**: Switch between languages
8. **Export Functions**: Test JSON/Excel export

## Upgrade Path

### From Docker to Shiny Server

If migrating from Docker deployment:

```bash
# Export data from Docker
docker cp marinesabres-ses-tool:/srv/shiny-server/marinesabres/data ./data-backup

# Deploy to Shiny Server
cd deployment
sudo ./deploy.sh --shiny-server

# Stop and restore data
sudo systemctl stop shiny-server
sudo cp -r ./data-backup/* /srv/shiny-server/marinesabres/data/
sudo chown -R shiny:shiny /srv/shiny-server/marinesabres/data
sudo systemctl start shiny-server
```

### From Shiny Server to Docker

If migrating to Docker:

```bash
# Backup data
sudo cp -r /srv/shiny-server/marinesabres/data ./data-backup

# Deploy with Docker
cd deployment
docker-compose up -d

# Data is automatically mounted from ../data directory
```

## Documentation References

- **DEPLOYMENT_GUIDE.md**: Comprehensive deployment guide
- **DEPLOYMENT_CHECKLIST.md**: Pre-deployment checklist
- **SHINY_SERVER_REFERENCE.md**: Complete Shiny Server reference
- **DEPLOYMENT_FRAMEWORK_UPDATE.md**: Docker deployment updates
- **deploy.sh**: Automated deployment script
- **validate-deployment.sh**: Post-deployment validation
- **pre-deploy-check.R**: Pre-deployment validation

## Support Resources

- Shiny Server Admin Guide: https://docs.posit.co/shiny-server/
- R Shiny Documentation: https://shiny.posit.co/
- Project Issues: Check `/var/log/shiny-server/marinesabres.log`
- System Issues: `sudo journalctl -u shiny-server`

## Conclusion

The non-Docker deployment is now fully updated and production-ready with:
- ✅ Automated deployment script
- ✅ Post-deployment validation
- ✅ Comprehensive documentation
- ✅ Troubleshooting guides
- ✅ Performance tuning options
- ✅ Security recommendations
- ✅ Backup/restore procedures
- ✅ Monitoring setup

Both Docker and Shiny Server deployment methods are equally supported and maintained.
