#!/bin/bash
# modules/compute/asg-rolling-deploy/user-data.sh
# Bootstrap script — installs and starts the web server on each EC2 instance

set -euo pipefail

apt-get update -y
apt-get install -y ruby

cat > /home/ubuntu/web-server.rb << 'RUBY'
require 'webrick'

port   = ${server_port}
env    = "${environment}"

server = WEBrick::HTTPServer.new(Port: port)

server.mount_proc '/' do |req, res|
  res.body = "Hello, World from #{env}! Server: #{`hostname`.strip}\n"
end

server.mount_proc '/health' do |req, res|
  res.status = 200
  res.body   = "OK\n"
end

trap('INT')  { server.shutdown }
trap('TERM') { server.shutdown }

server.start
RUBY

chown ubuntu:ubuntu /home/ubuntu/web-server.rb

# Create systemd service so the server survives reboots
cat > /etc/systemd/system/web-server.service << 'SERVICE'
[Unit]
Description=Ruby Web Server
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/bin/ruby /home/ubuntu/web-server.rb
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable web-server
systemctl start web-server
