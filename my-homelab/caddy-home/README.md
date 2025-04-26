Create LXC in Homelab for Caddy with Proxmox helper script:

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://caddyserver.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  debian-keyring \
  debian-archive-keyring \
  apt-transport-https \
  gpg
msg_ok "Installed Dependencies"

msg_info "Installing Caddy"
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' >/etc/apt/sources.list.d/caddy-stable.list
$STD apt-get update
$STD apt-get install -y caddy
msg_ok "Installed Caddy"

read -r -p "Would you like to install xCaddy Addon? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "Installing Golang"
  set +o pipefail
  temp_file=$(mktemp)
  golang_tarball=$(curl -fsSL https://go.dev/dl/ | grep -oP 'go[\d\.]+\.linux-amd64\.tar\.gz' | head -n 1)
  curl -fsSL "https://golang.org/dl/${golang_tarball}" -o "$temp_file"
  tar -C /usr/local -xzf "$temp_file"
  ln -sf /usr/local/go/bin/go /usr/local/bin/go
  rm -f "$temp_file"
  set -o pipefail
  msg_ok "Installed Golang"

  msg_info "Setup xCaddy"
  $STD apt-get install -y git
  cd /opt
  RELEASE=$(curl -fsSL https://api.github.com/repos/caddyserver/xcaddy/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  curl -fsSL "https://github.com/caddyserver/xcaddy/releases/download/${RELEASE}/xcaddy_${RELEASE:1}_linux_amd64.deb" -o $(basename "https://github.com/caddyserver/xcaddy/releases/download/${RELEASE}/xcaddy_${RELEASE:1}_linux_amd64.deb")
  $STD dpkg -i xcaddy_${RELEASE:1}_linux_amd64.deb
  rm -rf /opt/xcaddy*
  $STD xcaddy build
  msg_ok "Setup xCaddy"
fi

motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
```
# Edit LXC config
Add to the end of the config file `/etc/pve/lxc/<CTID>.conf`:
```bash
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
```
Restart the container.

Make sure go is installed: https://go.dev/doc/install

# xCaddy https://github.com/caddyserver/xcaddy
Use xcaddy to rebuild the binary with the required plugins. For example, to include the Cloudflare and Tailscale DNS providers, you can run:
```bash
xcaddy build v2.9.1 \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/tailscale/caddy-tailscale
```
# Make ephemeral auth key from Tailscale admin console
Save to /etc/caddy/tailscale.env
```bash
TS_AUTHKEY=<tskey-auth-XXXXX>
```

# Edit caddy.service /usr/lib/systemd/system/caddy.service
```bash
# caddy.service
#
# For using Caddy with a config file.
#
# Make sure the ExecStart and ExecReload commands are correct
# for your installation.
#
# See https://caddyserver.com/docs/install for instructions.
#
# WARNING: This service does not use the --resume flag, so if you
# use the API to make changes, they will be overwritten by the
# Caddyfile next time the service is restarted. If you intend to
# use Caddy's API to configure it, add the --resume flag to the
# `caddy run` command or use the caddy-api.service file instead.

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

# Edit Caddyfile
I am trying to proxy Gotify from within my homelab to another Caddy running in a VPS server. Gotify is running on http://192.168.30.212/#/login

```bash
gotify.securehaven.business {
        bind tailscale/caddy-home
        tls {
                get_certificate tailscale
        }
        reverse_proxy 192.168.30.212 {
                header_up X-Forwarded-Proto https
                header_up Host {host}
        }
}
```

