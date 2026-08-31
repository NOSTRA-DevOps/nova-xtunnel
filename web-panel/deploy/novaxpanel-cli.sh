#!/bin/bash
# NOVA XTUNNEL - Web Panel maintenance CLI ("novaxpanel").
# Installed to /usr/local/bin/novaxpanel by deploy/install.sh.
# Run `novaxpanel` for the interactive menu, or `novaxpanel <command>` directly.

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Error: This script must be run as root."
  exit 1
fi

PROJECT_DIR="__PROJECT_DIR__"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: $ENV_FILE not found. Has the panel been installed with deploy/install.sh ?"
  exit 1
fi

# shellcheck source=./lib-tls.sh
source "$PROJECT_DIR/deploy/lib-tls.sh"

env_get() { grep "^$1=" "$ENV_FILE" | head -n1 | cut -d= -f2-; }
env_set() {
  local key="$1" value="$2"
  if grep -q "^$key=" "$ENV_FILE"; then
    sed -i "s|^$key=.*|$key=$value|" "$ENV_FILE"
  else
    echo "$key=$value" >> "$ENV_FILE"
  fi
}

restart_panel() { systemctl restart novaxpanel && echo "✅ Service novaxpanel redémarré."; }

# ================= Commands =================

cmd_status() {
  local tls_mode; tls_mode=$(env_get TLS_MODE)
  echo "=================================================="
  echo " NOVA XTUNNEL — Status of the web panel"
  echo "=================================================="
  echo " Domain         : $(env_get DOMAIN)"
  echo " TLS Mode       : $([[ "$tls_mode" == "node" ]] && echo "Direct Node (no Nginx)" || echo "Nginx reverse proxy")"
  echo " PPublic Port    : $(env_get PUBLIC_PORT)"
  [[ "$tls_mode" != "node" ]] && echo " Internal Port  : $(env_get PORT)"
  echo " URL            : https://$(env_get DOMAIN):$(env_get PUBLIC_PORT)"
  echo
  systemctl is-active --quiet novaxpanel && echo " Service Node   : ✅ actif" || echo " Service Node   : ❌ stopped"
  if [[ "$tls_mode" != "node" ]]; then
    systemctl is-active --quiet nginx && echo " Nginx          : ✅ actif" || echo " Nginx          : ❌ stopped"
  fi
  echo "=================================================="

cmd_logs() {
  echo "Ctrl+C pour quitter les logs en direct."
  journalctl -u novaxpanel -f --no-pager -n 100
}

cmd_restart() { restart_panel; }

cmd_update() {
  cd "$PROJECT_DIR"
  if [[ -d .git ]]; then
    echo "📥 git pull..."
    git pull
  else
    echo "⚠️  This directory is not a git repository — replace the files manually"
    echo "   (or re-clone the repository) then run 'novaxpanel update' again."
  fi
  echo "📦 npm install..."
  cd web-panel 2>/dev/null || cd "$PROJECT_DIR"
  npm install --omit=dev
  restart_panel
}

cmd_change_domain() {
  local old_domain new_domain tls_mode
  old_domain=$(env_get DOMAIN)
  tls_mode=$(env_get TLS_MODE)
  echo "Current domain : $old_domain"
  read -r -p "👉 New domain name: " new_domain
  [[ -z "$new_domain" ]] && { echo "Cancelled."; return; }

  obtain_certificate_interactive "$new_domain" || { echo "❌ Failed, domain not changed."; return 1; }

  if [[ "$tls_mode" == "node" ]]; then
    env_set CERT_PATH "/etc/letsencrypt/live/$new_domain/fullchain.pem"
    env_set KEY_PATH "/etc/letsencrypt/live/$new_domain/privkey.pem"
  else
    local public_port app_port
    public_port=$(env_get PUBLIC_PORT); app_port=$(env_get PORT)
    sed -e "s|__DOMAIN__|$new_domain|g" \
        -e "s|__PUBLIC_PORT__|$public_port|g" \
        -e "s|__APP_PORT__|$app_port|g" \
        "$PROJECT_DIR/deploy/nginx-novaxpanel.conf.template" > /etc/nginx/sites-available/novaxpanel
    nginx -t && systemctl reload nginx
  fi

  env_set DOMAIN "$new_domain"
  restart_panel
  echo "✅ Domain changed : $old_domain -> $new_domain"
  echo "   New URL: https://$new_domain:$(env_get PUBLIC_PORT)"
}

cmd_change_port() {
  local tls_mode; tls_mode=$(env_get TLS_MODE)

  if [[ "$tls_mode" == "node" ]]; then
    local current new
    current=$(env_get PUBLIC_PORT)
    echo "Current public port (Direct Node) : $current"
    read -r -p "👉 New public port: " new
    new="${new:-$current}"
    if ! [[ "$new" =~ ^[0-9]+$ ]] || (( new < 1 || new > 65535 )); then
      echo "❌ Invalid port: $new"; return 1
    fi
    env_set PUBLIC_PORT "$new"
    env_set PORT "$new"
    restart_panel
    echo "✅ Port updated. New URL: https://$(env_get DOMAIN):$new"
    return
  fi

  local current_public current_app new_public new_app
  current_public=$(env_get PUBLIC_PORT); current_app=$(env_get PORT)
  echo "Current public port  : $current_public"
  echo "Current internal port : $current_app"
  read -r -p "👉 New public port (empty = unchanged): " new_public
  read -r -p "👉 New internal port (empty = unchanged): " new_app
  new_public="${new_public:-$current_public}"
  new_app="${new_app:-$current_app}"

  for p in "$new_public" "$new_app"; do
    if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
      echo "❌ Invalid port: $p"; return 1
    fi
  done
  if [[ "$new_public" == "$new_app" ]]; then
    echo "❌ The public port and the internal port must be different."; return 1
  fi

  local domain; domain=$(env_get DOMAIN)
  sed -e "s|__DOMAIN__|$domain|g" \
      -e "s|__PUBLIC_PORT__|$new_public|g" \
      -e "s|__APP_PORT__|$new_app|g" \
      "$PROJECT_DIR/deploy/nginx-novaxpanel.conf.template" > /etc/nginx/sites-available/novaxpanel
  nginx -t && systemctl reload nginx

  env_set PUBLIC_PORT "$new_public"
  env_set PORT "$new_app"
  restart_panel
  echo "✅ Ports updated. New URL: https://$domain:$new_public"
}

cmd_change_admin_username() {
  echo "Existing admin accounts :"
  node "$PROJECT_DIR/deploy/admin-tool.js" list
  read -r -p "👉 Username to rename: " old_user
  read -r -p "👉 New username: " new_user
  [[ -z "$old_user" || -z "$new_user" ]] && { echo "Cancelled."; return; }
  node "$PROJECT_DIR/deploy/admin-tool.js" set-username "$old_user" "$new_user"
}

cmd_change_admin_password() {
  echo "Existing admin accounts :"
  node "$PROJECT_DIR/deploy/admin-tool.js" list
  read -r -p "👉 Username of the account to change the password for: " user
  [[ -z "$user" ]] && { echo "Cancelled."; return; }
  read -r -s -p "👉 New password (empty = automatically generated): " pass; echo
  if [[ -z "$pass" ]]; then
    pass=$(openssl rand -base64 14 | tr -d '=+/')
    echo "🔑 New password generated: $pass"
  fi
  node "$PROJECT_DIR/deploy/admin-tool.js" set-password "$user" "$pass"
}

cmd_regen_secret() {
  echo "⚠️  Regenerating the session secret will invalidate all existing sessions, logging out all users."
  read -r -p "Continue ? (y/N) " c
  [[ "$c" =~ ^[yY] ]] || { echo "Cancelled."; return; }
  local secret; secret=$(openssl rand -hex 32)
  env_set SESSION_SECRET "$secret"
  restart_panel
  echo "✅ New session secret generated and applied."
}

cmd_backup() {
  local dir="/root/novaxpanel-backups"
  mkdir -p "$dir"
  local file="$dir/novaxpanel-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$file" -C "$PROJECT_DIR" .env db/panel.sqlite3 2>/dev/null || \
  tar -czf "$file" -C "$PROJECT_DIR" .env
  echo "✅ Backup created: $file"
}

cmd_restore() {
  local dir="/root/novaxpanel-backups"
  if [[ ! -d "$dir" ]] || [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
    echo "No backup found in $dir."; return 1
  fi
  echo "Available backups:"
  select f in "$dir"/*.tar.gz "Cancel"; do
    [[ "$f" == "Cancel" || -z "$f" ]] && return
    echo "⚠️  This will overwrite the current config (.env) and database."
    read -r -p "Continue ? (y/N) " c
    [[ "$c" =~ ^[yY] ]] || return
    tar -xzf "$f" -C "$PROJECT_DIR"
    restart_panel
    echo "✅ Restoration completed from $f"
    return
  done
}

cmd_tls_mode() {
  local current; current=$(env_get TLS_MODE)
  local domain; domain=$(env_get DOMAIN)
  local public_port; public_port=$(env_get PUBLIC_PORT)
  echo "Current TLS mode : $([[ "$current" == "node" ]] && echo "Node direct" || echo "Nginx reverse proxy")"
  echo "  1) Nginx reverse proxy"
  echo "  2) Node direct — certificat Let's Encrypt (auto, manage Cloudflare DNS-01)"
  echo "  3) Node direct — custom certificate  (ex: Cloudflare Origin Certificate)"
  read -r -p "Choice [1/2/3]: " choice

  if [[ "$choice" == "2" && "$current" != "node" ]]; then
    obtain_certificate_interactive "$domain" || { echo "❌ Échec, mode inchangé."; return 1; }
    if [[ -f /etc/nginx/sites-enabled/novaxpanel ]]; then
      rm -f /etc/nginx/sites-enabled/novaxpanel /etc/nginx/sites-available/novaxpanel
      systemctl reload nginx 2>/dev/null || true
    fi
    env_set TLS_MODE node
    env_set BEHIND_TLS_PROXY false
    env_set CERT_PATH "/etc/letsencrypt/live/$domain/fullchain.pem"
    env_set KEY_PATH "/etc/letsencrypt/live/$domain/privkey.pem"
    env_set PORT "$public_port"
    restart_panel
    echo "✅ The panel now manages the certificate directly (no more Nginx)."

  elif [[ "$choice" == "3" ]]; then
    echo "☁️  Custom certificate (e.g., Cloudflare Origin Certificate)."
    echo "   Generate it in the Cloudflare dashboard: SSL/TLS > Origin Certificates > Create a Certificate,"
    echo "   then remember to set the Cloudflare SSL/TLS mode for the domain to 'Full (strict)'."
    read -r -p "👉 Path to the certificate (fullchain/cert .pem): " custom_cert
    read -r -p "👉 Path to the private key (.pem/.key): " custom_key
    if [[ ! -f "$custom_cert" || ! -f "$custom_key" ]]; then
      echo "❌ File not found. Please copy the certificate and key to this server first, then try again."
      return 1
    fi
    if [[ -f /etc/nginx/sites-enabled/novaxpanel ]]; then
      rm -f /etc/nginx/sites-enabled/novaxpanel /etc/nginx/sites-available/novaxpanel
      systemctl reload nginx 2>/dev/null || true
    fi
    env_set TLS_MODE node
    env_set BEHIND_TLS_PROXY false
    env_set CERT_PATH "$custom_cert"
    env_set KEY_PATH "$custom_key"
    env_set PORT "$public_port"
    restart_panel
    echo "✅ The panel now uses your custom certificate (no more Nginx)."

  elif [[ "$choice" == "1" && "$current" != "nginx" ]]; then
    if ! command -v nginx >/dev/null 2>&1; then
      echo "📦 Installation of Nginx..."
      apt-get update -y && apt-get install -y nginx
    fi
    read -r -p "👉 Port interne pour l'application Node [3000]: " app_port
    app_port="${app_port:-3000}"
    sed -e "s|__DOMAIN__|$domain|g" \
        -e "s|__PUBLIC_PORT__|$public_port|g" \
        -e "s|__APP_PORT__|$app_port|g" \
        "$PROJECT_DIR/deploy/nginx-novaxpanel.conf.template" > /etc/nginx/sites-available/novaxpanel
    ln -sf /etc/nginx/sites-available/novaxpanel /etc/nginx/sites-enabled/novaxpanel
    nginx -t && systemctl reload nginx
    env_set TLS_MODE nginx
    env_set BEHIND_TLS_PROXY true
    env_set PORT "$app_port"
    restart_panel
    echo "✅ Nginx now manages the TLS in reverse proxy mode."
  else
    echo "No changes made."
  fi
}

cmd_uninstall() {
  echo "=================================================="
  echo " ⚠️  Uninstalling the NOVA XTUNNEL web panel"
  echo "=================================================="
  echo " This will: stop/disable the service, remove the Nginx config and the"
  echo " associated TLS certificate, and remove the 'novaxpanel' command."
  echo " (The terminal 'menu' panel and your SSH/ZiVPN accounts will NOT be affected.)"
  read -r -p "Confirm the uninstallation? (type 'oui'): " c
  [[ "$c" == "oui" ]] || { echo "Cancelled."; return; }

  local domain; domain=$(env_get DOMAIN)
  local tls_mode; tls_mode=$(env_get TLS_MODE)

  systemctl stop novaxpanel 2>/dev/null || true
  systemctl disable novaxpanel 2>/dev/null || true
  rm -f /etc/systemd/system/novaxpanel.service
  systemctl daemon-reload

  if [[ "$tls_mode" != "node" ]]; then
    rm -f /etc/nginx/sites-enabled/novaxpanel /etc/nginx/sites-available/novaxpanel
    systemctl reload nginx 2>/dev/null || true
  fi

  rm -f /etc/letsencrypt/renewal-hooks/pre/novaxpanel-stop-haproxy.sh
  rm -f /etc/letsencrypt/renewal-hooks/post/novaxpanel-start-haproxy.sh
  rm -f /etc/letsencrypt/renewal-hooks/post/novaxpanel-restart-panel.sh

  read -r -p "Delete the TLS certificate for $domain as well? (y/N) " c2
  if [[ "$c2" =~ ^[yY] ]]; then
    certbot delete --cert-name "$domain" --non-interactive 2>/dev/null || true
  fi

  read -r -p "Delete the data (SQLite database, .env, node_modules) as well? (y/N) " c3
  if [[ "$c3" =~ ^[yY] ]]; then
    rm -rf "$PROJECT_DIR/node_modules" "$PROJECT_DIR/.env" "$PROJECT_DIR/db/panel.sqlite3"
    echo "🗑️  Data deleted."
  else
    echo "ℹ️  Data preserved in $PROJECT_DIR (useful for a reinstallation)."
  fi

  echo "✅ Panel web uninstalled."
  rm -f /usr/local/bin/novaxpanel
  echo "   (Command 'novaxpanel' removed.)"
}

show_menu() {
  cat <<'EOF'

==================================================
   NOVA XTUNNEL — Maintenance panel (web panel)
==================================================
  1) Status
  2) View live logs
  3) Restart the service
  4) Update
  5) Change domain name
  6) Change ports (public / internal)
  7) Switch Nginx <-> Node direct (TLS mode)
  8) Change admin username
  9) Change admin password
 10) Regenerate session secret
 11) Backup
 12) Restore backup
 13) Uninstall web panel
  0) Quit
==================================================
EOF
  read -r -p "Choice: " choice
  case "$choice" in
    1) cmd_status ;;
    2) cmd_logs ;;
    3) cmd_restart ;;
    4) cmd_update ;;
    5) cmd_change_domain ;;
    6) cmd_change_port ;;
    7) cmd_tls_mode ;;
    8) cmd_change_admin_username ;;
    9) cmd_change_admin_password ;;
    10) cmd_regen_secret ;;
    11) cmd_backup ;;
    12) cmd_restore ;;
    13) cmd_uninstall; exit 0 ;;
    0) exit 0 ;;
    *) echo "Invalid choice." ;;
  esac
}

# ================= Entry point =================

case "$1" in
  status) cmd_status ;;
  logs) cmd_logs ;;
  restart) cmd_restart ;;
  update) cmd_update ;;
  domain) cmd_change_domain ;;
  port) cmd_change_port ;;
  tls-mode) cmd_tls_mode ;;
  admin-user) cmd_change_admin_username ;;
  admin-pass) cmd_change_admin_password ;;
  secret) cmd_regen_secret ;;
  backup) cmd_backup ;;
  restore) cmd_restore ;;
  uninstall) cmd_uninstall ;;
  "")
    while true; do show_menu; read -r -p "Press Enter to continue..." _; done
    ;;
  *)
    echo "Unknown command: $1"
    echo "Usage: novaxpanel [status|logs|restart|update|domain|port|tls-mode|admin-user|admin-pass|secret|backup|restore|uninstall]"
    exit 1
    ;;
esac
