# Shiny Server Deployment - Quick Reference

## Prerequisites

- Ubuntu/Debian Linux system
- Root/sudo access
- R installed (version 4.0+)
- Internet connection for downloading packages

## Quick Deployment

```bash
cd deployment
sudo ./deploy.sh --shiny-server
```

## Step-by-Step Manual Deployment

### 1. Install System Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
    r-base \
    r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    pandoc \
    gdebi-core
```

### 2. Install Shiny Server

```bash
# Download Shiny Server
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.21.1012-amd64.deb

# Install
sudo gdebi -n shiny-server-1.5.21.1012-amd64.deb

# Enable and start service
sudo systemctl enable shiny-server
sudo systemctl start shiny-server
```

### 3. Install R Package Dependencies

```bash
cd deployment
Rscript install_dependencies.R
```

### 4. Deploy Application Files

```bash
# Create application directory
sudo mkdir -p /srv/shiny-server/marinesabres

# Copy application files
sudo cp ../app.R /srv/shiny-server/marinesabres/
sudo cp ../global.R /srv/shiny-server/marinesabres/
sudo cp ../run_app.R /srv/shiny-server/marinesabres/
sudo cp ../constants.R /srv/shiny-server/marinesabres/
sudo cp ../io.R /srv/shiny-server/marinesabres/
sudo cp ../utils.R /srv/shiny-server/marinesabres/
sudo cp ../VERSION /srv/shiny-server/marinesabres/
sudo cp ../VERSION_INFO.json /srv/shiny-server/marinesabres/
sudo cp ../version_manager.R /srv/shiny-server/marinesabres/

# Copy directories
sudo cp -r ../modules /srv/shiny-server/marinesabres/
sudo cp -r ../functions /srv/shiny-server/marinesabres/
sudo cp -r ../server /srv/shiny-server/marinesabres/
sudo cp -r ../www /srv/shiny-server/marinesabres/
sudo cp -r ../data /srv/shiny-server/marinesabres/
sudo cp -r ../translations /srv/shiny-server/marinesabres/

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/marinesabres
```

### 5. Configure Shiny Server

```bash
# Backup original configuration
sudo cp /etc/shiny-server/shiny-server.conf /etc/shiny-server/shiny-server.conf.backup

# Copy MarineSABRES configuration
sudo cp shiny-server.conf /etc/shiny-server/shiny-server.conf

# Restart Shiny Server
sudo systemctl restart shiny-server
```

### 6. Validate Deployment

```bash
sudo ./validate-deployment.sh
```

## Application Access

After deployment, access the application at:
- **Local**: http://localhost:3838/marinesabres
- **Network**: http://YOUR_SERVER_IP:3838/marinesabres

## Management Commands

### Service Control

```bash
# Check status
sudo systemctl status shiny-server

# Start service
sudo systemctl start shiny-server

# Stop service
sudo systemctl stop shiny-server

# Restart service
sudo systemctl restart shiny-server

# Enable on boot
sudo systemctl enable shiny-server

# Disable on boot
sudo systemctl disable shiny-server
```

### View Logs

```bash
# Main Shiny Server log
sudo tail -f /var/log/shiny-server.log

# Application-specific log
sudo tail -f /var/log/shiny-server/marinesabres.log

# System service log
sudo journalctl -u shiny-server -f
```

### Update Application

```bash
# Stop service
sudo systemctl stop shiny-server

# Backup data
sudo cp -r /srv/shiny-server/marinesabres/data /tmp/marinesabres-data-backup

