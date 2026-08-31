#!/bin/bash
# NOVA XTUNNEL - Web Panel maintenance CLI ("novaxpanel").
# Installed to /usr/local/bin/novaxpanel by deploy/install.sh.
# Run `novaxpanel` for the interactive menu, or `novaxpanel <command>` directly.

set -e

# Couleurs personnalisées
SEP='\033[38;5;135m'        # Couleur du séparateur (violet)
C_GREEN='\033[38;5;46m'     # Vert vif
C_RED='\033[38;5;196m'      # Rouge vif
C_BLUE='\033[38;5;26m'      # Bleu foncé
C_YELLOW='\033[38;5;226m'   # Jaune
C_CYAN='\033[38;5;51m'      # Cyan
C_WHITE='\033[38;5;255m'    # Blanc
C_PURPLE='\033[38;5;135m'   # Violet
NC='\033[0m'                # No Color
BOLD='\033[1m'

# Separator functions
sep() { echo -e "${SEP}══════════════════════════════════════════════════════════════════════${NC}"; }
sep_double() { echo -e "${SEP}══════════════════════════════════════════════════════════════════════${NC}"; }
sep_short() { echo -e "${SEP}──────────────────────────────────────────────────────────────────────${NC}"; }

# Print colored messages
print_error() { echo -e "${C_RED}❌ $1${NC}"; }
print_success() { echo -e "${C_GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${C_YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${C_BLUE}ℹ️  $1${NC}"; }
print_header() { echo -e "${BOLD}${C_BLUE}$1${NC}"; }

if [[ $EUID -ne 0 ]]; then
  print_error "This script must be run as root."
  exit 1
fi

PROJECT_DIR="/opt/nova-x-tunnel/web-panel"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  print_error "$ENV_FILE not found. Has the panel been installed with deploy/install.sh ?"
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

restart_panel() { systemctl restart novaxpanel && print_success "Service novaxpanel redémarré."; }

# ================= Commands =================

cmd_status() {
  sep_double
  print_header "                    NOVA XTUNNEL — Status of the web panel"
  sep_double
  local tls_mode; tls_mode=$(env_get TLS_MODE)
  echo -e "${C_WHITE} Domain         :${NC} $(env_get DOMAIN)"
  echo -e "${C_WHITE} TLS Mode       :${NC} $([[ "$tls_mode" == "node" ]] && echo "${C_GREEN}Direct Node (no Nginx)${NC}" || echo "${C_BLUE}Nginx reverse proxy${NC}")"
  echo -e "${C_WHITE} Public Port    :${NC} $(env_get PUBLIC_PORT)"
  [[ "$tls_mode" != "node" ]] && echo -e "${C_WHITE} Internal Port  :${NC} $(env_get PORT)"
  echo -e "${C_WHITE} URL            :${NC} ${C_GREEN}https://$(env_get DOMAIN):$(env_get PUBLIC_PORT)${NC}"
  echo
  local service_status=$(systemctl is-active novaxpanel)
  if [[ "$service_status" == "active" ]]; then
    echo -e " Service Node   : ${C_GREEN}✅ actif${NC}"
  else
    echo -e " Service Node   : ${C_RED}❌ stopped${NC}"
  fi
  if [[ "$tls_mode" != "node" ]]; then
    local nginx_status=$(systemctl is-active nginx)
    if [[ "$nginx_status" == "active" ]]; then
      echo -e " Nginx          : ${C_GREEN}✅ actif${NC}"
    else
      echo -e " Nginx          : ${C_RED}❌ stopped${NC}"
    fi
  fi
  sep_double
}

cmd_logs() {
  print_info "Ctrl+C pour quitter les logs en direct."
  sep_short
  journalctl -u novaxpanel -f --no-pager -n 100
}

cmd_restart() { restart_panel; }

cmd_update() {
  sep_double
  print_header "                    UPDATE WEB PANEL"
  sep_double
  cd "$PROJECT_DIR"
  if [[ -d .git ]]; then
    print_info "📥 git pull..."
    git pull
  else
    print_warning "This directory is not a git repository — replace the files manually"
    echo "   (or re-clone the repository) then run 'novaxpanel update' again."
  fi
  print_info "📦 npm install..."
  cd web-panel 2>/dev/null || cd "$PROJECT_DIR"
  npm install --omit=dev
  restart_panel
  sep_short
}

