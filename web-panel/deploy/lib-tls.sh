#!/bin/bash
# NOVA X Tunnel - shared TLS / Cloudflare helper functions.
# Sourced by deploy/install.sh and the novaxpanel maintenance CLI.
# Assumes `set -e` is active in the caller unless noted otherwise.

CF_RANGES_URL_V4="https://www.cloudflare.com/ips-v4"
CF_RANGES_URL_V6="https://www.cloudflare.com/ips-v6"
CF_CREDENTIALS_DIR="/root/.secrets"
CF_CREDENTIALS_FILE="$CF_CREDENTIALS_DIR/novaxpanel-cloudflare.ini"

# ---------- Cloudflare detection ----------

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
  echo "🔐 Certificate emission for $domain via HTTP-01 (standalone)..."

  local haproxy_was_active=false
  if systemctl is-active --quiet haproxy 2>/dev/null; then
    haproxy_was_active=true
    systemctl stop haproxy
  fi

  if certbot certonly --standalone --non-interactive --agree-tos \
      --register-unsafely-without-email -d "$domain"; then
    if [[ "$haproxy_was_active" == true ]]; then
      systemctl start haproxy
    fi
    return 0
  else
    echo "⚠️  failed to obtain certificate (HTTP-01)."
    if [[ "$haproxy_was_active" == true ]]; then
      systemctl start haproxy
    fi
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

  echo "🔐 Certificate emission for $domain via DNS-01 (Cloudflare API)..."
  if certbot certonly --dns-cloudflare \
      --dns-cloudflare-credentials "$CF_CREDENTIALS_FILE" \
      --non-interactive --agree-tos --register-unsafely-without-email \
      -d "$domain"; then
    return 0
  else
    echo "⚠️  failed to obtain certificate (DNS-01 Cloudflare). Check that the API token"
    echo "    has the 'Zone:DNS:Edit' permission on the concerned zone."
    return 1
  fi
}

generate_self_signed_cert() {
  local target="$1"
  local dir="/etc/letsencrypt/live/$target"
  echo "⚠️  Generating a self-signed certificate for $target (browser warning expected)."
  mkdir -p "$dir"

  # A modern browser/TLS client checks the Subject Alternative Name, not the legacy CN -
  # and for an IP address it specifically needs an "IP:" SAN entry (a "DNS:" one, or CN
  # alone, is silently ignored for IP targets by most clients). Build the right SAN
  # depending on whether $target is an IP literal or an actual hostname.
  local san
  if [[ "$target" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    san="IP:$target"
  else
    san="DNS:$target"
  fi

  openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
    -keyout "$dir/privkey.pem" -out "$dir/fullchain.pem" \
    -subj "/CN=$target" \
    -addext "subjectAltName=$san" >/dev/null 2>&1
}

# Interactive helper: decides HOW to obtain a cert for $1 = domain, handling the
# Cloudflare case. Returns 0 on success (cert present at the expected path).
obtain_certificate_interactive() {
  local domain="$1"
  local cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"

  if [[ -f "$cert_path" ]]; then
    echo "✅ Certificate already present for $domain."
    return 0
  fi

  if ! command -v dig >/dev/null 2>&1; then
    apt-get install -y dnsutils >/dev/null 2>&1 || true
  fi

  if domain_is_behind_cloudflare "$domain"; then
    echo "=================================================="
    echo " ☁️  This domain appears to be proxied by Cloudflare (orange cloud)."
    echo "    The standard HTTP-01 validation will fail while the proxy is active,"
    echo "    unless you temporarily disable it (DNS only / grey cloud)."
    echo "=================================================="
    echo " How would you like to obtain the TLS certificate ?"
    echo "   1) DNS-01 challenge via a Cloudflare API token (domain remains proxied)"
    echo "   2) Disable the Cloudflare proxy, then validate via standard HTTP-01"
    echo "   3) Use a self-signed certificate (not recommended, browser warning)"
    read -r -p "Choice [1/2/3] (default 1): " cf_choice
    cf_choice="${cf_choice:-1}"

    case "$cf_choice" in
      1)
        read -r -p "👉 Cloudflare API Token (permission Zone:DNS:Edit on the zone): " cf_token
        [[ -z "$cf_token" ]] && { echo "Token required, aborting."; return 1; }
        issue_cert_cloudflare_dns "$domain" "$cf_token" && return 0
        return 1
        ;;
      2)
        echo "👉 Disable the proxy (orange cloud -> grey cloud) for $domain in the Cloudflare dashboard"
        echo "   (DNS), wait a few minutes for the change to propagate, then validate here."
        read -r -p "Press Enter once the proxy is disabled to continue..." _
        issue_cert_standalone "$domain" && return 0
        return 1
        ;;
      3)
        generate_self_signed_cert "$domain"
        return 0
        ;;
      *)
        echo "Invalid choice, aborting."
        return 1
        ;;
    esac
  else
    issue_cert_standalone "$domain" && return 0
    return 1
  fi
}