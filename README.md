#### Create Cloudflare based firewall rule for Hetzner with [hcloud](https://github.com/hetznercloud/cli)

```bash
Usage:
	update_cdn.sh [ --server SERVER  --action TYPE ] | --json TYPE

Action:
	--delete [ ssh | cloudflare ]
	--create [ ssh | cloudflare ]

Example:
	update_cdn.sh --server rocky-2gb-hel1-1 --create cloudflare
	update_cdn.sh --json cloudflare
```
