#!/bin/bash

# This script checks and fixes the Tailscale auth key configuration

echo "=== Checking environment files ==="

# Check if the cloudflare.env file exists
if [ -f /etc/caddy/cloudflare.env ]; then
    echo "Found /etc/caddy/cloudflare.env"
    
    # Check if TS_AUTHKEY is set in the file
    if grep -q "TS_AUTHKEY" /etc/caddy/cloudflare.env; then
        echo "TS_AUTHKEY is present in the file"
        
        # Check the format of the key
        KEY_FORMAT=$(grep "TS_AUTHKEY" /etc/caddy/cloudflare.env)
        if [[ "$KEY_FORMAT" == TS_AUTHKEY=tskey-* ]]; then
            echo "Key format looks correct"
        else
            echo "WARNING: Key format might be incorrect. It should start with 'tskey-'"
            echo "Current format: $KEY_FORMAT"
        fi
    else
        echo "ERROR: TS_AUTHKEY is not set in /etc/caddy/cloudflare.env"
    fi
else
    echo "ERROR: /etc/caddy/cloudflare.env file not found"
fi

echo -e "\n=== Creating a new environment file ==="
echo "Please enter a new Tailscale auth key (starts with tskey-auth-...):"
read -p "> " NEW_KEY

if [[ -z "$NEW_KEY" ]]; then
    echo "No key entered. Exiting."
    exit 1
fi

# Create a backup of the existing file
if [ -f /etc/caddy/cloudflare.env ]; then
    sudo cp /etc/caddy/cloudflare.env /etc/caddy/cloudflare.env.backup
    echo "Created backup of existing file at /etc/caddy/cloudflare.env.backup"
fi

# Create a new environment file with the correct format
echo "Creating new environment file..."
cat << EOF | sudo tee /etc/caddy/cloudflare.env
TS_AUTHKEY=$NEW_KEY
EOF

if [ -f /etc/caddy/cloudflare.env ]; then
    # Set proper permissions
    sudo chmod 600 /etc/caddy/cloudflare.env
    sudo chown caddy:caddy /etc/caddy/cloudflare.env
    echo "Created new environment file with correct permissions"
    
    # Restart Caddy
    echo -e "\n=== Restarting Caddy ==="
    sudo systemctl restart caddy
    echo "Caddy restarted"
    
    echo -e "\n=== Checking Caddy logs ==="
    echo "Waiting 5 seconds for Caddy to start..."
    sleep 5
    sudo journalctl -u caddy -n 20
    
    echo -e "\nTo continue monitoring logs, run: sudo journalctl -u caddy -f"
else
    echo "ERROR: Failed to create environment file"
fi