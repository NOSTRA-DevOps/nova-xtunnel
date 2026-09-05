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


echo "✅ Command menu updated. You can now run 'menu' from any terminal to access the NOVA X Tunnel panel."