cmd_change_domain() {
  sep_double
  print_header "                    CHANGE DOMAIN"
  sep_double
  local old_domain new_domain tls_mode
  old_domain=$(env_get DOMAIN)
  tls_mode=$(env_get TLS_MODE)
  echo -e "${C_WHITE}Current domain :${NC} ${C_YELLOW}$old_domain${NC}"
  read -r -p "$(echo -e ${C_GREEN}👉 New domain name: ${NC})" new_domain
  [[ -z "$new_domain" ]] && { print_warning "Cancelled."; return; }

  obtain_certificate_interactive "$new_domain" || { print_error "Failed, domain not changed."; return 1; }

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
  print_success "Domain changed : ${C_YELLOW}$old_domain${NC} -> ${C_GREEN}$new_domain${NC}"
  echo -e "   ${C_WHITE}New URL:${NC} ${C_GREEN}https://$new_domain:$(env_get PUBLIC_PORT)${NC}"
  sep_short
}

cmd_change_port() {
  sep_double
  print_header "                    CHANGE PORTS"
  sep_double
  local tls_mode; tls_mode=$(env_get TLS_MODE)

  if [[ "$tls_mode" == "node" ]]; then
    local current new
    current=$(env_get PUBLIC_PORT)
    echo -e "${C_WHITE}Current public port (Direct Node) :${NC} ${C_YELLOW}$current${NC}"
    read -r -p "$(echo -e ${C_GREEN}👉 New public port: ${NC})" new
    new="${new:-$current}"
    if ! [[ "$new" =~ ^[0-9]+$ ]] || (( new < 1 || new > 65535 )); then
      print_error "Invalid port: $new"
      return 1
    fi
    env_set PUBLIC_PORT "$new"
    env_set PORT "$new"
    restart_panel
    print_success "Port updated. New URL: ${C_GREEN}https://$(env_get DOMAIN):$new${NC}"
    sep_short
    return
  fi

  local current_public current_app new_public new_app
  current_public=$(env_get PUBLIC_PORT); current_app=$(env_get PORT)
  echo -e "${C_WHITE}Current public port  :${NC} ${C_YELLOW}$current_public${NC}"
  echo -e "${C_WHITE}Current internal port :${NC} ${C_YELLOW}$current_app${NC}"
  read -r -p "$(echo -e ${C_GREEN}👉 New public port (empty = unchanged): ${NC})" new_public
  read -r -p "$(echo -e ${C_GREEN}👉 New internal port (empty = unchanged): ${NC})" new_app
  new_public="${new_public:-$current_public}"
  new_app="${new_app:-$current_app}"

  for p in "$new_public" "$new_app"; do
    if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
      print_error "Invalid port: $p"
      return 1
    fi
  done
  if [[ "$new_public" == "$new_app" ]]; then
    print_error "The public port and the internal port must be different."
    return 1
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
  print_success "Ports updated. New URL: ${C_GREEN}https://$domain:$new_public${NC}"
  sep_short
}

cmd_change_admin_username() {
  sep_double
  print_header "                    CHANGE ADMIN USERNAME"
  sep_double
  print_info "Existing admin accounts :"
  sep_short
  node "$PROJECT_DIR/deploy/admin-tool.js" list
  sep_short
  read -r -p "$(echo -e ${C_GREEN}👉 Username to rename: ${NC})" old_user
  read -r -p "$(echo -e ${C_GREEN}👉 New username: ${NC})" new_user
  [[ -z "$old_user" || -z "$new_user" ]] && { print_warning "Cancelled."; return; }
  node "$PROJECT_DIR/deploy/admin-tool.js" set-username "$old_user" "$new_user"
  sep_short
}

cmd_change_admin_password() {
  sep_double
  print_header "                    CHANGE ADMIN PASSWORD"
  sep_double
  print_info "Existing admin accounts :"
  sep_short
  node "$PROJECT_DIR/deploy/admin-tool.js" list
  sep_short
  read -r -p "$(echo -e ${C_GREEN}👉 Username: ${NC})" user
  [[ -z "$user" ]] && { print_warning "Cancelled."; return; }
  read -r -s -p "$(echo -e ${C_GREEN}👉 New password (empty = automatically generated): ${NC})" pass; echo
  if [[ -z "$pass" ]]; then
    pass=$(openssl rand -base64 14 | tr -d '=+/')
    echo -e "${C_YELLOW}🔑 New password generated: ${C_GREEN}$pass${NC}"
  fi
  node "$PROJECT_DIR/deploy/admin-tool.js" set-password "$user" "$pass"
  sep_short
}

