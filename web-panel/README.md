# NOVA X Tunnel — Web Panel (Admin / Reseller)

Two-tier web panel (single Admin + Resellers) for managing SSH and ZiVPN
accounts, alongside the existing terminal panel (`menu.sh`). **Both panels
share the same files** (`/etc/novaxtunnel/users.db`, `/etc/zivpn/config.json`,
`/etc/zivpn/passwords_meta.json`) — nothing is duplicated or broken.

## What it does

- **Admin (single account)**: creates/edits/deletes resellers, and sets for
  each one: max users, total data quota (or unlimited), allowed protocols
  (SSH WS/UDP/TLS/SlowDNS, ZiVPN), and an expiry date. Sees every reseller's
  live stats — online users vs. max allowed, quota consumed vs. quota
  authorized, and how many of that reseller's client accounts are locked or
  expired — and can do anything a reseller can do.
- **Reseller**: creates/edits/deletes SSH or ZiVPN client accounts within
  the limits set by the admin. Sees their own online users vs. max allowed,
  quota consumed vs. quota authorized, and how many of their client accounts
  are currently locked or expired.
- **Cascading lock**: when a reseller expires, all of their client accounts
  are automatically locked (SSH: `usermod -L` + killed sessions; ZiVPN:
  password removed from active config). Extending the expiry date
  re-activates everything automatically (checked every 2 minutes).
- **Deleting a client** keeps its allocated quota counted in the reseller's
  total consumed quota.

## ⚠️ Known limitation: ZiVPN data quota

The ZiVPN binary (udp-zivpn) has no per-password traffic-counting API — all
users share the same UDP port. Its quota is therefore a **reserved
allocation** used for total-quota accounting, not a byte-accurate metered
cutoff. SSH accounts, by contrast, report real usage read from
`/etc/novaxtunnel/bandwidth/<user>.usage`.

## Requirements

- A VPS already running `menu.sh` / ZiVPN.
- Node.js 18+.
- Must run as **root** (like `menu.sh`), since it calls `useradd`, `usermod`,
  `chage`, `chpasswd`, `userdel`.

## Automated install (recommended)

⚠️ HAProxy already listens on ports **80/443** for SSH/TLS/SlowDNS/ZiVPN, so
the web panel installs on its **own dedicated port** (8443 by default) via
its own Nginx instance — no existing HAProxy config is touched.

```bash
cd /opt
git clone https://github.com/NOSTRA-DevOps/nova-xtunnel.git nova-x-tunnel
cd nova-x-tunnel/web-panel
sudo bash deploy/install.sh
```

The installer asks interactively for: domain, TLS mode (Nginx reverse proxy
vs. Node serving HTTPS directly), port(s), admin username/password (leave
blank to auto-generate), and session secret. Everything is also available as
flags for scripted installs:

```bash
sudo bash deploy/install.sh \
  --domain panel.yourdomain.com --tls-mode nginx --port 8443 --app-port 3000 \
  --admin-user admin --admin-pass 'S3cur3Pass!' --secret "$(openssl rand -hex 32)"

# or with Node handling its own certificate (no Nginx):
sudo bash deploy/install.sh --domain panel.yourdomain.com --tls-mode node --port 8443
```

The script then: installs Node.js 20 / Certbot / Nginx as needed, writes
`.env`, runs `npm install`, creates and starts the `novaxpanel` systemd
service, obtains a TLS certificate (with automatic Cloudflare-proxy
detection: DNS-01, temporary proxy bypass, or self-signed, your choice),
installs Certbot renewal hooks, and installs the `novaxpanel` maintenance
command.

**Access**: `https://panel.yourdomain.com:2045`

### Nginx vs. Node direct

| | Nginx reverse proxy | Node direct |
|---|---|---|
| Multiple sites/apps on one server | ✅ | ❌ port is dedicated to the panel |
| Simplicity | One extra, standard layer | Single process to manage |
| Switch later | `novaxpanel tls-mode` | `novaxpanel tls-mode` |

## Maintenance — `novaxpanel` command

Run `novaxpanel` (as root) for an interactive menu, or use each action directly:

```bash
novaxpanel status        # domain, ports, TLS mode, service state
novaxpanel logs           # live logs (journalctl -u novaxpanel -f)
novaxpanel restart
novaxpanel update          # git pull + npm install + restart
novaxpanel domain          # change domain (handles Cloudflare automatically)
novaxpanel port            # change public and/or internal port
novaxpanel tls-mode        # switch between Nginx reverse proxy and Node direct
novaxpanel admin-user       # rename an admin account
novaxpanel admin-pass       # change an admin account's password
novaxpanel secret           # regenerate SESSION_SECRET (logs everyone out)
novaxpanel backup           # back up .env + SQLite db to /root/novaxpanel-backups
novaxpanel restore          # restore a previous backup
novaxpanel uninstall        # clean uninstall (service, Nginx, cert, data)
```

`novaxpanel uninstall` never touches the terminal panel (`menu`) or your
SSH/ZiVPN accounts — only the web panel itself is removed, with confirmation
at each destructive step.

### Troubleshooting

```bash
systemctl status novaxpanel        # Node service state
journalctl -u novaxpanel -f        # live logs
systemctl status haproxy           # confirm HAProxy is still fine
nginx -t                           # validate Nginx config
```

## Manual install

```bash
cd /opt/nova-x-tunnel/web-panel
cp .env.example .env
nano .env   # set SESSION_SECRET and the initial admin password
npm install
node server.js
```
Then follow steps 4-7 of `deploy/install.sh` manually, or adapt the
`deploy/*.template` files to your setup.

## Project structure

```
nova-x-tunnel/web-panel/
  server.js              entry point
  config.js              paths shared with menu.sh
  db/database.js         SQLite schema (admins, resellers, clients)
  lib/system.js           real SSH provisioning (useradd/chpasswd/chage/usermod)
  lib/zivpn.js            ZiVPN provisioning (reads/writes the same files as menu.sh)
  lib/quota.js            business rules (quotas, limits, protocols, online/locked counts)
  lib/clients.js          shared admin/reseller client-management logic
  cron/enforcement.js     cascading lock logic (runs every 2 min)
  routes/                 auth.js, admin.js, reseller.js
  views/                  EJS pages (login, dashboards)
  public/css/style.css    panel styling
  deploy/install.sh          interactive installer (see above)
  deploy/lib-tls.sh          Cloudflare detection + certificate issuance
  deploy/novaxpanel-cli.sh   source of the maintenance command
  deploy/admin-tool.js       helper for changing admin credentials
  deploy/*.template          Nginx/systemd templates used by install.sh
  deploy/renewal-hooks/      Certbot hooks (stop/start HAProxy around renewal)
```

## Security

Already in place:
- Strong admin password auto-generated if none is provided.
- Random 32-byte `SESSION_SECRET`, regenerable via `novaxpanel secret`.
- Session cookies: `httpOnly`, `sameSite=lax`, `secure` (served behind Nginx/TLS).
- Security headers via `helmet`.
- Brute-force limiting on `/login` (10 attempts / 15 min / IP).
- Session regeneration on login (anti session-fixation).

Worth checking on your end:
- Serve over HTTPS only (default with the installer).
- Keep the panel behind your firewall — never expose the internal `PORT`
  (e.g. 3000) directly, only the public Nginx port.
- Run `novaxpanel backup` regularly (backs up `.env` + SQLite db).
