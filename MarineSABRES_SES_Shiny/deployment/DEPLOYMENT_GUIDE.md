# MarineSABRES SES Tool - Deployment Guide

## Table of Contents

1. [Overview](#overview)
2. [Deployment Options](#deployment-options)
3. [Docker Deployment (Recommended)](#docker-deployment-recommended)
4. [Shiny Server Deployment](#shiny-server-deployment)
5. [ShinyApps.io Deployment](#shinyappsio-deployment)
6. [Configuration](#configuration)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance](#maintenance)

---

## Overview

The MarineSABRES Social-Ecological Systems Analysis Tool is a Shiny application designed for collaborative analysis of marine social-ecological systems using the DAPSI(W)R(M) framework.

**System Requirements:**
- R version 4.4.1 or higher
- 4 GB RAM minimum (8 GB recommended)
- 2 GB disk space
- Linux, macOS, or Windows Server

**Network Requirements:**
- Port 3838 (default Shiny Server port)
- HTTPS support recommended for production

---

## Deployment Options

### Option 1: Docker (Recommended)
- **Pros**: Isolated environment, easy updates, portable
- **Cons**: Requires Docker knowledge
- **Best for**: Production servers, cloud deployment

### Option 2: Shiny Server
- **Pros**: Native R environment, fine-grained control
- **Cons**: Manual dependency management
- **Best for**: Dedicated servers, institutional hosting

### Option 3: ShinyApps.io
- **Pros**: Managed hosting, no server management
- **Cons**: Subscription costs, resource limits
- **Best for**: Quick demos, small teams

---

## Docker Deployment (Recommended)

### Prerequisites

1. Install Docker and Docker Compose:
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install docker.io docker-compose

   # Or use Docker Desktop (Windows/Mac)
   ```

### Deployment Steps

1. **Clone or copy the application files**:
   ```bash
   cd /srv
   git clone <repository-url> marinesabres
   cd marinesabres/MarineSABRES_SES_Shiny
   ```

2. **Build the Docker image**:
   ```bash
   cd deployment
   docker-compose build
   ```

3. **Start the container**:
   ```bash
   docker-compose up -d
   ```

4. **Verify the deployment**:
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

5. **Access the application**:
   - Open browser: `http://your-server-ip:3838`
   - Or: `http://localhost:3838` (if local)

### Docker Management Commands

```bash
# Stop the application
docker-compose down

# Restart the application
docker-compose restart

# View logs
docker-compose logs -f marinesabres-shiny

# Update the application
git pull
docker-compose build
docker-compose up -d

# Access container shell
docker exec -it marinesabres-ses-tool /bin/bash
```

---

## Shiny Server Deployment

### Prerequisites

1. **Install R** (version 4.4.1+):
   ```bash
   # Ubuntu 22.04
   sudo apt-get update
   sudo apt-get install -y r-base r-base-dev

   # Verify installation
   R --version
   ```

2. **Install system dependencies**:
   ```bash
   sudo apt-get install -y \
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

3. **Install Shiny Server**:
   ```bash
   # Download Shiny Server
   wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.21.1012-amd64.deb

   # Install
   sudo gdebi shiny-server-1.5.21.1012-amd64.deb

   # Verify installation
   sudo systemctl status shiny-server
   ```

### Deployment Steps

1. **Install R package dependencies**:
   ```bash
   cd /path/to/MarineSABRES_SES_Shiny/deployment
   sudo Rscript install_dependencies.R
   ```

2. **Copy application to Shiny Server directory**:
   ```bash
   sudo cp -r ../. /srv/shiny-server/marinesabres/
   sudo chown -R shiny:shiny /srv/shiny-server/marinesabres
   ```

3. **Configure Shiny Server**:
   ```bash
   # Backup original config
   sudo cp /etc/shiny-server/shiny-server.conf /etc/shiny-server/shiny-server.conf.backup

   # Copy new configuration
   sudo cp shiny-server.conf /etc/shiny-server/shiny-server.conf
   ```

4. **Restart Shiny Server**:
   ```bash
   sudo systemctl restart shiny-server
   ```

5. **Check status**:
   ```bash
   sudo systemctl status shiny-server
   sudo tail -f /var/log/shiny-server.log
   ```

6. **Access the application**:
   - Open browser: `http://your-server-ip:3838/marinesabres`

### Firewall Configuration

```bash
# Allow Shiny Server port
sudo ufw allow 3838/tcp
sudo ufw reload
```

---

## ShinyApps.io Deployment

### Prerequisites

1. **Create ShinyApps.io account**: https://www.shinyapps.io/
2. **Install rsconnect package**:
   ```r
   install.packages("rsconnect")
   ```

### Deployment Steps

1. **Configure rsconnect** (one-time setup):
   ```r
   library(rsconnect)
   rsconnect::setAccountInfo(
     name = "your-account-name",
     token = "your-token",
     secret = "your-secret"
   )
   ```

2. **Deploy the application**:
   ```r
   # From R console, in the app directory
   setwd("/path/to/MarineSABRES_SES_Shiny")
   rsconnect::deployApp(
     appName = "marinesabres-ses-tool",
     appTitle = "MarineSABRES SES Analysis Tool",
     account = "your-account-name"
   )
   ```

3. **Access the application**:
   - URL: `https://your-account.shinyapps.io/marinesabres-ses-tool/`

---

## Configuration

### Environment Variables

Create a `.Renviron` file in the app directory:

```bash
# Application settings
MARINESABRES_ENV=production
MARINESABRES_LOG_LEVEL=INFO

# Data persistence
MARINESABRES_DATA_DIR=/srv/shiny-server/marinesabres/data

# Session timeout (seconds)
SHINY_SESSION_TIMEOUT=3600
```

### Resource Limits

Edit Shiny Server config to set resource limits:

```conf
location /marinesabres {
  app_dir /srv/shiny-server/marinesabres;

  # Increase timeouts for long operations
  app_init_timeout 60;
  app_idle_timeout 3600;

  # Set max connections
  simple_scheduler 20;
}
```

### HTTPS/SSL Configuration

1. **Obtain SSL certificate** (Let's Encrypt recommended):
   ```bash
   sudo apt-get install certbot
   sudo certbot certonly --standalone -d your-domain.com
   ```

2. **Configure reverse proxy** (nginx example):
   ```nginx
   server {
     listen 443 ssl;
     server_name your-domain.com;

     ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

     location / {
       proxy_pass http://localhost:3838;
       proxy_redirect http://localhost:3838/ $scheme://$host/;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_read_timeout 3600s;
     }
   }
   ```

---

## Troubleshooting

### Application won't start

1. **Check logs**:
   ```bash
   # Docker
   docker-compose logs -f

   # Shiny Server
   sudo tail -f /var/log/shiny-server/marinesabres-shiny*.log
   ```

2. **Verify R packages**:
   ```bash
   Rscript -e "library(shiny); library(shinydashboard); library(visNetwork)"
   ```

3. **Check permissions**:
   ```bash
   ls -la /srv/shiny-server/marinesabres
   sudo chown -R shiny:shiny /srv/shiny-server/marinesabres
   ```

### Performance issues

1. **Increase memory limit**:
   ```r
   # In app.R or global.R
   options(shiny.maxRequestSize = 100*1024^2)  # 100 MB
   ```

2. **Enable caching**:
   ```r
   # Use reactiveVal() and reactive() efficiently
   # Cache expensive computations
   ```

3. **Monitor resources**:
   ```bash
   htop
   docker stats  # For Docker deployment
   ```

### Connection timeouts

1. **Increase timeout settings** in shiny-server.conf:
   ```conf
   app_idle_timeout 7200;  # 2 hours
   ```

2. **Configure reconnect**:
   ```conf
   reconnect true;
   ```

---

## Maintenance

### Regular Updates

1. **Update R packages**:
   ```bash
   sudo Rscript -e "update.packages(ask = FALSE)"
   ```

2. **Update application**:
   ```bash
   cd /srv/marinesabres
   git pull
   sudo cp -r MarineSABRES_SES_Shiny/* /srv/shiny-server/marinesabres/
   sudo systemctl restart shiny-server
   ```

### Backup

1. **Backup user data**:
   ```bash
   tar -czf marinesabres-data-$(date +%Y%m%d).tar.gz \
     /srv/shiny-server/marinesabres/data
   ```

2. **Automated backups** (cron):
   ```bash
   # Add to crontab (sudo crontab -e)
   0 2 * * * /usr/local/bin/backup-marinesabres.sh
   ```

### Monitoring

1. **Application logs**:
   ```bash
   tail -f /var/log/shiny-server/marinesabres-shiny*.log
   ```

2. **Server metrics**:
   - Use tools like Grafana + Prometheus
   - Monitor CPU, memory, disk usage
   - Track active users and sessions

---

## Security Recommendations

1. **Use HTTPS** in production
2. **Implement authentication** (ShinyProxy, auth0, etc.)
3. **Regular security updates**:
   ```bash
   sudo apt-get update && sudo apt-get upgrade
   ```
4. **Firewall configuration**:
   ```bash
   sudo ufw enable
   sudo ufw allow ssh
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```
5. **Limit file upload sizes** in the app
6. **Validate user inputs** server-side
7. **Regular backups** of user data

---

## Support

For issues or questions:
- GitHub Issues: [repository-url]/issues
- Email: support@marinesabres.eu
- Documentation: [repository-url]/wiki

---

## Version Information

- **Application Version**: 1.0
- **Last Updated**: 2025-10-21
- **R Version Required**: 4.4.1+
- **Shiny Server Version**: 1.5.21+