cmd_regen_secret() {
  sep_double
  print_header "                    REGENERATE SESSION SECRET"
  sep_double
  print_warning "Regenerating the session secret will invalidate all existing sessions, logging out all users."
  read -r -p "$(echo -e ${C_YELLOW}Continue ? (y/N) ${NC})" c
  [[ "$c" =~ ^[yY] ]] || { print_warning "Cancelled."; return; }
  local secret; secret=$(openssl rand -hex 32)
  env_set SESSION_SECRET "$secret"
  restart_panel
  print_success "New session secret generated and applied."
  sep_short
}

cmd_backup() {
  sep_double
  print_header "                    BACKUP"
  sep_double
  local dir="/root/novaxpanel-backups"
  mkdir -p "$dir"
  local file="$dir/novaxpanel-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$file" -C "$PROJECT_DIR" .env db/panel.sqlite3 2>/dev/null || \
  tar -czf "$file" -C "$PROJECT_DIR" .env
  print_success "Backup created: ${C_GREEN}$file${NC}"
  sep_short
}

cmd_restore() {
  sep_double
  print_header "                    RESTORE BACKUP"
  sep_double
  local dir="/root/novaxpanel-backups"
  if [[ ! -d "$dir" ]] || [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
    print_error "No backup found in $dir."
    sep_short
    return 1
  fi
  print_info "Available backups:"
  sep_short
  select f in "$dir"/*.tar.gz "Cancel"; do
    [[ "$f" == "Cancel" || -z "$f" ]] && { print_warning "Restore cancelled."; return; }
    print_warning "This will overwrite the current config (.env) and database."
    read -r -p "$(echo -e ${C_YELLOW}Continue ? (y/N) ${NC})" c
    [[ "$c" =~ ^[yY] ]] || { print_warning "Restore cancelled."; return; }
    tar -xzf "$f" -C "$PROJECT_DIR"
    restart_panel
    print_success "Restoration completed from ${C_GREEN}$f${NC}"
    sep_short
    return
  done
}

cmd_tls_mode() {
  sep_double
  print_header "                    TLS MODE SWITCH"
  sep_double
  local current; current=$(env_get TLS_MODE)
  local domain; domain=$(env_get DOMAIN)
  local public_port; public_port=$(env_get PUBLIC_PORT)
  echo -e "${C_WHITE}Current TLS mode :${NC} $([[ "$current" == "node" ]] && echo "${C_GREEN}Node direct${NC}" || echo "${C_BLUE}Nginx reverse proxy${NC}")"
  sep_short
  echo -e "  ${BOLD}${C_RED}1)${NC} ${C_BLUE}Nginx reverse proxy${NC}"
  echo -e "  ${BOLD}${C_RED}2)${NC} ${C_GREEN}Node direct — Let's Encrypt${NC} (auto, manage Cloudflare DNS-01)"
  echo -e "  ${BOLD}${C_RED}3)${NC} ${C_YELLOW}Node direct — custom certificate${NC} (ex: Cloudflare Origin Certificate)"
  sep_short
  read -r -p "$(echo -e ${C_GREEN}Choice [1/2/3]: ${NC})" choice

  if [[ "$choice" == "2" && "$current" != "node" ]]; then
    obtain_certificate_interactive "$domain" || { print_error "Échec, mode inchangé."; return 1; }
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
    print_success "The panel now manages the certificate directly (no more Nginx)."

  elif [[ "$choice" == "3" ]]; then
    print_info "Custom certificate (e.g., Cloudflare Origin Certificate)."
    echo "   Generate it in the Cloudflare dashboard: SSL/TLS > Origin Certificates > Create a Certificate,"
    echo "   then remember to set the Cloudflare SSL/TLS mode for the domain to 'Full (strict)'."
    sep_short
    read -r -p "$(echo -e ${C_GREEN}👉 Path to the certificate (fullchain/cert .pem): ${NC})" custom_cert
    read -r -p "$(echo -e ${C_GREEN}👉 Path to the private key (.pem/.key): ${NC})" custom_key
    if [[ ! -f "$custom_cert" || ! -f "$custom_key" ]]; then
      print_error "File not found. Please copy the certificate and key to this server first, then try again."
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
    print_success "The panel now uses your custom certificate (no more Nginx)."

  elif [[ "$choice" == "1" && "$current" != "nginx" ]]; then
    if ! command -v nginx >/dev/null 2>&1; then
      print_info "Installing Nginx..."
      apt-get update -y && apt-get install -y nginx
    fi
    read -r -p "$(echo -e ${C_GREEN}👉 Internal port for Node application [3000]: ${NC})" app_port
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
    print_success "Nginx now manages the TLS in reverse proxy mode."
  else
    print_info "No changes made."
  fi
  sep_short
}

cmd_uninstall() {
  sep_double
  print_header "                    UNINSTALL WEB PANEL"
  sep_double
  print_warning "This will: stop/disable the service, remove the Nginx config and the"
  echo "   associated TLS certificate, and remove the 'novaxpanel' command."
  echo -e "   ${C_GREEN}The terminal 'menu' panel and your SSH/ZiVPN accounts will NOT be affected.${NC}"
  sep_short
  read -r -p "$(echo -e ${C_RED}Confirm the uninstallation? (type 'oui'): ${NC})" c
  [[ "$c" == "oui" ]] || { print_warning "Cancelled."; return; }

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

  read -r -p "$(echo -e ${C_YELLOW}Delete the TLS certificate for $domain as well? (y/N) ${NC})" c2
  if [[ "$c2" =~ ^[yY] ]]; then
    certbot delete --cert-name "$domain" --non-interactive 2>/dev/null || true
  fi

  read -r -p "$(echo -e ${C_YELLOW}Delete the data (SQLite database, .env, node_modules) as well? (y/N) ${NC})" c3
  if [[ "$c3" =~ ^[yY] ]]; then
    rm -rf "$PROJECT_DIR/node_modules" "$PROJECT_DIR/.env" "$PROJECT_DIR/db/panel.sqlite3"
    print_info "🗑️  Data deleted."
  else
    print_info "Data preserved in ${C_WHITE}$PROJECT_DIR${NC} (useful for a reinstallation)."
  fi

  print_success "Panel web uninstalled."
  rm -f /usr/local/bin/novaxpanel
  echo -e "   ${C_WHITE}(Command 'novaxpanel' removed.)${NC}"
  sep_short
}

show_menu() {
  clear
  sep_double
  print_header "           NOVA XTUNNEL — Maintenance Panel (Web Panel)"
  sep_double
  echo -e "  ${BOLD}${C_RED}1)${NC} ${C_WHITE}Status${NC}"
  echo -e "  ${BOLD}${C_RED}2)${NC} ${C_WHITE}View live logs${NC}"
  echo -e "  ${BOLD}${C_RED}3)${NC} ${C_WHITE}Restart the service${NC}"
  echo -e "  ${BOLD}${C_RED}4)${NC} ${C_WHITE}Update${NC}"
  echo -e "  ${BOLD}${C_RED}5)${NC} ${C_WHITE}Change domain name${NC}"
  echo -e "  ${BOLD}${C_RED}6)${NC} ${C_WHITE}Change ports (public / internal)${NC}"
  echo -e "  ${BOLD}${C_RED}7)${NC} ${C_WHITE}Switch Nginx <-> Node direct (TLS mode)${NC}"
  echo -e "  ${BOLD}${C_RED}8)${NC} ${C_WHITE}Change admin username${NC}"
  echo -e "  ${BOLD}${C_RED}9)${NC} ${C_WHITE}Change admin password${NC}"
  echo -e " ${BOLD}${C_RED}10)${NC} ${C_WHITE}Regenerate session secret${NC}"
  echo -e " ${BOLD}${C_RED}11)${NC} ${C_WHITE}Backup${NC}"
  echo -e " ${BOLD}${C_RED}12)${NC} ${C_WHITE}Restore backup${NC}"
  echo -e " ${BOLD}${C_RED}13)${NC} ${C_RED}Uninstall web panel${NC}"
  echo -e "  ${BOLD}${C_RED}0)${NC} ${C_WHITE}Quit${NC}"
  sep_double
  read -r -p "$(echo -e ${C_GREEN}Choice: ${NC})" choice
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
    *) print_error "Invalid choice." ;;
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
    while true; do show_menu; read -r -p "$(echo -e ${C_BLUE}Press Enter to continue...${NC})" _; done
    ;;
  *)
    print_error "Unknown command: $1"
    sep_short
    echo -e "${C_WHITE}Usage:${NC} novaxpanel [status|logs|restart|update|domain|port|tls-mode|admin-user|admin-pass|secret|backup|restore|uninstall]"
    sep_short
    exit 1
    ;;
esac