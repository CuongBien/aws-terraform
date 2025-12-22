#!/bin/bash
# ==================================================
# App Server Installation Script - PHP + Apache
# ==================================================

set -e

echo "========================================"
echo "Installing App Server Components"
echo "========================================"

# Install Apache and PHP
echo "==> Installing Apache and PHP 7.4"
sudo amazon-linux-extras enable php7.4
sudo yum install -y \
  httpd \
  php \
  php-cli \
  php-fpm \
  php-mysqlnd \
  php-pdo \
  php-json \
  php-mbstring \
  php-xml

# Install MySQL client for database connectivity
echo "==> Installing MySQL client"
sudo yum install -y mysql

# Install additional utilities
echo "==> Installing utilities"
sudo yum install -y \
  git \
  curl \
  wget \
  unzip \
  vim

# Configure Apache
echo "==> Configuring Apache"
cat <<'EOF' | sudo tee /etc/httpd/conf.d/api.conf
<VirtualHost *:8080>
    DocumentRoot /var/www/api
    
    <Directory /var/www/api>
        AllowOverride All
        Require all granted
        
        # Enable PHP
        <FilesMatch \.php$>
            SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost"
        </FilesMatch>
    </Directory>
    
    # Health check endpoint
    <Location /health>
        SetHandler None
        Require all granted
    </Location>
    
    # Version endpoint
    <Location /version>
        SetHandler None
        Require all granted
    </Location>
    
    ErrorLog /var/log/httpd/api_error.log
    CustomLog /var/log/httpd/api_access.log combined
</VirtualHost>

# Listen on port 8080
Listen 8080
EOF

# Configure PHP-FPM
echo "==> Configuring PHP-FPM"
sudo sed -i 's/listen = 127.0.0.1:9000/listen = \/run\/php-fpm\/www.sock/' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.owner = nobody/listen.owner = apache/' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.group = nobody/listen.group = apache/' /etc/php-fpm.d/www.conf
sudo sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /etc/php-fpm.d/www.conf

# Create health check endpoint
echo "==> Creating health check endpoint"
sudo mkdir -p /var/www/api
cat <<'EOF' | sudo tee /var/www/api/health.php
<?php
header('Content-Type: text/plain');
echo "healthy\n";
?>
EOF

# Test configuration
echo "==> Testing Apache configuration"
sudo apachectl configtest

echo "==> App server installation complete"
