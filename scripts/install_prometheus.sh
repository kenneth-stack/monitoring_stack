#!/bin/bash
set -e

PROMETHEUS_VERSION="2.47.0"
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
tar xvf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
cp prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/

# Create prometheus user
useradd --no-create-home --shell /bin/false prometheus

# Set ownership
chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Create systemd service
cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
    --config.file=/etc/prometheus/prometheus.yml \
    --storage.tsdb.path=/var/lib/prometheus
    
[Install]
WantedBy=multi-user.target
EOF

systemctl enable prometheus
systemctl start prometheus
