#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Mise à jour de NOVA X Tunnel (panel web)..."
npm install --omit=dev

if systemctl list-unit-files | grep -q "^novaxpanel.service"; then
    systemctl restart novaxpanel
    echo "✅ Service novaxpanel redémarré."
else
    echo "⚠️ The novaxpanel service does not exist yet — run deploy/install.sh first."
fi
