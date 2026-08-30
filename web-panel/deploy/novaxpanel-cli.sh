#!/bin/bash
# NOVA X Tunnel - Web Panel maintenance CLI ("novaxpanel").
# Installed to /usr/local/bin/novaxpanel by deploy/install.sh.
# Run `novaxpanel` for the interactive menu, or `novaxpanel <command>` directly.

set -e

if [[ $EUID -ne 0 ]]; then
  echo "Erreur : cette commande doit être exécutée en root (sudo novaxpanel)."
  exit 1
fi

PROJECT_DIR="__PROJECT_DIR__"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Erreur : $ENV_FILE introuvable. Le panel a-t-il bien été installé avec deploy/install.sh ?"
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
  echo " NOVA X Tunnel — Statut du panel web"
  echo "=================================================="
  echo " Domaine        : $(env_get DOMAIN)"
  echo " Mode TLS       : $([[ "$tls_mode" == "node" ]] && echo "Node direct (pas de Nginx)" || echo "Nginx reverse proxy")"
  echo " Port public    : $(env_get PUBLIC_PORT)"
  [[ "$tls_mode" != "node" ]] && echo " Port interne   : $(env_get PORT)"
  echo " URL            : https://$(env_get DOMAIN):$(env_get PUBLIC_PORT)"
  echo
  systemctl is-active --quiet novaxpanel && echo " Service Node   : ✅ actif" || echo " Service Node   : ❌ arrêté"
  if [[ "$tls_mode" != "node" ]]; then
    systemctl is-active --quiet nginx && echo " Nginx          : ✅ actif" || echo " Nginx          : ❌ arrêté"
  fi
  echo "=================================================="
}

cmd_logs() {
  echo "Ctrl+C pour quitter les logs."
  journalctl -u novaxpanel -f --no-pager -n 100
}

cmd_restart() { restart_panel; }

cmd_update() {
  cd "$PROJECT_DIR"
  if [[ -d .git ]]; then
    echo "📥 git pull..."
    git pull
  else
    echo "⚠️  Ce répertoire n'est pas un dépôt git — remplacez les fichiers manuellement"
    echo "   (ou re-clonez le dépôt) puis relancez 'novaxpanel update'."
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
  echo "Domaine actuel : $old_domain"
  read -r -p "👉 Nouveau nom de domaine: " new_domain
  [[ -z "$new_domain" ]] && { echo "Annulé."; return; }

  obtain_certificate_interactive "$new_domain" || { echo "❌ Échec, domaine non changé."; return 1; }

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
  echo "✅ Domaine changé : $old_domain -> $new_domain"
  echo "   Nouvelle URL: https://$new_domain:$(env_get PUBLIC_PORT)"
}

cmd_change_port() {
  local tls_mode; tls_mode=$(env_get TLS_MODE)

  if [[ "$tls_mode" == "node" ]]; then
    local current new
    current=$(env_get PUBLIC_PORT)
    echo "Port public actuel (Node en direct) : $current"
    read -r -p "👉 Nouveau port public: " new
    new="${new:-$current}"
    if ! [[ "$new" =~ ^[0-9]+$ ]] || (( new < 1 || new > 65535 )); then
      echo "❌ Port invalide: $new"; return 1
    fi
    env_set PUBLIC_PORT "$new"
    env_set PORT "$new"
    restart_panel
    echo "✅ Port mis à jour. Nouvelle URL: https://$(env_get DOMAIN):$new"
    return
  fi

  local current_public current_app new_public new_app
  current_public=$(env_get PUBLIC_PORT); current_app=$(env_get PORT)
  echo "Port public actuel  : $current_public"
  echo "Port interne actuel : $current_app"
  read -r -p "👉 Nouveau port public (vide = inchangé): " new_public
  read -r -p "👉 Nouveau port interne (vide = inchangé): " new_app
  new_public="${new_public:-$current_public}"
  new_app="${new_app:-$current_app}"

  for p in "$new_public" "$new_app"; do
    if ! [[ "$p" =~ ^[0-9]+$ ]] || (( p < 1 || p > 65535 )); then
      echo "❌ Port invalide: $p"; return 1
    fi
  done
  if [[ "$new_public" == "$new_app" ]]; then
    echo "❌ Le port public et le port interne doivent être différents."; return 1
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
  echo "✅ Ports mis à jour. Nouvelle URL: https://$domain:$new_public"
}

