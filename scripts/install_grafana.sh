#!/bin/bash
set -e

# Add Grafana GPG key and repository
apt-get install -y apt-transport-https software-properties-common
wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

# Install Grafana
apt-get update
apt-get install -y grafana

# Create grafana.ini with admin credentials
cat > /etc/grafana/grafana.ini << EOF
[paths]
data = /var/lib/grafana
logs = /var/log/grafana
plugins = /var/lib/grafana/plugins

[server]
protocol = https
domain = grafana.delightdev.ng
root_url = https://grafana.delightdev.ng

[security]
admin_user = ${MONITORING_USERNAME}
admin_password = ${MONITORING_PASSWORD}

[auth]
disable_login_form = false

[users]
allow_sign_up = false
auto_assign_org_role = Editor

[auth.basic]
enabled = true
EOF

# Set proper permissions
chown -R grafana:grafana /etc/grafana
chmod 640 /etc/grafana/grafana.ini

# Enable and start Grafana
sudo systemctl enable grafana
sudo systemctl restart grafana

echo "Grafana installation and configuration completed"