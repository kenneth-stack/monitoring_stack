#!/bin/bash
set -e

STATSD_VERSION="0.24.0"

# Download and install statsd_exporter
wget https://github.com/prometheus/statsd_exporter/releases/download/v${STATSD_VERSION}/statsd_exporter-${STATSD_VERSION}.linux-amd64.tar.gz
tar xvf statsd_exporter-${STATSD_VERSION}.linux-amd64.tar.gz
cp statsd_exporter-${STATSD_VERSION}.linux-amd64/statsd_exporter /usr/local/bin/

# Create statsd user
useradd --no-create-home --shell /bin/false statsd

# Set proper permissions
chown -R statsd:statsd /etc/statsd

# Create systemd service
cat > /etc/systemd/system/statsd-exporter.service << EOF
[Unit]
Description=StatsD Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=statsd
ExecStart=/usr/local/bin/statsd_exporter \
    --statsd.mapping-config=/etc/statsd/mapping.yml \
    --statsd.listen-udp=":9125" \
    --statsd.listen-tcp=":9125" \
    --web.listen-address=":9102"

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable statsd-exporter
systemctl start statsd-exporter