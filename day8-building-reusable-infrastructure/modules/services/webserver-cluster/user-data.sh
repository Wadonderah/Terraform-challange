#!/bin/bash

set -euo pipefail

# Install and start Apache HTTP server

yum update -y
yum install -y httpd

# Fetch IMDSv2 token first (required since launch template enforces http_tokens=required)

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

AZ=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/availability-zone)

# Write a response page that identifies the cluster and instance

cat > /var/www/html/index.html <<EOF
<html>
<head><title>${cluster_name}</title></head>
<body>
  <h1>Hello, Welcome Wadonderah!</h1>
  <p><strong>Instance ID:</strong> $INSTANCE_ID</p>
  <p><strong>Availability Zone:</strong> $AZ</p>
</body>
</html>
EOF

# Reconfigure Apache to listen on the specified port

sed -i "s/Listen 80/Listen ${server_port}/" /etc/httpd/conf/httpd.conf

systemctl enable httpd
systemctl start httpd
