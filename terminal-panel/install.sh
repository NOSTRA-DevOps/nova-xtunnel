#!/bin/bash
set -e

# Must be root
if [[ $EUID -ne 0 ]]; then
   echo "Error: This script must be run as root."
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing NOVA X Tunnel Manager..."

# Install menu (copied from this repo, no external download needed)
cp "$SCRIPT_DIR/menu.sh" /usr/local/bin/menu
chmod +x /usr/local/bin/menu


if [ -d "$SCRIPT_DIR/falconproxy" ]; then
    mkdir -p /opt/novaxtunnel
    rm -rf /opt/novaxtunnel/falconproxy
    cp -r "$SCRIPT_DIR/falconproxy" /opt/novaxtunnel/falconproxy
    chmod +x /opt/novaxtunnel/falconproxy/falconproxy /opt/novaxtunnel/falconproxy/falconproxyarm 2>/dev/null || true
fi

echo "Applying NOVA X Tunnel SSH configuration..."

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.backup.$(date +%F-%H%M%S)"

# Backup current SSH config
cp "$SSHD_CONFIG" "$BACKUP"

# Install NOVA X Tunnel SSH config (copied from this repo)
cp "$SCRIPT_DIR/ssh" "$SSHD_CONFIG"
chmod 600 "$SSHD_CONFIG"

# Validate SSH config (silent)
if ! sshd -t 2>/dev/null; then
    echo "ERROR: SSH configuration is invalid!"
    echo "Restoring previous configuration..."
    cp "$BACKUP" "$SSHD_CONFIG"
    exit 1
fi

echo "SSH configuration validated."

# Restart SSH quietly and safely
restart_ssh() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl restart sshd 2>/dev/null \
        || systemctl restart ssh 2>/dev/null \
        || return 1
    elif command -v service >/dev/null 2>&1; then
        service sshd restart 2>/dev/null \
        || service ssh restart 2>/dev/null \
        || return 1
    elif command -v rc-service >/dev/null 2>&1; then
        rc-service sshd restart 2>/dev/null \
        || rc-service ssh restart 2>/dev/null \
        || return 1
    elif [ -x /etc/init.d/sshd ]; then
        /etc/init.d/sshd restart >/dev/null 2>&1
    elif [ -x /etc/init.d/ssh ]; then
        /etc/init.d/ssh restart >/dev/null 2>&1
    else
        return 1
    fi
}

if restart_ssh; then
    echo "SSH service restarted."
else
    echo "WARNING: SSH restart not supported on this system."
    echo "SSH config applied but service was not restarted automatically."
fi

# Run NOVA X Tunnel setup
bash /usr/local/bin/menu --install-setup

echo "Installation complete!"
echo "Type 'menu' to start."
