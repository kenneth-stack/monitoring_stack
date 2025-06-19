#!/bin/bash
set -e

ALERTMANAGER_VERSION="0.26.0"
wget https://github.com/prometheus/alertmanager/releases/download/v${ALERTMANAGER_VERSION}/alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
tar xvf alertmanager-${ALERTMANAGER_VERSION}.linux-amd64.tar.gz
cp alertmanager-${ALERTMANAGER_VERSION}.linux-amd64/alertmanager /usr/local/bin/

# Create alertmanager user
useradd --no-create-home --shell /bin/false alertmanager

# Set ownership
chown -R alertmanager:alertmanager /etc/alertmanager
chmod 755 /usr/local/bin/alertmanager
chown -R alertmanager:alertmanager /var/lib/alertmanager
chown alertmanager:alertmanager /usr/local/bin/alertmanager

# Create systemd service
cat > /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=AlertManager
Wants=network-online.target
After=network-online.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
EnvironmentFile=/tmp/scripts/.env 
ExecStart=/usr/local/bin/alertmanager \
    --config.file=/etc/alertmanager/alertmanager.yml \
    --storage.path=/var/lib/alertmanager
Restart=always
RestartSec=5
WorkingDirectory=/var/lib/alertmanager


[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
