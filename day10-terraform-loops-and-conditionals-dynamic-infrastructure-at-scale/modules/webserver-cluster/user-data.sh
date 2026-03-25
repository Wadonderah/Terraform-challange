#!/bin/bash
set -euo pipefail

# Install and start Apache

yum install -y httpd
systemctl enable httpd
systemctl start httpd

# Write a simple index page

cat <<HTML > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head><title>${cluster_name}</title></head>
<body>
  <h1>${cluster_name}</h1>
  <p>Environment: <strong>${environment}</strong></p>
  <p>Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</p>
  <p>AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
</body>
</html>
HTML
