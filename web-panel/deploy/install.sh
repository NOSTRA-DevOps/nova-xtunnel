#!/bin/bash
# NOVA XTUNNEL - Web Panel deployment script
#
# Fully interactive: asks for the domain, the TLS mode, admin username/password,
# ports and a session secret key. Every value can also be passed as a flag for
# non-interactive/CI use:
#
#   sudo bash deploy/install.sh \
#     --domain panel.tondomaine.com --tls-mode nginx --port 2045 --app-port 3000 \
#     --admin-user admin --admin-pass 'S3cur3Pass!' --secret "$(openssl rand -hex 32)"
#
set -e

if [[ $EUID -ne 0 ]]; then
  echo "Erreur : ce script doit être exécuté en root (sudo)."
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=./lib-tls.sh
source "$PROJECT_DIR/deploy/lib-tls.sh"

# When this script (or a parent, e.g. bootstrap.sh via `curl | sudo bash`) has its stdin
# occupied by a downloaded script instead of a real terminal, plain `read` gets EOF
# immediately and every prompt below would silently fall through empty. Route reads
# through /dev/tty when one is available so prompts still work in that case.
read_tty() {
  if [ -r /dev/tty ]; then
    read "$@" < /dev/tty
  else
    read "$@" < /dev/null
  fi
}

# ---------- Defaults ----------
PUBLIC_PORT=2045
APP_PORT=3000
DOMAIN=""
TLS_MODE=""     # "nginx" | "node"
ADMIN_USER=""
ADMIN_PASS=""
SECRET=""
ASSUME_YES=false

# ---------- Parse args (all optional -> falls back to interactive prompts) ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain) DOMAIN="$2"; shift 2 ;;
    --tls-mode) TLS_MODE="$2"; shift 2 ;;
    --port) PUBLIC_PORT="$2"; shift 2 ;;
    --app-port) APP_PORT="$2"; shift 2 ;;
    --admin-user) ADMIN_USER="$2"; shift 2 ;;
    --admin-pass) ADMIN_PASS="$2"; shift 2 ;;
    --secret) SECRET="$2"; shift 2 ;;
    --yes) ASSUME_YES=true; shift ;;
    *) echo "Argument inconnu: $1"; exit 1 ;;
  esac
done

echo "=================================================="
echo " NOVA XTUNNEL —  Web panel Installation"
echo "=================================================="
echo

# ---------- Interactive prompts for anything not given as a flag ----------

if [[ -z "$DOMAIN" ]]; then
  while true; do
    read_tty -r -p "👉 The novaxpanel service does not exist yet. Domain name for the panel (e.g., panel.yourdomain.com): " DOMAIN
    [[ "$DOMAIN" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)+$ ]] && break
    echo "   ⚠️ Invalid domain format; please try again."
  done
fi

if [[ -z "$TLS_MODE" ]]; then
  echo
  echo " How do you want to manage the TLS certificate of $DOMAIN ?"
  echo "   1) Nginx as a reverse proxy (recommended) — Nginx handles the certificate on a port"
  echo "      dedicated and forwards traffic to the Node application internally."
  echo "   2) The Node panel manages the domain certificate itself — no Nginx,"
  echo "      the application listens directly via HTTPS on the public port."
  read_tty -r -p " Choice [1/2] (default 1): " tls_choice
  case "${tls_choice:-1}" in
    2) TLS_MODE="node" ;;
    *) TLS_MODE="nginx" ;;
  esac
fi

read_tty -r -p "👉 Public port (HTTPS) [$PUBLIC_PORT]: " input
PUBLIC_PORT="${input:-$PUBLIC_PORT}"

if [[ "$TLS_MODE" == "nginx" ]]; then
  read_tty -r -p "👉 Internal port of the Node application [$APP_PORT]: " input
  APP_PORT="${input:-$APP_PORT}"
else
  APP_PORT="$PUBLIC_PORT" # node listens directly on the public port, no separate internal port
fi

for p in "$PUBLIC_PORT" "$APP_PORT"; do
  if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
    echo "❌ Invalid port: $p"; exit 1
  fi
done
if [[ "$TLS_MODE" == "nginx" && "$PUBLIC_PORT" == "$APP_PORT" ]]; then
  echo "❌ The public port and the internal port must be different."; exit 1
fi
if ss -ltn 2>/dev/null | grep -q ":$PUBLIC_PORT "; then
  echo "⚠️  The port $PUBLIC_PORT seems to be already in use on this server. Continue only if you know what you are doing."
  $ASSUME_YES || read_tty -r -p "   Continue anyway? (y/N) " c; [[ "$c" =~ ^[yY] ]] || exit 1
fi

