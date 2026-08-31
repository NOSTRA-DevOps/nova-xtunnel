#!/bin/bash
# NOVA XTUNNEL - bootstrap script
#
# Installation (première fois) OU mise à jour (fois suivantes) — même commande :
#
#   curl -fsSL https://raw.githubusercontent.com/NOSTRA-DevOps/nova-xtunnel/main/bootstrap.sh | sudo bash
#
set -e

REPO_URL="https://github.com/NOSTRA-DevOps/nova-xtunnel.git"
INSTALL_DIR="/opt/nova-x-tunnel"

if [[ $EUID -ne 0 ]]; then
  echo "Error: This script must be run as root (sudo)."
  exit 1
fi

echo "=================================================="
echo " NOVA XTUNNEL - bootstrap"
echo "=================================================="

# ---------- 1. Clone (première fois) ou pull (mise à jour) ----------
if ! command -v git >/dev/null 2>&1; then
  echo "📦 Installation de git..."
  apt-get update -y
  apt-get install -y git
fi

if [ -d "$INSTALL_DIR/.git" ]; then
  echo "🔄 Repository already present in $INSTALL_DIR — updating (git pull)..."
  git -C "$INSTALL_DIR" pull
  MODE="update"
else
  echo "📥 Cloning repository into $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
  MODE="install"
fi

cd "$INSTALL_DIR"

# ---------- 2. Panel terminal ----------
if [ -x /usr/local/bin/menu ]; then
  echo "🔄 Terminal panel already installed → minor update (menu.sh only)."
  bash terminal-panel/update.sh
else
  echo "📥 Terminal panel missing → complete installation."
  bash terminal-panel/install.sh
fi

# ---------- 3. Panel web (optionnel) ----------
if [ -r /dev/tty ]; then
  read -r -p "👉 Install/update the web panel too? (y/n): " DO_WEB < /dev/tty
else
  echo "⚠️  No interactive terminal detected (non-interactive execution) — web panel skipped."
  echo "    Rerun with 'bash web-panel/deploy/install.sh --domain <your-domain>' to install it."
  DO_WEB="n"
fi
if [[ "$DO_WEB" =~ ^[oOyY] ]]; then
  if systemctl list-unit-files 2>/dev/null | grep -q "^novaxpanel.service"; then
    echo "🔄 Web panel already installed → update (code + restart)."
    bash web-panel/update.sh
  else
    if [ -r /dev/tty ]; then
      read -r -p "👉 Domain name for the web panel (e.g., panel.yourdomain.com): " DOMAIN < /dev/tty
    else
      echo "⚠️  No interactive terminal detected — impossible to request the domain name."
      echo "    Rerun with 'bash web-panel/deploy/install.sh --domain <your-domain>' to install it."
      DOMAIN=""
    fi
    if [ -n "$DOMAIN" ]; then
      bash web-panel/deploy/install.sh --domain "$DOMAIN"
    fi
  fi
fi

bash terminal-panel/nostra.sh

echo "=================================================="
echo " ✅ Completed (mode: $MODE)."
echo "    Terminal panel : type 'menu'"
if [ -x /usr/local/bin/novaxpanel ]; then
  echo "    Web panel (maintenance) : type 'novaxpanel'"
fi
echo "    Local repository    : $INSTALL_DIR"
echo "=================================================="
