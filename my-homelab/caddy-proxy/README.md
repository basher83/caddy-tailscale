# Digital Ocean VPS with Caddy and Tailscale, cloudflare DNS

- Point VPS IP (206.81.7.245) to  gotify.securehaven.business via A record
- Make sure go is installed: https://go.dev/doc/install

# xCaddy https://github.com/caddyserver/xcaddy
Use xcaddy to rebuild the binary with the required plugins. For example, to include the Cloudflare and Tailscale DNS providers, you can run:
```bash
xcaddy build v2.9.1 \
    --with github.com/caddy-dns/cloudflare \
    --with github.com/tailscale/caddy-tailscale
```
# Make ephemeral auth key from Tailscale admin console
Save to /etc/caddy/cloudflare.env
```bash
TS_AUTHKEY=<tskey-auth-XXXXX>
CF_ZONE_TOKEN=<cf-zone-token-XXXXX>
CF_API_TOKEN=<cf-api-token-XXXXX>
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
EnvironmentFile=/etc/caddy/cloudflare.env

[Install]
WantedBy=multi-user.target
```

# Edit Caddyfile
I am also running Coder on the VPS server, which is accessible via coder.securehaven.business. The Caddyfile for the VPS server should look like this:

```bash
coder.securehaven.business, *.coder.securehaven.business {
        tls {
                dns cloudflare {
                        api_token {env.CF_API_TOKEN}
                        zone_token {env.CF_ZONE_TOKEN}
                }
        }
        reverse_proxy 127.0.0.1:3000
}

gotify.securehaven.business {
        tls {
                dns cloudflare {
                        api_token {env.CF_API_TOKEN}
                        zone_token {env.CF_ZONE_TOKEN}
                }
        }

        reverse_proxy caddy-home.tailfb3ea.ts.net {
                transport tailscale {
                        hostname caddy-home
                }
        }
}
```