if [[ -z "$ADMIN_USER" ]]; then
  read_tty -r -p "👉 Admin username [admin]: " ADMIN_USER
  ADMIN_USER="${ADMIN_USER:-admin}"
fi

if [[ -z "$ADMIN_PASS" ]]; then
  while true; do
    read_tty -r -s -p "👉 Admin password (leave blank to generate a strong one automatically): " ADMIN_PASS
    echo
    if [[ -z "$ADMIN_PASS" ]]; then
      ADMIN_PASS=$(openssl rand -base64 14 | tr -d '=+/')
      echo "   🔑 Password generated automatically (displayed in the final summary)."
      break
    fi
    if [[ ${#ADMIN_PASS} -lt 8 ]]; then
      echo "   ⚠️ At least 8 characters recommended, please try again."
      continue
    fi
    read_tty -r -s -p "👉 Confirm the password: " confirm
    echo
    [[ "$ADMIN_PASS" == "$confirm" ]] && break
    echo "   ⚠️ The passwords do not match, please try again."
  done
fi

if [[ -z "$SECRET" ]]; then
  read_tty -r -p "👉 Session secret (leave blank to generate one automatically): " SECRET
  [[ -z "$SECRET" ]] && SECRET=$(openssl rand -hex 32)
fi

# sed treats '&', '\' and our chosen delimiter '|' specially inside the REPLACEMENT text
# ('&' re-inserts the whole matched line, '\' escapes the next char). Any of these appearing
# in a user-typed value (very common in a "strong" password) would silently corrupt what
# actually gets written to .env - the admin password entered here would then NOT be the one
# that ends up working, with no error shown. Escape before ever interpolating into sed.
sed_escape_repl() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//&/\\&}"
  s="${s//|/\\|}"
  printf '%s' "$s"
}
ADMIN_USER_ESC="$(sed_escape_repl "$ADMIN_USER")"
ADMIN_PASS_ESC="$(sed_escape_repl "$ADMIN_PASS")"
SECRET_ESC="$(sed_escape_repl "$SECRET")"
DOMAIN_ESC="$(sed_escape_repl "$DOMAIN")"

echo
echo "=================================================="
echo " Project directory  : $PROJECT_DIR"
echo " Domain             : $DOMAIN"
echo " TLS mode           : $([[ "$TLS_MODE" == "node" ]] && echo "Direct Node (no Nginx)" || echo "Nginx reverse proxy")"
echo " PPublic port        : $PUBLIC_PORT"
[[ "$TLS_MODE" == "nginx" ]] && echo " Internal port (Node) : $APP_PORT"
echo " Admin user         : $ADMIN_USER"
echo "=================================================="
echo

# ---------- 1. Node.js ----------
if ! command -v node >/dev/null 2>&1; then
  echo "📦 Installation of Node.js 20..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  apt-get install -y nodejs
else
  echo "✅ Node.js already installed ($(node -v))"
fi

# ---------- 2. Certbot & dig (+ Nginx only if that mode was chosen) ----------
apt-get update -y
PKGS="dig:dnsutils certbot:certbot"
[[ "$TLS_MODE" == "nginx" ]] && PKGS="$PKGS nginx:nginx"
for pkg_bin_pair in $PKGS; do
  bin="${pkg_bin_pair%%:*}"; pkg="${pkg_bin_pair##*:}"
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "📦 Installation of $pkg..."
    apt-get install -y "$pkg"
  fi
done

# ---------- 3. .env ----------
cd "$PROJECT_DIR"
echo "📝 Writing the .env file..."
cp .env.example .env
sed -i "s|^SESSION_SECRET=.*|SESSION_SECRET=$SECRET_ESC|" .env
sed -i "s|^PORT=.*|PORT=$APP_PORT|" .env
sed -i "s|^DOMAIN=.*|DOMAIN=$DOMAIN_ESC|" .env
sed -i "s|^PUBLIC_PORT=.*|PUBLIC_PORT=$PUBLIC_PORT|" .env
sed -i "s|^DEFAULT_ADMIN_USER=.*|DEFAULT_ADMIN_USER=$ADMIN_USER_ESC|" .env
sed -i "s|^DEFAULT_ADMIN_PASS=.*|DEFAULT_ADMIN_PASS=$ADMIN_PASS_ESC|" .env

if [[ "$TLS_MODE" == "node" ]]; then
  sed -i "s|^BEHIND_TLS_PROXY=.*|BEHIND_TLS_PROXY=false|" .env
  {
    echo "TLS_MODE=node"
    echo "CERT_PATH=/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    echo "KEY_PATH=/etc/letsencrypt/live/$DOMAIN/privkey.pem"
  } >> .env
else
  sed -i "s|^BEHIND_TLS_PROXY=.*|BEHIND_TLS_PROXY=true|" .env
  echo "TLS_MODE=nginx" >> .env
fi

# ---------- 4. npm install ----------
echo "📦 Installation of Node dependencies..."
npm install --omit=dev

# ---------- 5. TLS certificate (Cloudflare-aware) ----------
obtain_certificate_interactive "$DOMAIN" || {
  echo "❌ Unable to obtain a TLS certificate for $DOMAIN."

  echo "   Please resolve the DNS/Cloudflare issue and then use 'novaxpanel domain' to try again."
  exit 1
}

if [[ "$TLS_MODE" == "nginx" ]]; then
  # ---------- 6a. Nginx site on the dedicated port ----------
  echo "📝 Configuration Nginx (dedicated port $PUBLIC_PORT)..."
  sed -e "s|__DOMAIN__|$DOMAIN|g" \
      -e "s|__PUBLIC_PORT__|$PUBLIC_PORT|g" \
      -e "s|__APP_PORT__|$APP_PORT|g" \
      "$PROJECT_DIR/deploy/nginx-novaxpanel.conf.template" > /etc/nginx/sites-available/novaxpanel
  ln -sf /etc/nginx/sites-available/novaxpanel /etc/nginx/sites-enabled/novaxpanel
  nginx -t
  systemctl reload nginx
fi
# In TLS_MODE=node there is nothing to configure here: server.js reads CERT_PATH/KEY_PATH
# straight from .env and listens directly in HTTPS on PORT (== PUBLIC_PORT).

# ---------- 7. systemd service for the panel ----------
echo "⚙️  Configuration of the systemd service..."
sed -e "s|__PROJECT_DIR__|$PROJECT_DIR|g" \
    "$PROJECT_DIR/deploy/novaxpanel.service.template" > /etc/systemd/system/novaxpanel.service
systemctl daemon-reload
systemctl enable --now novaxpanel
systemctl restart novaxpanel

# ---------- 8. Certbot renewal hooks ----------
# Pre-hook stops HAProxy (needed if issuing/renewing via HTTP-01 on 80/443, harmless otherwise).
# Post-hook restarts HAProxy AND the panel itself (Node caches the cert in memory at startup,
# so TLS_MODE=node needs a restart after every renewal to pick up the fresh certificate).
echo "🔁 Installation of the Certbot renewal hooks..."
mkdir -p /etc/letsencrypt/renewal-hooks/pre /etc/letsencrypt/renewal-hooks/post
cp "$PROJECT_DIR/deploy/renewal-hooks/pre/stop-haproxy.sh" /etc/letsencrypt/renewal-hooks/pre/novaxpanel-stop-haproxy.sh
cp "$PROJECT_DIR/deploy/renewal-hooks/post/start-haproxy.sh" /etc/letsencrypt/renewal-hooks/post/novaxpanel-start-haproxy.sh
chmod +x /etc/letsencrypt/renewal-hooks/pre/novaxpanel-stop-haproxy.sh
chmod +x /etc/letsencrypt/renewal-hooks/post/novaxpanel-start-haproxy.sh
cat > /etc/letsencrypt/renewal-hooks/post/novaxpanel-restart-panel.sh <<'EOF'
#!/bin/bash
systemctl restart novaxpanel 2>/dev/null || true
if command -v nginx >/dev/null 2>&1; then systemctl reload nginx 2>/dev/null || true; fi
EOF
chmod +x /etc/letsencrypt/renewal-hooks/post/novaxpanel-restart-panel.sh

# ---------- 9. Install the `novaxpanel` maintenance CLI (update/uninstall/change domain, etc.) ----------
echo "⚙️  Installation of the 'novaxpanel' command (3x-ui style maintenance panel)..."
sed -e "s|__PROJECT_DIR__|$PROJECT_DIR|g" \
    "$PROJECT_DIR/deploy/novaxpanel-cli.sh" > /usr/local/bin/novaxpanel
chmod +x /usr/local/bin/novaxpanel

echo
echo "=================================================="
echo " ✅ Deployment completed !"
echo "    Panel accessible at : https://$DOMAIN:$PUBLIC_PORT"
echo "    Admin username       : $ADMIN_USER"
echo "    Admin password       : $ADMIN_PASS"
echo "    (changeable at any time from the panel or via: novaxpanel)"
echo
echo "    Service Node : systemctl status novaxpanel"
echo "    Logs         : journalctl -u novaxpanel -f"
echo "    Maintenance  : type 'novaxpanel' at any time (update, uninstall,"
echo "                   change domain/port/credentials, backup...)"
echo "=================================================="
