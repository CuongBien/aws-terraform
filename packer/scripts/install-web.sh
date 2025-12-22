#!/bin/bash
# ==================================================
# Web Server Installation Script - Nginx + Frontend
# ==================================================

set -e

echo "========================================"
echo "Installing Web Server Components"
echo "========================================"

# Install Nginx
echo "==> Installing Nginx"
sudo amazon-linux-extras enable nginx1
sudo yum install -y nginx

# Install additional tools
echo "==> Installing utilities"
sudo yum install -y \
  git \
  curl \
  wget \
  unzip \
  vim \
  htop

# Install Docker
echo "==> Installing Docker"
sudo yum install -y docker
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# Install AWS CLI v2 for ECR access
echo "==> Installing AWS CLI v2"
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Configure Nginx
echo "==> Configuring Nginx"
cat <<'EOF' | sudo tee /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript 
               application/x-javascript application/xml+rss 
               application/json application/javascript;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /var/www/html;

        # Health check endpoint
        location /health {
            access_log off;
            return 200 "healthy\n";
            add_header Content-Type text/plain;
        }

        # Version endpoint
        location /version {
            default_type text/plain;
            alias /var/www/html/version.txt;
        }

        # Static files
        location / {
            index index.html index.htm;
            try_files $uri $uri/ =404;
        }

        # Proxy to backend API
        location /api/ {
            proxy_pass http://localhost:8080/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        error_page 404 /404.html;
        location = /404.html {
        }

        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
        }
    }
}
EOF

# Create log directory
sudo mkdir -p /var/log/nginx
sudo chown -R nginx:nginx /var/log/nginx

# Test configuration
echo "==> Testing Nginx configuration"
sudo nginx -t

echo "==> Web server installation complete"
