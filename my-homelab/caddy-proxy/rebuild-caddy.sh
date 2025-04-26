#!/bin/bash

# This script rebuilds Caddy with the Tailscale plugin and installs it

echo "=== Installing dependencies ==="
sudo apt-get update
sudo apt-get install -y golang git

echo -e "\n=== Building Caddy with Tailscale plugin ==="
# Create a temporary directory for building
BUILD_DIR=$(mktemp -d)
cd $BUILD_DIR

# Install xcaddy if not already installed
if ! command -v xcaddy &> /dev/null; then
    echo "Installing xcaddy..."
    go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
    export PATH=$PATH:$(go env GOPATH)/bin
fi

echo "Building Caddy with Tailscale plugin..."
xcaddy build v2.9.1 \
    --with github.com/tailscale/caddy-tailscale@latest \
    --with github.com/caddy-dns/cloudflare@latest

echo -e "\n=== Installing the new Caddy binary ==="
# Stop Caddy service
sudo systemctl stop caddy

# Backup the existing Caddy binary
if [ -f /usr/bin/caddy ]; then
    sudo mv /usr/bin/caddy /usr/bin/caddy.backup
    echo "Backed up existing Caddy binary to /usr/bin/caddy.backup"
fi

# Install the new binary
sudo cp caddy /usr/bin/
sudo chmod +x /usr/bin/caddy
echo "Installed new Caddy binary to /usr/bin/caddy"

# Verify the installation
echo -e "\n=== Verifying the installation ==="
caddy version
echo "Checking for Tailscale plugin:"
caddy list-modules | grep tailscale

echo -e "\n=== Updating test configuration ==="
# Copy the test configuration to the correct location
sudo cp /etc/caddy/test-tailscale.caddyfile /etc/caddy/Caddyfile
echo "Copied test configuration to /etc/caddy/Caddyfile"

echo -e "\n=== Starting Caddy service ==="
sudo systemctl start caddy
echo "Caddy service started"

echo -e "\n=== Checking Caddy service status ==="
sudo systemctl status caddy

echo -e "\n=== Viewing Caddy logs ==="
echo "To view Caddy logs, run: sudo journalctl -u caddy -f"

# Clean up
cd -
rm -rf $BUILD_DIR