cmd_change_admin_username() {
  echo "Comptes admin existants :"
  node "$PROJECT_DIR/deploy/admin-tool.js" list
  read -r -p "👉 Nom d'utilisateur à renommer: " old_user
  read -r -p "👉 Nouveau nom d'utilisateur: " new_user
  [[ -z "$old_user" || -z "$new_user" ]] && { echo "Annulé."; return; }
  node "$PROJECT_DIR/deploy/admin-tool.js" set-username "$old_user" "$new_user"
}

cmd_change_admin_password() {
  echo "Comptes admin existants :"
  node "$PROJECT_DIR/deploy/admin-tool.js" list
  read -r -p "👉 Nom d'utilisateur dont changer le mot de passe: " user
  [[ -z "$user" ]] && { echo "Annulé."; return; }
  read -r -s -p "👉 Nouveau mot de passe (vide = généré automatiquement): " pass; echo
  if [[ -z "$pass" ]]; then
    pass=$(openssl rand -base64 14 | tr -d '=+/')
    echo "🔑 Mot de passe généré: $pass"
  fi
  node "$PROJECT_DIR/deploy/admin-tool.js" set-password "$user" "$pass"
}

cmd_regen_secret() {
  echo "⚠️  Régénérer la clé secrète déconnectera immédiatement tous les utilisateurs connectés."
  read -r -p "Continuer ? (o/N) " c
  [[ "$c" =~ ^[oOyY] ]] || { echo "Annulé."; return; }
  local secret; secret=$(openssl rand -hex 32)
  env_set SESSION_SECRET "$secret"
  restart_panel
  echo "✅ Nouvelle clé secrète générée et appliquée."
}

cmd_backup() {
  local dir="/root/novaxpanel-backups"
  mkdir -p "$dir"
  local file="$dir/novaxpanel-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
  tar -czf "$file" -C "$PROJECT_DIR" .env db/panel.sqlite3 2>/dev/null || \
  tar -czf "$file" -C "$PROJECT_DIR" .env
  echo "✅ Sauvegarde créée: $file"
}

