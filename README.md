<!-- NOVA X Tunnel Banner -->
<p align="center">
  <img src="https://img.shields.io/badge/version-2.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-All%20Rights%20Reserved-red.svg" alt="License">
  <img src="https://img.shields.io/badge/bash-5.0+-4EAA25.svg" alt="Bash">
  <img src="https://img.shields.io/badge/node.js-16.x+-339933.svg" alt="Node.js">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome">
  <img src="https://img.shields.io/badge/Powered%20by-NOSTRA-ff69b4.svg" alt="Powered by NOSTRA">
</p>

<h1 align="center">🚀 NOVA X Tunnel</h1>

<p align="center">
  <strong>Enterprise-grade VPN tunnel management suite with dual-panel architecture</strong>
</p>

# 📋 Overview

NOVA X Tunnel is a comprehensive VPN management solution featuring both a terminal panel for direct VPS administration and a web panel for remote multi-client management. The architecture ensures zero redundancy—both panels operate on the same system files without conflicts.
Supported Protocols

    SSH WebSocket/UDP/TLS

    SlowDNS

    ZiVPN

    HAProxy load balancing

🏗️ Main Architecture
```text

nova-x-tunnel/
├── terminal-panel/                 # Bash interactive SSH menu
│   ├── install.sh                  # Complete VPS installation
│   ├── menu.sh                     # Main panel interface (`menu` command)
│   ├── sshd                    # SSH daemon configuration
│   └── falconproxy/            # falcon proxy            
│
└── web-panel/                      # Node.js Admin/Reseller interface
    ├── deploy/
    │   └── install.sh              # Automated deployment with Certbot
    ├── server.js                   # Main application entry
    ├── routes/                     # API endpoints
    ├── views/                      # EJS templates
    ├── lib/                        # Core business logic
    ├── db/                         # Database schemas & migrations
    └── README.md                   # Web panel documentation
```
**🚀 Quick Installation**
One-Command Install
```bash
curl -fsSL https://raw.githubusercontent.com/NOSTRA-DevOps/nova-xtunnel/main/bootstrap.sh | sudo bash
```
    Important: Update REPO_URL in bootstrap.sh with your actual repository URL before pushing to GitHub.

The bootstrap script intelligently detects installed components:

    First run: Clones repository to /opt/nova-x-tunnel and installs terminal panel (web panel optional)

    Subsequent runs: Performs git pull and updates installed panels only

Component-Specific Updates
```bash
cd /opt/nova-x-tunnel
```
# Update terminal panel only
bash terminal-panel/update.sh

# Update web panel only
bash web-panel/update.sh

🔧 Manual Installation
Terminal Panel
```bash

git clone https://github.com/NOSTRA-DevOps/nova-xtunnel.git nova-x-tunnel
cd nova-x-tunnel/terminal-panel
sudo bash install.sh
```
What's installed:

    menu command for SSH/ZiVPN/SlowDNS/HAProxy management

    Optimized SSH daemon configuration

    Service monitoring and auto-restart mechanisms

Web Panel
```bash
cd ../web-panel
sudo bash deploy/install.sh
```
**Installation features:**

    Interactive domain, port, and credentials setup

    Automatic Cloudflare proxy detection

    Adaptive TLS certificate issuance (Let's Encrypt)

    Non-interactive mode with CLI flags support

    ⚠️ Port Configuration: Nginx runs on a dedicated port (default: 8443) to avoid conflicts with HAProxy on ports 80/443.

Access URL: https://panel.yourdomain.com:port
Web Panel Management

After installation, the novaxpanel command provides comprehensive management capabilities:
```bash

novaxpanel status           # Show service status
novaxpanel logs             # View application logs
novaxpanel update           # Update to latest version
novaxpanel domain <domain>  # Change domain
novaxpanel port <port>      # Change web port
novaxpanel credentials      # Update admin credentials
novaxpanel backup           # Create system backup
novaxpanel restore <file>   # Restore from backup
novaxpanel uninstall        # Complete removal
```
🔄 Data Synchronization

The two panels maintain consistency through shared data files:
```text
Data Type	Shared File Location
SSH Accounts	/etc/novaxtunnel/users.db
SSH Bandwidth Usage	/etc/novaxtunnel/bandwidth/<user>.usage
ZiVPN Credentials & Quotas	/etc/zivpn/config.json
/etc/zivpn/passwords_meta.json
```
Key Benefit: Accounts created in either panel are immediately available in the other.
📦 Updating After Git Push
```bash

cd /opt/nova-x-tunnel
git pull

# Update terminal panel
cp terminal-panel/menu.sh /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# Update web panel
cd web-panel
npm install                    # Only if package.json changed
systemctl restart novaxpanel
```
**🛡️ Security Features**

    ✅ TLS encryption via Let's Encrypt

    ✅ Automatic certificate renewal

    ✅ Cloudflare proxy compatibility

    ✅ Secure session management

    ✅ Role-based access control (Admin/Reseller)

    ✅ Audit logging

    ✅ Rate limiting protection

**📊 Monitoring & Logging**

    Real-time service health checks

    User bandwidth tracking

    Connection monitoring

    System resource usage

    Comprehensive audit trails


# 🌍 Community & Support

| Plateforme | Description / Nom du Salon | Badge de Lien |
| :--- | :--- | :--- |
| 💬 **WhatsApp** | Official WhatsApp Channel | [![WhatsApp](https://shields.io)](https://whatsapp.com/channel/0029Vb6yLAG9WtC0zbXeEo2t) |
| 📱 **WhatsApp** | WhatsApp Channel 2 | [![WhatsApp](https://shields.io)](https://whatsapp.com/channel/0029Vb8ZJnsAYlUHo1uA6W0y) |
| 🟢 **WhatsApp** | Community Group | [![WhatsApp](https://shields.io)](https://chat.whatsapp.com/LUkXjJNfWrT8Fz7akxosH0
) |
| ✈️ **Telegram** | Telegram Channel & Support(Addlist) | [![Telegram](https://shields.io)](https://t.me/addlist/CpQzYQfWwwxmYTk0) |
| 📺 **Facebook** | FACEBOOK Channel | [![Facebook](https://shields.io)](https://www.facebook.com/profile.php?id=61591828051151) |
| 🎮 **Discord** | Discord Server | [![Discord](https://shields.io)](https://discord.gg/xGAGs69UHj) |
| 🎥 **YouTube** | YouTube Channel | [![YouTube](https://shields.io)](https://www.youtube.com/@LaboKingFreeSurf) |



---

## 📧 Contact

**Author:** NOSTRA
**Email:** contact.nostra237@gmail.com

---

# ⭐ Support the Project

If you find this project useful, consider giving it a ⭐ on GitHub.
It helps the project grow and motivates future development.

<a href='https://ko-fi.com/X6N522CQQ2' target='_blank'><img height='36' style='border:0px;height:36px;' src='https://storage.ko-fi.com/cdn/kofi2.png?v=6' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>

> 💡 **Looking for DevOps solutions? ?** Reach out to us now!

---

# 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](./LICENSE) file for details.

Copyright (c) 2026 **NOVA X Tunnel**

---

<p align="center">

<i>Powerd by<i> <b>NOSTRA<i> (Nova X-Code)</i></b>

</p>