# Remove old files (keep data)
sudo rm -rf /srv/shiny-server/marinesabres/*

# Deploy new version (follow step 4)
# ...

# Restore data if needed
sudo cp -r /tmp/marinesabres-data-backup /srv/shiny-server/marinesabres/data

# Set permissions
sudo chown -R shiny:shiny /srv/shiny-server/marinesabres

# Start service
sudo systemctl start shiny-server
```

## Troubleshooting

### Application Won't Start

1. Check service status:
```bash
sudo systemctl status shiny-server
```

2. Check logs for errors:
```bash
sudo tail -50 /var/log/shiny-server.log
sudo tail -50 /var/log/shiny-server/marinesabres.log
```

3. Verify file permissions:
```bash
ls -la /srv/shiny-server/marinesabres/
```

4. Test if shiny user can read files:
```bash
sudo -u shiny test -r /srv/shiny-server/marinesabres/app.R && echo "OK" || echo "FAIL"
```

### Missing R Packages

1. Check which packages are installed:
```bash
Rscript -e "installed.packages()[,'Package']"
```

2. Install missing packages:
```bash
cd deployment
Rscript install_dependencies.R
```

3. Restart Shiny Server:
```bash
sudo systemctl restart shiny-server
```

### Port 3838 Not Accessible

1. Check if port is listening:
```bash
sudo netstat -tuln | grep 3838
# or
sudo ss -tuln | grep 3838
```

2. Check firewall rules:
```bash
sudo ufw status
sudo ufw allow 3838/tcp
```

3. Check Shiny Server configuration:
```bash
sudo cat /etc/shiny-server/shiny-server.conf
```

### High Memory Usage

1. Check current memory usage:
```bash
free -h
```

2. Limit application memory in `shiny-server.conf`:
```
location /marinesabres {
  app_dir /srv/shiny-server/marinesabres;
  
  # Limit number of processes
  app_max_processes 3;
  
  # Set memory limit
  utilization_scheduler 0;
}
```

3. Restart service:
```bash
sudo systemctl restart shiny-server
```

### Application Crashes

1. Check system resources:
```bash
df -h                    # Disk space
free -h                  # Memory
top                      # CPU usage
```

2. Increase timeout in `shiny-server.conf`:
```
location /marinesabres {
  app_dir /srv/shiny-server/marinesabres;
  
  app_init_timeout 120;
  app_idle_timeout 7200;
}
```

3. Check R process limits:
```bash
sudo -u shiny bash -c 'ulimit -a'
```

## Performance Tuning

### For Production Use

Edit `/etc/shiny-server/shiny-server.conf`:

```
# Adjust based on your server resources
location /marinesabres {
  app_dir /srv/shiny-server/marinesabres;
  log_dir /var/log/shiny-server/marinesabres;
  
  # Timeouts (in seconds)
  app_init_timeout 120;        # Time to start app
  app_idle_timeout 3600;       # Keep alive for 1 hour
  
  # Process management
  app_max_processes 5;         # Max concurrent processes
  app_min_processes 1;         # Keep 1 always running
  
  # Load balancing
  utilization_scheduler 0.7;   # Start new process at 70% load
  
  # WebSocket support
  websocket true;
  
  # Reconnect settings
  reconnect true;
}
```

### Log Rotation

Create `/etc/logrotate.d/shiny-server`:

```
/var/log/shiny-server/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 shiny shiny
    sharedscripts
    postrotate
        systemctl reload shiny-server > /dev/null 2>&1 || true
    endscript
}
```

## HTTPS Setup (Nginx Reverse Proxy)

### 1. Install Nginx

```bash
sudo apt-get install nginx certbot python3-certbot-nginx
```

### 2. Configure Nginx

Create `/etc/nginx/sites-available/marinesabres`:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3838/marinesabres/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
```

### 3. Enable Site

```bash
sudo ln -s /etc/nginx/sites-available/marinesabres /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 4. Setup SSL

```bash
sudo certbot --nginx -d your-domain.com
```

## Backup and Restore

### Backup

```bash
#!/bin/bash
# backup-marinesabres.sh

BACKUP_DIR="/backup/marinesabres"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup data directory
sudo tar -czf "$BACKUP_DIR/data_$DATE.tar.gz" /srv/shiny-server/marinesabres/data

# Backup configuration
sudo cp /etc/shiny-server/shiny-server.conf "$BACKUP_DIR/shiny-server.conf_$DATE"

echo "Backup completed: $BACKUP_DIR"
```

### Restore

```bash
#!/bin/bash
# restore-marinesabres.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup_file.tar.gz>"
    exit 1
fi

sudo systemctl stop shiny-server
sudo tar -xzf "$BACKUP_FILE" -C /
sudo chown -R shiny:shiny /srv/shiny-server/marinesabres
sudo systemctl start shiny-server
```

## Monitoring

### Check Application Health

```bash
# HTTP check
curl -I http://localhost:3838/marinesabres/

# Process check
ps aux | grep shiny-server

# Memory usage
ps aux | grep shiny-server | awk '{print $6}'
```

### Setup Monitoring with systemd

Create `/etc/systemd/system/marinesabres-monitor.service`:

```ini
[Unit]
Description=MarineSABRES Health Monitor
After=shiny-server.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/check-marinesabres.sh

[Install]
WantedBy=multi-user.target
```

Create `/etc/systemd/system/marinesabres-monitor.timer`:

```ini
[Unit]
Description=Run MarineSABRES Health Check every 5 minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable marinesabres-monitor.timer
sudo systemctl start marinesabres-monitor.timer
```

## Security Recommendations

1. **Firewall**: Only allow necessary ports
```bash
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
```

2. **Updates**: Keep system updated
```bash
sudo apt-get update && sudo apt-get upgrade -y
```

3. **Authentication**: Use Nginx with basic auth or OAuth
4. **SSL**: Always use HTTPS in production
5. **Backups**: Automated daily backups of data directory

## Support

- Shiny Server Documentation: https://docs.posit.co/shiny-server/
- Deployment Guide: See `DEPLOYMENT_GUIDE.md`
- Troubleshooting: See logs in `/var/log/shiny-server/`
