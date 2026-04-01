#!/bin/bash
set -euo pipefail

# Install dependencies (Amazon Linux 2023 uses dnf)
dnf update -y
dnf install -y httpd

# Configure the web server
cat > /var/www/html/index.html <<EOF
<html>
  <body>
    <h1>Hello from ${cluster_name}!</h1>
    <p>Environment: ${environment}</p>
    <p>Instance: $(curl -s --max-time 2 http://169.254.169.254/latest/meta-data/instance-id || echo "unknown")</p>
  </body>
</html>
EOF

# Health check endpoint
mkdir -p /var/www/html
echo "OK" > /var/www/html/health

# Configure port if not 80
if [ "${server_port}" != "80" ]; then
  sed -i "s/Listen 80/Listen ${server_port}/" /etc/httpd/conf/httpd.conf
fi

# Start and enable apache
systemctl enable httpd
systemctl start httpd
