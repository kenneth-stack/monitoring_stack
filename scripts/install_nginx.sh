#!/bin/bash
set -e

# Install Nginx and Certbot with required plugins
sudo apt-get update
sudo apt-get install -y nginx certbot python3-certbot-nginx python3-certbot-dns-digitalocean

# Set up DigitalOcean DNS credentials
source /tmp/scripts/.env

sudo mkdir -p /root/.secrets/
echo "dns_digitalocean_token = ${DO_API_TOKEN}" > /root/.secrets/certbot-dns-digitalocean.ini
sudo chmod 600 /root/.secrets/certbot-dns-digitalocean.ini

# Create required directories
sudo mkdir -p /etc/letsencrypt
sudo mkdir -p /var/www/html

# Create SSL options file
cat << EOF > /etc/letsencrypt/options-ssl-nginx.conf
ssl_session_cache shared:le_nginx_SSL:1m;
ssl_session_timeout 1440m;
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;
ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
EOF

# Create DH parameters
openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048

# Remove default configuration and enable our config
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/nginx.conf /etc/nginx/sites-enabled/

# Start nginx with HTTP-only config
nginx -t
systemctl start nginx

# Get SSL certificate for base domain and all subdomains
certbot certonly \
    --dns-digitalocean \
    --dns-digitalocean-credentials /root/.secrets/certbot-dns-digitalocean.ini \
    -d delightdev.ng \
    -d *.delightdev.ng \
    --non-interactive \
    --agree-tos \
    --email xxxxx@gmail.com

# Reload nginx to apply SSL configuration
nginx -t
systemctl reload nginx