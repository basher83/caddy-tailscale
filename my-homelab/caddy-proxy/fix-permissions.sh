#!/bin/bash

# This script fixes permissions for the Tailscale auth key file

echo "=== Checking current permissions ==="
sudo ls -lah /etc/caddy/cloudflare.env

echo -e "\n=== Fixing permissions ==="
# Change ownership to caddy:caddy (instead of root:caddy)
sudo chown caddy:caddy /etc/caddy/cloudflare.env

# Set permissions to 600 (only owner can read/write)
sudo chmod 600 /etc/caddy/cloudflare.env

echo -e "\n=== Verifying new permissions ==="
sudo ls -lah /etc/caddy/cloudflare.env

echo -e "\n=== Restarting Caddy ==="
sudo systemctl restart caddy

echo -e "\n=== Checking Caddy logs ==="
echo "Waiting 5 seconds for Caddy to start..."
sleep 5
sudo journalctl -u caddy -n 20

echo -e "\nTo continue monitoring logs, run: sudo journalctl -u caddy -f"
echo "To check if caddy-proxy appears in your Tailnet, check the Tailscale admin console."