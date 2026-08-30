#!/bin/bash
# NOVA X Tunnel - shared TLS / Cloudflare helper functions.
# Sourced by deploy/install.sh and the novaxpanel maintenance CLI.
# Assumes `set -e` is active in the caller unless noted otherwise.

CF_RANGES_URL_V4="https://www.cloudflare.com/ips-v4"
CF_RANGES_URL_V6="https://www.cloudflare.com/ips-v6"
CF_CREDENTIALS_DIR="/root/.secrets"
CF_CREDENTIALS_FILE="$CF_CREDENTIALS_DIR/novaxpanel-cloudflare.ini"

# ---------- Cloudflare detection ----------

# Returns 0 (true) if $1 (a domain) currently resolves to an IP that belongs to
# Cloudflare's published ranges (i.e. the domain is proxied / "orange cloud").
domain_is_behind_cloudflare() {
  local domain="$1"
  local resolved_ip
  resolved_ip=$(dig +short A "$domain" 2>/dev/null | tail -n1)
  [[ -z "$resolved_ip" ]] && return 1

  local ranges
  ranges=$(curl -fsSL --max-time 6 "$CF_RANGES_URL_V4" 2>/dev/null) || return 1
  [[ -z "$ranges" ]] && return 1

  local range
  while IFS= read -r range; do
    [[ -z "$range" ]] && continue
    if ip_in_cidr "$resolved_ip" "$range"; then
      return 0
    fi
  done <<< "$ranges"
  return 1
}

# Pure-bash IPv4-in-CIDR check ($1 = ip, $2 = cidr)
ip_in_cidr() {
  local ip="$1" cidr="$2"
  local network="${cidr%/*}" prefix="${cidr#*/}"
  local IFS=.
  read -r i1 i2 i3 i4 <<< "$ip"
  read -r n1 n2 n3 n4 <<< "$network"
  local ip_int=$(( (i1 << 24) + (i2 << 16) + (i3 << 8) + i4 ))
  local net_int=$(( (n1 << 24) + (n2 << 16) + (n3 << 8) + n4 ))
  local mask=$(( 0xFFFFFFFF << (32 - prefix) & 0xFFFFFFFF ))
  [[ $(( ip_int & mask )) -eq $(( net_int & mask )) ]]
}

# ---------- Certbot: HTTP-01 standalone (works for non-proxied / grey-cloud domains) ----------

issue_cert_standalone() {
  local domain="$1"
  echo "🔐 Émission du certificat TLS pour $domain via HTTP-01 (standalone)..."

  local haproxy_was_active=false
  if systemctl is-active --quiet haproxy 2>/dev/null; then
    haproxy_was_active=true
    systemctl stop haproxy
  fi

  if certbot certonly --standalone --non-interactive --agree-tos \
      --register-unsafely-without-email -d "$domain"; then
    $haproxy_was_active && systemctl start haproxy
    return 0
  else
    echo "⚠️  Échec de l'émission du certificat (HTTP-01)."
    $haproxy_was_active && systemctl start haproxy
    return 1
  fi
}

# ---------- Certbot: DNS-01 via Cloudflare API token (works even if the domain stays proxied) ----------

ensure_certbot_dns_cloudflare() {
  if python3 -c "import certbot_dns_cloudflare" >/dev/null 2>&1; then
    return 0
  fi
  echo "📦 Installation du plugin certbot-dns-cloudflare..."
  if command -v apt-get >/dev/null 2>&1; then
    apt-get install -y python3-certbot-dns-cloudflare 2>/dev/null && return 0
  fi
  pip3 install --break-system-packages certbot-dns-cloudflare 2>/dev/null \
    || pip3 install certbot-dns-cloudflare
}

# Writes (or overwrites) the Cloudflare API token credentials file used by certbot.
write_cloudflare_credentials() {
  local token="$1"
  mkdir -p "$CF_CREDENTIALS_DIR"
  cat > "$CF_CREDENTIALS_FILE" <<EOF
dns_cloudflare_api_token = $token
EOF
  chmod 600 "$CF_CREDENTIALS_FILE"
}

issue_cert_cloudflare_dns() {
  local domain="$1" token="$2"
  ensure_certbot_dns_cloudflare
  write_cloudflare_credentials "$token"

  echo "🔐 Émission du certificat TLS pour $domain via DNS-01 (Cloudflare API)..."
  if certbot certonly --dns-cloudflare \
      --dns-cloudflare-credentials "$CF_CREDENTIALS_FILE" \
      --non-interactive --agree-tos --register-unsafely-without-email \
      -d "$domain"; then
    return 0
  else
    echo "⚠️  Échec de l'émission du certificat (DNS-01 Cloudflare). Vérifiez que le jeton API"
    echo "    a bien la permission 'Zone:DNS:Edit' sur la zone concernée."
    return 1
  fi
}

generate_self_signed_cert() {
  local domain="$1"
  local dir="/etc/letsencrypt/live/$domain"
  echo "⚠️  Génération d'un certificat auto-signé pour $domain (avertissement navigateur attendu)."
  mkdir -p "$dir"
  openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
    -keyout "$dir/privkey.pem" -out "$dir/fullchain.pem" \
    -subj "/CN=$domain" >/dev/null 2>&1
}

# Interactive helper: decides HOW to obtain a cert for $1 = domain, handling the
# Cloudflare case. Returns 0 on success (cert present at the expected path).
obtain_certificate_interactive() {
  local domain="$1"
  local cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"

  if [[ -f "$cert_path" ]]; then
    echo "✅ Certificat déjà présent pour $domain."
    return 0
  fi

  if ! command -v dig >/dev/null 2>&1; then
    apt-get install -y dnsutils >/dev/null 2>&1 || true
  fi

  if domain_is_behind_cloudflare "$domain"; then
    echo "=================================================="
    echo " ☁️  Ce domaine semble passer par le proxy Cloudflare (orange cloud)."
    echo "    La validation HTTP-01 classique échouera tant que le proxy est actif,"
    echo "    sauf si vous la désactivez temporairement (DNS only / grey cloud)."
    echo "=================================================="
    echo " Comment voulez-vous obtenir le certificat TLS ?"
    echo "   1) Challenge DNS-01 via un jeton API Cloudflare (le domaine reste proxifié)"
    echo "   2) Désactiver moi-même le proxy Cloudflare, puis valider en HTTP-01 standard"
    echo "   3) Utiliser un certificat auto-signé (déconseillé, avertissement navigateur)"
    read_tty -r -p "Choix [1/2/3] (défaut 1): " cf_choice
    cf_choice="${cf_choice:-1}"

    case "$cf_choice" in
      1)
        read_tty -r -p "👉 Jeton API Cloudflare (permission Zone:DNS:Edit sur la zone): " cf_token
        [[ -z "$cf_token" ]] && { echo "Jeton requis, abandon."; return 1; }
        issue_cert_cloudflare_dns "$domain" "$cf_token" && return 0
        return 1
        ;;
      2)
        echo "👉 Désactivez le proxy (nuage orange -> gris) pour $domain dans le tableau de bord"
        echo "   Cloudflare (DNS), attendez quelques minutes que ça se propage, puis validez ici."
        read_tty -r -p "Appuyez sur Entrée une fois le proxy désactivé pour continuer..." _
        issue_cert_standalone "$domain" && return 0
        return 1
        ;;
      3)
        generate_self_signed_cert "$domain"
        return 0
        ;;
      *)
        echo "Choix invalide, abandon."
        return 1
        ;;
    esac
  else
    issue_cert_standalone "$domain" && return 0
    return 1
  fi
}
