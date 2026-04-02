#!/bin/bash
##############################################################
# user_data.sh.tpl — EC2 Bootstrap Script (Templatefile)
# Rendered by Terraform with: server_port, hello_world_version,
# and environment variables substituted at plan time.
##############################################################

set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

echo "=== Starting user-data bootstrap ==="
echo "Environment : ${environment}"
echo "Server Port : ${server_port}"
echo "Version     : ${hello_world_version}"

# Install Python (Amazon Linux 2023 ships with Python 3)
dnf update -y --quiet
dnf install -y python3 --quiet

# Create the web server script
cat > /usr/local/bin/webserver.py << 'PYEOF'
#!/usr/bin/env python3
"""Minimal HTTP server for Day 17 webserver cluster."""
import http.server
import socketserver
import os

PORT = int(os.environ.get("SERVER_PORT", "8080"))
VERSION = os.environ.get("HELLO_WORLD_VERSION", "v2")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "unknown")

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"OK")
            return

        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.end_headers()
        msg = f"Hello World {VERSION} | env={ENVIRONMENT} | host={self.headers.get('Host','?')}\n"
        self.wfile.write(msg.encode())

    def log_message(self, format, *args):
        pass  # suppress per-request logs to keep /var/log/user-data.log clean

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving on port {PORT}", flush=True)
    httpd.serve_forever()
PYEOF

chmod +x /usr/local/bin/webserver.py

# Create systemd service unit
cat > /etc/systemd/system/webserver.service << SVCEOF
[Unit]
Description=Hello World Web Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /usr/local/bin/webserver.py
Restart=always
RestartSec=5
Environment=SERVER_PORT=${server_port}
Environment=HELLO_WORLD_VERSION=${hello_world_version}
Environment=ENVIRONMENT=${environment}

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable webserver
systemctl start webserver

echo "=== Bootstrap complete — webserver running on port ${server_port} ==="
