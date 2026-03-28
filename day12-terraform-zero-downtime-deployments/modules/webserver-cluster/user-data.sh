#!/bin/bash
# Day 12 — Zero-Downtime Deployments
# This script runs on every new EC2 instance at launch.
# Terraform renders the variables before passing to cloud-init.

set -e

apt-get update -y
apt-get install -y nginx

# Write the response page — version is injected by Terraform templatefile()
cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Webserver ${app_version}</title>
  <style>
    body { font-family: Arial, sans-serif; text-align: center; padding: 60px; background: #f0f4f8; }
    .card { background: white; border-radius: 8px; padding: 40px; display: inline-block;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    .version { font-size: 48px; font-weight: bold; color: ${color}; }
    .label { font-size: 18px; color: #64748b; margin-top: 8px; }
  </style>
</head>
<body>
  <div class="card">
    <div class="version">${app_version}</div>
    <div class="label">${cluster_name} — ${environment}</div>
    <div class="label">Instance: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</div>
    <div class="label">AZ: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</div>
  </div>
</body>
</html>
EOF

systemctl enable nginx
systemctl start nginx
