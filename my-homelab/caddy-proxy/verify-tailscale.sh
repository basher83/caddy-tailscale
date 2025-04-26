#!/bin/bash

# This script verifies that the Tailscale plugin is properly built into Caddy
# and tests the Tailscale connection

echo "=== Checking Caddy version and plugins ==="
caddy version

echo -e "\n=== Checking if Tailscale plugin is loaded ==="
caddy list-modules | grep tailscale

echo -e "\n=== Checking environment variables ==="
if [ -f /etc/caddy/cloudflare.env ]; then
  echo "Environment file exists: /etc/caddy/cloudflare.env"
  
  # Check if TS_AUTHKEY is set (without revealing the actual key)
  if grep -q "TS_AUTHKEY" /etc/caddy/cloudflare.env; then
    echo "TS_AUTHKEY is set in the environment file"
  else
    echo "ERROR: TS_AUTHKEY is not set in the environment file"
  fi
else
  echo "ERROR: Environment file not found: /etc/caddy/cloudflare.env"
fi

echo -e "\n=== Testing Tailscale connection with simple config ==="
echo "Stopping Caddy service..."
sudo systemctl stop caddy

echo "Running Caddy with test configuration and debug logging..."
sudo TS_LOG=debug caddy run --config /etc/caddy/test-tailscale.caddyfile

# Note: The script will stop here as Caddy will run in the foreground
# Press Ctrl+C to stop Caddy when done testing