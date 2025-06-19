#!/bin/bash

set -e

# Log file for the setup process
LOG_FILE="/var/log/monitoring_setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Default values for directories
CONFIG_DIR="/tmp/config"
SCRIPT_DIR="/tmp/scripts"
PROMETHEUS_DIR="/etc/prometheus"
ALERTMANAGER_DIR="/etc/alertmanager"
GRAFANA_DIR="/etc/grafana"
LOKI_DIR="/etc/loki"
STATSD_DIR="/etc/statsd"
NGINX_DIR="/etc/nginx/sites-available"
DATA_DIR_BASE="/var/lib"

# Function to check if a directory exists or create it
create_dir() {
  local dir=$1
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir"
    echo "Created directory: $dir"
  else
    echo "Directory already exists: $dir"
  fi
}

# Create necessary directories
create_dir "$PROMETHEUS_DIR"
create_dir "$ALERTMANAGER_DIR"
create_dir "$GRAFANA_DIR"
create_dir "$LOKI_DIR"
create_dir "$STATSD_DIR"
create_dir "$NGINX_DIR"
create_dir "$DATA_DIR_BASE/prometheus"
create_dir "$DATA_DIR_BASE/grafana"
create_dir "$DATA_DIR_BASE/loki"

# Load environment variables from .env file if it exists
if [ -f "$SCRIPT_DIR/.env" ]; then
  source "$SCRIPT_DIR/.env"
  echo "Loaded environment variables from .env file"
else
  echo "Error: .env file not found in $SCRIPT_DIR. Please create the .env file with necessary variables."
  exit 1
fi

# Verify that required environment variables are set
if [ -z "$MONITORING_USERNAME" ] || [ -z "$MONITORING_PASSWORD" ]; then
  echo "Error: MONITORING_USERNAME or MONITORING_PASSWORD is not set in the .env file."
  exit 1
fi

if [ -z "$SMTP_AUTH_USERNAME" ] || [ -z "$SMTP_AUTH_PASSWORD" ] || [ -z "$SMTP_SMARTHOST" ] || [ -z "$SMTP_FROM" ]; then
  echo "Error: SMTP_AUTH_USERNAME, SMTP_AUTH_PASSWORD, SMTP_SMARTHOST, or SMTP_FROM is not set in the .env file."
  exit 1
fi

# Verify configuration files exist
for service in prometheus alertmanager grafana loki statsd nginx; do
  if [ ! -d "$CONFIG_DIR/$service" ]; then
    echo "Error: Configuration directory for $service is missing at $CONFIG_DIR/$service"
    exit 1
  fi
done

# Copy configurations to their respective directories
cp -r "$CONFIG_DIR/prometheus/"* "$PROMETHEUS_DIR/"
cp -r "$CONFIG_DIR/alertmanager/"* "$ALERTMANAGER_DIR/"
cp -r "$CONFIG_DIR/grafana/"* "$GRAFANA_DIR/"
cp -r "$CONFIG_DIR/loki/"* "$LOKI_DIR/"
cp -r "$CONFIG_DIR/statsd/"* "$STATSD_DIR/"
cp -r "$CONFIG_DIR/nginx/nginx.conf" "$NGINX_DIR/"


# Function to wait for apt locks
wait_for_apt_locks() {
    echo "Checking for apt locks..."
    while sudo fuser /var/lib/apt/lists/lock /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
        echo "Waiting for other apt-get processes to finish..."
        sleep 5
    done
# Stop conflicting processes
echo "Stopping any apt or apt-get processes..."
sudo killall apt apt-get >/dev/null 2>&1 || true
}

# Install required packages
wait_for_apt_locks
sudo apt-get update && sudo apt-get install -y apache2-utils unzip certbot python3-certbot-nginx

# Generate .htpasswd file with basic authentication details
HTPASSWD_FILE="/etc/nginx/.htpasswd"
echo "Creating .htpasswd file..."
htpasswd -cb "$HTPASSWD_FILE" "$MONITORING_USERNAME" "$MONITORING_PASSWORD"

# Install services one at a time
for script in install_prometheus.sh install_alertmanager.sh install_grafana.sh install_loki.sh install_statsd.sh install_nginx.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        echo "Starting installation of $script..."
        wait_for_apt_locks  # Wait for locks before each installation
        bash "$SCRIPT_DIR/$script"
        echo "Completed: $script"
        sleep 5  # Add a small delay between installations
    else
        echo "Error: Script $script not found in $SCRIPT_DIR"
        exit 1
    fi
done

# Reload Nginx to apply changes
sudo systemctl reload nginx

echo "Monitoring setup completed successfully!"
