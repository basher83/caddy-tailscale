# Pihole on tailnet https://tailscale.com/kb/1114/pi-hole?q=pihole

Use tailscale script for install
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```
Launch tailscale
```bash
tailscale up --accept-dns=false
```

# Add pihole to nameserver in tailscale
- Add the tailscale IP of the pihole to admin console nameservers
- Enable override DNS servers
- Disable key expiration
- In the Pi-hole Admin page in Settings > DNS, make sure that Listen on all interfaces, permit all origins is selected.