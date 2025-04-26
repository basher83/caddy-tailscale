# Troubleshooting Tailscale Connectivity Issues

## Issue: caddy-proxy not showing up in Tailnet

If your caddy-proxy node is not appearing in your Tailnet, follow these steps to diagnose and fix the issue:

### 1. Check the Caddy Service Status

```bash
sudo systemctl status caddy
```

Make sure the service is running without errors. Look for any Tailscale-related error messages.

### 2. Verify Environment File

Ensure your environment file is correctly set up and being loaded:

```bash
# Check if the file exists
cat /etc/caddy/cloudflare.env

# Make sure it contains a valid TS_AUTHKEY
# The key should look something like: tskey-auth-xxxxxxxxxxxxxxxx
```

### 3. Check Caddy Logs for Tailscale Errors

```bash
sudo journalctl -u caddy -f
```

Look for any error messages related to Tailscale, such as:
- Authentication failures
- Network connectivity issues
- Permission problems

### 4. Verify Caddy Has Required Capabilities

Caddy needs the CAP_NET_ADMIN capability to create and manage the Tailscale network interface:

```bash
# Check if the service file has the correct capabilities
grep CAP_NET_ADMIN /usr/lib/systemd/system/caddy.service

# The output should include: AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
```

### 5. Test Tailscale Auth Key

Generate a new ephemeral auth key in the Tailscale admin console and update your environment file:

```bash
sudo nano /etc/caddy/cloudflare.env
# Update the TS_AUTHKEY value with the new key
```

Then restart Caddy:

```bash
sudo systemctl restart caddy
```

### 6. Check Firewall Settings

Ensure your firewall allows outbound connections to the Tailscale control server:

```bash
# For UFW
sudo ufw status

# For iptables
sudo iptables -L
```

Tailscale needs to be able to connect to the following domains:
- login.tailscale.com (TCP/443)
- controlplane.tailscale.com (TCP/443)

### 7. Manually Test Tailscale Connectivity

You can temporarily install the Tailscale client to test connectivity:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey=YOUR_AUTH_KEY
```

If this works but Caddy's built-in Tailscale doesn't, it suggests an issue with how Caddy is using the Tailscale library.

### 8. Check for Hostname Conflicts

Make sure you don't have another device on your Tailnet with the same hostname:

1. Go to the Tailscale admin console
2. Check if there's already a device named "caddy-proxy"
3. If there is, either remove it or use a different hostname in your Caddyfile

### 9. Rebuild Caddy with the Latest Tailscale Plugin

The issue might be resolved in a newer version of the plugin:

```bash
xcaddy build v2.9.1 \
    --with github.com/tailscale/caddy-tailscale@latest \
    --with github.com/caddy-dns/cloudflare
```

### 10. Check System Time

Tailscale authentication can fail if your system clock is significantly off:

```bash
date
```

If needed, synchronize your system time:

```bash
sudo timedatectl set-ntp true
```

### 11. Restart with Debug Logging

You can enable more verbose logging to help diagnose the issue:

```bash
sudo systemctl stop caddy
sudo TS_LOG=debug /usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
```

This will run Caddy in the foreground with debug logging enabled.

## After Making Changes

Remember to restart the Caddy service after making any changes:

```bash
sudo systemctl daemon-reload  # If you modified the service file
sudo systemctl restart caddy
```

Then check the logs again to see if the issue is resolved:

```bash
sudo journalctl -u caddy -f