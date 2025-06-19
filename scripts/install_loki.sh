#!/bin/bash
set -e

LOKI_VERSION="2.9.0"
wget https://github.com/grafana/loki/releases/download/v${LOKI_VERSION}/loki-linux-amd64.zip
unzip loki-linux-amd64.zip
cp loki-linux-amd64 /usr/local/bin/loki

# Create loki user
useradd --no-create-home --shell /bin/false loki || true

# Create necessary directories
mkdir -p /etc/loki
mkdir -p /var/lib/loki/chunks
mkdir -p /var/lib/loki/index

# Set proper permissions
chmod 755 /usr/local/bin/loki
chown -R loki:loki /etc/loki
chown -R loki:loki /var/lib/loki
chown loki:loki /usr/local/bin/loki

# Create systemd service with improved configuration
cat > /etc/systemd/system/loki.service << EOF
[Unit]
Description=Loki
Wants=network-online.target
After=network-online.target

[Service]
User=loki
Group=loki
Type=simple
ExecStart=/usr/local/bin/loki --config.file=/etc/loki/loki-config.yaml
Restart=always
WorkingDirectory=/var/lib/loki

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl enable loki
sudo systemctl start loki