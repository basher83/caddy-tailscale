# Tailscale and Caddy Homelab Setup Guide

This guide will help you properly configure your Tailscale and Caddy setup for your homelab.

## Overview of Your Setup

Your setup consists of three main components:

1. **caddy-home**: A Caddy server running in your homelab that proxies requests to your Gotify instance.
2. **caddy-proxy**: A Caddy server running on a VPS that receives requests from the internet and forwards them to your homelab via Tailscale.
3. **pihole-home**: A Pi-hole instance for DNS management within your Tailnet.

## Step 1: Create Tailscale Auth Keys

1. Go to the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys)
2. Create two ephemeral auth keys:
   - One for caddy-home
   - One for caddy-proxy

## Step 2: Install and Configure Caddy with Tailscale Plugin

### For Both caddy-home and caddy-proxy

1. Install Go:
   ```bash
   # Download and install Go
   wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
   sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
   echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.profile
   source ~/.profile
   ```

2. Install xcaddy:
   ```bash
   go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest
   ```

3. Build Caddy with the Tailscale plugin:
   ```bash
   # For caddy-home
   xcaddy build v2.9.1 --with github.com/tailscale/caddy-tailscale

   # For caddy-proxy
   xcaddy build v2.9.1 --with github.com/tailscale/caddy-tailscale --with github.com/caddy-dns/cloudflare
   ```

4. Move the built binary to the system path:
   ```bash
   sudo mv caddy /usr/bin/
   ```

## Step 3: Configure Environment Files

### For caddy-home

Create `/etc/caddy/tailscale.env`:
```
TS_AUTHKEY=<your-caddy-home-auth-key>
```

### For caddy-proxy

Create `/etc/caddy/cloudflare.env`:
```
TS_AUTHKEY=<your-caddy-proxy-auth-key>
CF_API_TOKEN=<your-cloudflare-api-token>
CF_ZONE_TOKEN=<your-cloudflare-zone-token>
```

## Step 4: Configure Caddy Service Files

### For caddy-home

Edit `/usr/lib/systemd/system/caddy.service`:
```
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
EnvironmentFile=/etc/caddy/tailscale.env

[Install]
WantedBy=multi-user.target
```

### For caddy-proxy

Edit `/usr/lib/systemd/system/caddy.service` (same as above but with different EnvironmentFile):
```
EnvironmentFile=/etc/caddy/cloudflare.env
```

## Step 5: Start and Enable Caddy Services

```bash
sudo systemctl daemon-reload
sudo systemctl enable caddy
sudo systemctl restart caddy
```

## Step 6: Verify Tailscale Connectivity

Once both Caddy instances are running, they should automatically register as nodes in your Tailnet using the auth keys you provided.

1. Check if both nodes appear in your Tailscale admin console
2. Verify that the node names match what you've configured in your Caddyfiles

## Troubleshooting

### Check Caddy Logs

```bash
sudo journalctl -u caddy -f
```

### Common Issues and Solutions

1. **Tailscale nodes can't see each other**:
   - Verify both nodes are connected to the same Tailnet
   - Check firewall settings
   - Ensure both auth keys are valid and not expired

2. **Caddy can't bind to Tailscale interface**:
   - Ensure Caddy has the necessary capabilities (CAP_NET_ADMIN)
   - Verify the Tailscale node name in the Caddyfile matches the actual node name

3. **TLS certificate issues**:
   - For caddy-home, ensure you're using `get_certificate tailscale`
   - For caddy-proxy, ensure your Cloudflare API tokens have the correct permissions

4. **Reverse proxy not working**:
   - Verify the internal service (Gotify) is running and accessible
   - Check that the transport configuration is correct
   - Ensure the hostname in the transport configuration matches the Tailscale node name

## Important Notes

1. The `bind tailscale/caddy-home` directive in your caddy-home Caddyfile tells Caddy to listen on the Tailscale interface with the node name "caddy-home".

2. The `transport tailscale { hostname caddy-home }` directive in your caddy-proxy Caddyfile tells Caddy to use Tailscale to connect to the "caddy-home" node.

3. Make sure the node names match exactly between your Tailscale setup and your Caddyfile configurations.

4. The global `tailscale { ephemeral }` block in both Caddyfiles ensures that the nodes are registered as ephemeral, which means they will be automatically removed from your Tailnet when they go offline.

5. **Note about Tailscale installation**: The caddy-tailscale plugin creates its own Tailscale node directly within Caddy, so you don't need to install Tailscale separately on the host system. The plugin handles all the Tailscale functionality internally.

## For Pi-hole Integration

For your Pi-hole instance, you would still need to install Tailscale directly on that system since Pi-hole doesn't have a Tailscale plugin:

```bash
# Install Tailscale on Pi-hole
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale (don't accept DNS settings since Pi-hole is your DNS server)
tailscale up --accept-dns=false
```

Then follow the instructions in your pihole-home/README.md to configure it as a DNS server for your Tailnet.