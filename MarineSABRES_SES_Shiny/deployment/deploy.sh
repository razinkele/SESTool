#!/bin/bash
# ============================================================================
# MarineSABRES SES Tool - Quick Deployment Script
# ============================================================================
#
# This script automates the deployment of MarineSABRES to a Shiny Server
#
# Usage:
#   sudo ./deploy.sh [--docker|--shiny-server]
#
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default deployment method
DEPLOY_METHOD="${1:---shiny-server}"

echo "================================================================================"
echo " MarineSABRES SES Tool - Deployment Script"
echo "================================================================================"
echo ""

# Check if running as root for shiny-server deployment
if [[ "$DEPLOY_METHOD" == "--shiny-server" ]] && [[ $EUID -ne 0 ]]; then
   echo -e "${RED}ERROR: This script must be run as root for Shiny Server deployment${NC}"
   echo "Please run: sudo ./deploy.sh"
   exit 1
fi

# Function to print status messages
print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# ============================================================================
# Docker Deployment
# ============================================================================

deploy_docker() {
    print_status "Starting Docker deployment..."

    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        echo "Please install Docker first: https://docs.docker.com/get-docker/"
        exit 1
    fi

    # Check if Docker Compose is installed
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose is not installed"
        echo "Please install Docker Compose first"
        exit 1
    fi

    print_success "Docker and Docker Compose found"

    # Build Docker image
    print_status "Building Docker image..."
    docker-compose build

    # Start containers
    print_status "Starting containers..."
    docker-compose up -d

    # Wait for container to be ready
    print_status "Waiting for application to start..."
    sleep 10

    # Check if container is running
    if docker-compose ps | grep -q "Up"; then
        print_success "Docker deployment successful!"
        echo ""
        echo "Application is running at: http://localhost:3838"
        echo ""
        echo "Useful commands:"
        echo "  - View logs: docker-compose logs -f"
        echo "  - Stop app: docker-compose down"
        echo "  - Restart: docker-compose restart"
    else
        print_error "Container failed to start"
        echo "Check logs with: docker-compose logs"
        exit 1
    fi
}

# ============================================================================
# Shiny Server Deployment
# ============================================================================

deploy_shiny_server() {
    print_status "Starting Shiny Server deployment..."

    # Check if Shiny Server is installed
    if ! systemctl is-active --quiet shiny-server; then
        print_warning "Shiny Server is not running"
        print_status "Installing Shiny Server..."

        # Install R if not present
        if ! command -v R &> /dev/null; then
            print_status "Installing R..."
            apt-get update
            apt-get install -y r-base r-base-dev
        fi

        # Install system dependencies
        print_status "Installing system dependencies..."
        apt-get install -y \
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

        # Download and install Shiny Server
        print_status "Downloading Shiny Server..."
        wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.21.1012-amd64.deb

        print_status "Installing Shiny Server..."
        gdebi -n shiny-server-1.5.21.1012-amd64.deb
        rm shiny-server-1.5.21.1012-amd64.deb

        # Start Shiny Server
        systemctl enable shiny-server
        systemctl start shiny-server

        print_success "Shiny Server installed"
    else
        print_success "Shiny Server is running"
    fi

    # Install R package dependencies
    print_status "Installing R package dependencies..."
    Rscript install_dependencies.R

    if [ $? -ne 0 ]; then
        print_error "Failed to install R dependencies"
        exit 1
    fi

    print_success "R dependencies installed"

    # Copy application files
    print_status "Deploying application files..."

    # Create app directory
    mkdir -p /srv/shiny-server/marinesabres

    # Copy files
    cp -r ../* /srv/shiny-server/marinesabres/

    # Set permissions
    chown -R shiny:shiny /srv/shiny-server/marinesabres

    print_success "Application files deployed"

    # Configure Shiny Server
    print_status "Configuring Shiny Server..."

    # Backup original config
    if [ -f /etc/shiny-server/shiny-server.conf ]; then
        cp /etc/shiny-server/shiny-server.conf /etc/shiny-server/shiny-server.conf.backup
        print_success "Original config backed up"
    fi

    # Copy new config
    cp shiny-server.conf /etc/shiny-server/shiny-server.conf

    print_success "Shiny Server configured"

    # Restart Shiny Server
    print_status "Restarting Shiny Server..."
    systemctl restart shiny-server

    # Wait for server to start
    sleep 5

    # Check if Shiny Server is running
    if systemctl is-active --quiet shiny-server; then
        print_success "Deployment successful!"
        echo ""
        echo "Application is running at: http://$(hostname -I | awk '{print $1}'):3838/marinesabres"
        echo ""
        echo "Useful commands:"
        echo "  - Check status: sudo systemctl status shiny-server"
        echo "  - View logs: sudo tail -f /var/log/shiny-server.log"
        echo "  - Restart: sudo systemctl restart shiny-server"
    else
        print_error "Shiny Server failed to start"
        echo "Check logs with: sudo journalctl -u shiny-server -n 50"
        exit 1
    fi
}

# ============================================================================
# Main execution
# ============================================================================

case "$DEPLOY_METHOD" in
    --docker)
        deploy_docker
        ;;
    --shiny-server)
        deploy_shiny_server
        ;;
    *)
        echo "Usage: $0 [--docker|--shiny-server]"
        echo ""
        echo "Deployment methods:"
        echo "  --docker         Deploy using Docker (default)"
        echo "  --shiny-server   Deploy to Shiny Server"
        exit 1
        ;;
esac

echo ""
echo "================================================================================"
echo " Deployment Complete!"
echo "================================================================================"
echo ""