cmd_restore() {
  local dir="/root/novaxpanel-backups"
  if [[ ! -d "$dir" ]] || [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
    echo "Aucune sauvegarde trouvée dans $dir."; return 1
  fi
  echo "Sauvegardes disponibles :"
  select f in "$dir"/*.tar.gz "Annuler"; do
    [[ "$f" == "Annuler" || -z "$f" ]] && return
    echo "⚠️  Ceci va écraser la config (.env) et la base actuelles."
    read -r -p "Continuer ? (o/N) " c
    [[ "$c" =~ ^[oOyY] ]] || return
    tar -xzf "$f" -C "$PROJECT_DIR"
    restart_panel
    echo "✅ Restauration terminée depuis $f"
    return
  done
}

cmd_tls_mode() {
  local current; current=$(env_get TLS_MODE)
  local domain; domain=$(env_get DOMAIN)
  local public_port; public_port=$(env_get PUBLIC_PORT)
  echo "Mode TLS actuel : $([[ "$current" == "node" ]] && echo "Node direct" || echo "Nginx reverse proxy")"
  echo "  1) Nginx reverse proxy"
  echo "  2) Node direct — certificat Let's Encrypt (auto, gère aussi Cloudflare DNS-01)"
  echo "  3) Node direct — certificat personnalisé (ex: Cloudflare Origin Certificate)"
  read -r -p "Choix [1/2/3]: " choice

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
    echo "✅ Le panel gère maintenant directement le certificat (plus de Nginx)."

  elif [[ "$choice" == "3" ]]; then
    echo "☁️  Certificat personnalisé (ex: Cloudflare Origin Certificate)."
    echo "   Générez-le dans le tableau de bord Cloudflare : SSL/TLS > Certificats d'origine > Créer un certificat,"
    echo "   puis pensez à passer le mode SSL/TLS Cloudflare du domaine sur 'Full (strict)'."
    read -r -p "👉 Chemin du certificat (fullchain/cert .pem): " custom_cert
    read -r -p "👉 Chemin de la clé privée (.pem/.key): " custom_key
    if [[ ! -f "$custom_cert" || ! -f "$custom_key" ]]; then
      echo "❌ Fichier introuvable. Copiez d'abord le certificat et la clé sur ce serveur, puis réessayez."
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
    echo "✅ Le panel utilise maintenant votre certificat personnalisé (plus de Nginx)."

  elif [[ "$choice" == "1" && "$current" != "nginx" ]]; then
    if ! command -v nginx >/dev/null 2>&1; then
      echo "📦 Installation de Nginx..."
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
    echo "✅ Nginx gère maintenant le TLS en reverse proxy."
  else
    echo "Aucun changement."
  fi
}

cmd_uninstall() {
  echo "=================================================="
  echo " ⚠️  Désinstallation du panel web NOVA X Tunnel"
  echo "=================================================="
  echo " Ceci va : arrêter/désactiver le service, retirer la config Nginx et le"
  echo " certificat TLS associés, et retirer la commande 'novaxpanel'."
  echo " (Le panel terminal 'menu' et vos comptes SSH/ZiVPN NE SONT PAS touchés.)"
  read -r -p "Confirmer la désinstallation ? (tapez 'oui'): " c
  [[ "$c" == "oui" ]] || { echo "Annulé."; return; }

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

  read -r -p "Supprimer aussi le certificat TLS pour $domain ? (o/N) " c2
  if [[ "$c2" =~ ^[oOyY] ]]; then
    certbot delete --cert-name "$domain" --non-interactive 2>/dev/null || true
  fi

  read -r -p "Supprimer aussi les données (base SQLite, .env, node_modules) ? (o/N) " c3
  if [[ "$c3" =~ ^[oOyY] ]]; then
    rm -rf "$PROJECT_DIR/node_modules" "$PROJECT_DIR/.env" "$PROJECT_DIR/db/panel.sqlite3"
    echo "🗑️  Données supprimées."
  else
    echo "ℹ️  Données conservées dans $PROJECT_DIR (utile pour une réinstallation)."
  fi

  echo "✅ Panel web désinstallé."
  rm -f /usr/local/bin/novaxpanel
  echo "   (Commande 'novaxpanel' retirée.)"
}

show_menu() {
  cat <<'EOF'

==================================================
   NOVA X TUNNEL — Panel de maintenance (web panel)
==================================================
  1) Statut
  2) Voir les logs en direct
  3) Redémarrer le service
  4) Mettre à jour
  5) Changer le nom de domaine
  6) Changer les ports (public / interne)
  7) Basculer Nginx <-> Node direct (mode TLS)
  8) Changer le nom d'utilisateur admin
  9) Changer le mot de passe admin
 10) Régénérer la clé secrète de session
 11) Sauvegarder
 12) Restaurer une sauvegarde
 13) Désinstaller le panel web
  0) Quitter
==================================================
EOF
  read -r -p "Choix: " choice
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
    *) echo "Choix invalide." ;;
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
    while true; do show_menu; read -r -p "Appuyez sur Entrée pour continuer..." _; done
    ;;
  *)
    echo "Commande inconnue: $1"
    echo "Usage: novaxpanel [status|logs|restart|update|domain|port|tls-mode|admin-user|admin-pass|secret|backup|restore|uninstall]"
    exit 1
    ;;
esac
