# MarineSABRES SES Tool - Deployment Package

This directory contains all necessary files for deploying the MarineSABRES Social-Ecological Systems Analysis Tool to production servers.

## Quick Start

### Docker Deployment (Recommended)

```bash
cd deployment
docker-compose up -d
```

Access at: http://localhost:3838

### Shiny Server Deployment

```bash
cd deployment
sudo bash deploy.sh --shiny-server
```

Access at: http://your-server:3838/marinesabres

## Package Contents

```
deployment/
├── README.md                    # This file
├── DEPLOYMENT_GUIDE.md          # Comprehensive deployment documentation
├── Dockerfile                   # Docker container configuration
├── docker-compose.yml           # Docker Compose orchestration
├── shiny-server.conf            # Shiny Server configuration
├── install_dependencies.R       # R package installation script
└── deploy.sh                    # Automated deployment script
```

## File Descriptions

### Dockerfile
Docker image definition for containerized deployment. Includes:
- R 4.4.1 base image
- All system dependencies
- All R package dependencies
- Application files
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

### deploy.sh
Automated deployment script supporting:
- Docker deployment
- Shiny Server deployment
- Dependency installation
- Configuration management
- Health checks

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

### Application won't start
```bash
# Check logs
docker-compose logs -f  # Docker
sudo tail -f /var/log/shiny-server.log  # Shiny Server

# Verify R packages
Rscript -e "library(shiny); library(visNetwork)"

# Check permissions
ls -la /srv/shiny-server/marinesabres
```

### Port already in use
```bash
# Find process using port 3838
sudo lsof -i :3838

# Kill process
sudo kill -9 <PID>
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

- **Package Version**: 1.0
- **Last Updated**: 2025-10-21
- **R Version**: 4.4.1+
- **Shiny Server**: 1.5.21+
- **Docker**: 20.10+
