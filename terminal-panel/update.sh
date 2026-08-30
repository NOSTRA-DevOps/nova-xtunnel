#!/bin/bash
set -e

if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Mise à jour de NOVA X Tunnel (panel terminal)..."
cp "$SCRIPT_DIR/menu.sh" /usr/local/bin/menu
chmod +x /usr/local/bin/menu

if [ -d "$SCRIPT_DIR/falconproxy" ]; then
    mkdir -p /opt/novaxtunnel
    rm -rf /opt/novaxtunnel/falconproxy
    cp -r "$SCRIPT_DIR/falconproxy" /opt/novaxtunnel/falconproxy
    chmod +x /opt/novaxtunnel/falconproxy/falconproxy /opt/novaxtunnel/falconproxy/falconproxyarm 2>/dev/null || true
fi

echo "✅ Commande 'menu' mise à jour."
echo "(La configuration SSH existante n'est pas retouchée par une mise à jour."
echo " Pour la réappliquer, relancez install.sh à la place.)"
