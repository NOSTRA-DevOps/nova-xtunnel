#!/bin/bash

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_UL=$'\033[4m'

# Premium Color Palette
C_RED=$'\033[38;5;196m'      # Bright Red
C_GREEN=$'\033[38;5;46m'     # Neon Green
C_YELLOW=$'\033[38;5;226m'   # Bright Yellow
C_BLUE=$'\033[38;5;39m'      # Deep Sky Blue
C_PURPLE=$'\033[38;5;135m'   # Light Purple
C_CYAN=$'\033[38;5;51m'      # Cyan
C_WHITE=$'\033[38;5;255m'    # Bright White
C_GRAY=$'\033[38;5;245m'     # Gray
C_ORANGE=$'\033[38;5;208m'   # Orange

# Semantic Aliases
C_TITLE=$C_PURPLE
C_CHOICE=$C_CYAN
C_PROMPT=$C_BLUE
C_WARN=$C_YELLOW
C_DANGER=$C_RED
C_STATUS_A=$C_GREEN
C_STATUS_I=$C_GRAY
C_ACCENT=$C_ORANGE

DB_DIR="/etc/novaxtunnel"
DB_FILE="$DB_DIR/users.db"
INSTALL_FLAG_FILE="$DB_DIR/.install"
BADVPN_SERVICE_FILE="/etc/systemd/system/badvpn.service"
BADVPN_BUILD_DIR="/root/badvpn-build"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/default"
SSL_CERT_DIR="/etc/novaxtunnel/ssl"
SSL_CERT_FILE="$SSL_CERT_DIR/novaxtunnel.pem"
SSL_CERT_CHAIN_FILE="$SSL_CERT_DIR/novaxtunnel.crt"
SSL_CERT_KEY_FILE="$SSL_CERT_DIR/novaxtunnel.key"
EDGE_CERT_INFO_FILE="$DB_DIR/edge_cert.conf"
NGINX_PORTS_FILE="$DB_DIR/nginx_ports.conf"
EDGE_PUBLIC_HTTP_PORT="80"
EDGE_PUBLIC_TLS_PORT="443"
NGINX_INTERNAL_HTTP_PORT="8880"
NGINX_INTERNAL_TLS_PORT="8443"
HAPROXY_INTERNAL_DECRYPT_PORT="10443"
DNSTT_SERVICE_FILE="/etc/systemd/system/dnstt.service"
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_KEYS_DIR="/etc/novaxtunnel/dnstt"
DNSTT_CONFIG_FILE="$DB_DIR/dnstt_info.conf"
DNS_INFO_FILE="$DB_DIR/dns_info.conf"
UDP_CUSTOM_DIR="/root/udp"
UDP_CUSTOM_SERVICE_FILE="/etc/systemd/system/udp-custom.service"
UDP_CUSTOM_LISTEN_PORT="36712"
UDP_CUSTOM_RANGE_START="1"
UDP_CUSTOM_RANGE_END="65535"
UDP_CUSTOM_EXCLUDE_SINGLE_PORTS="53 5300"
SSH_BANNER_FILE="/etc/bannerssh"
FALCONPROXY_SERVICE_FILE="/etc/systemd/system/falconproxy.service"
FALCONPROXY_BINARY="/usr/local/bin/falconproxy"
FALCONPROXY_CONFIG_FILE="$DB_DIR/falconproxy_config.conf"
# Dossier persistant (hors /usr/local/bin, donc jamais en conflit avec FALCONPROXY_BINARY
# ci-dessus) contenant les binaires pré-compilés livrés avec le projet
# (falconproxy, falconproxyarm[, VERSION]). C'est aussi là que vit une copie du code
# original récupéré depuis le dépôt git. S'il existe, install_falcon_proxy l'utilise
# directement au lieu de télécharger depuis GitHub.
FALCONPROXY_BUNDLE_DIR="/opt/nova-x-tunnel/terminal-panel/falconproxy"

# --- PY SOCKS/WS Proxy (legacy SSHPlus-style CONNECT tunnel, ported to Python 3) ---
PYPROXY_DIR="$DB_DIR/pyproxy"
PYPROXY_SCRIPT="$PYPROXY_DIR/novaxtunnel_pyproxy.py"
PYPROXY_SOCKS_SERVICE="/etc/systemd/system/pyproxy-socks.service"
PYPROXY_WS_SERVICE="/etc/systemd/system/pyproxy-ws.service"
PYPROXY_CONFIG_FILE="$DB_DIR/pyproxy_config.conf"
LIMITER_SCRIPT="/usr/local/bin/novaxtunnel-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/novaxtunnel-limiter.service"
BANDWIDTH_DIR="$DB_DIR/bandwidth"
BANDWIDTH_SCRIPT="/usr/local/bin/novaxtunnel-bandwidth.sh"
BANDWIDTH_SERVICE="/etc/systemd/system/novaxtunnel-bandwidth.service"
LEGACY_BANDWIDTH_DIR="/usr/local/bin/firewallfalcon-bandwidth"
TRIAL_CLEANUP_SCRIPT="/usr/local/bin/novaxtunnel-trial-cleanup.sh"
LOGIN_INFO_SCRIPT="/usr/local/bin/novaxtunnel-login-info.sh"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/novaxtunnel.conf"

# --- ZiVPN Variables ---
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_SERVICE_FILE="/etc/systemd/system/zivpn.service"
ZIVPN_CONFIG_FILE="$ZIVPN_DIR/config.json"
ZIVPN_CERT_FILE="$ZIVPN_DIR/zivpn.crt"
ZIVPN_KEY_FILE="$ZIVPN_DIR/zivpn.key"
ZIVPN_META_FILE="$ZIVPN_DIR/passwords_meta.json"
ZIVPN_CLEANUP_SCRIPT="/usr/local/bin/novaxtunnel-zivpn-cleanup.sh"
ZIVPN_CLEANUP_CRON_MARKER="novaxtunnel-zivpn-cleanup"
ZIVPN_LISTEN_PORT="5667"
# Plage publique dédiée à ZiVPN (redirigée en interne vers ZIVPN_LISTEN_PORT).
# Doit rester totalement disjointe de UDP_CUSTOM_RANGE_START:UDP_CUSTOM_RANGE_END.
ZIVPN_RANGE_START="6000"
ZIVPN_RANGE_END="19999"

DESEC_TOKEN="V55cFY8zTictLCPfviiuX5DHjs15"
DESEC_DOMAIN="manager.firewallfalcon.qzz.io"

SELECTED_USER=""
UNINSTALL_MODE="interactive"
BANNER_CACHE_TTL=15
BANNER_CACHE_TS=0
BANNER_CACHE_OS_NAME=""
BANNER_CACHE_SERVER_IP=""
BANNER_CACHE_UP_TIME=""
BANNER_CACHE_RAM_USAGE=""
BANNER_CACHE_CPU_LOAD=""
BANNER_CACHE_ONLINE_USERS=0
BANNER_CACHE_TOTAL_USERS=0
SSH_SESSION_CACHE_TTL=10
SSH_SESSION_CACHE_TS=0
SSH_SESSION_CACHE_DB_MTIME=0
SSH_SESSION_TOTAL=0
APT_CACHE_READY=0
FF_USERS_GROUP="ffusers"
declare -A SSH_SESSION_COUNTS=()
declare -A SSH_SESSION_PIDS=()

if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}❌ Error: This script requires root privileges to run.${C_RESET}"
   exit 1
fi

get_ubuntu_codename() {
    local codename=""

    if [[ -r /etc/os-release ]]; then
        codename=$(awk -F= '/^(VERSION_CODENAME|UBUNTU_CODENAME)=/{gsub(/"/, "", $2); if ($2 != "") { print $2; exit }}' /etc/os-release 2>/dev/null)
    fi

    if [[ -z "$codename" ]] && command -v lsb_release &>/dev/null; then
        codename=$(lsb_release -sc 2>/dev/null)
    fi

    echo "$codename"
}

is_known_eol_ubuntu_codename() {
    case "$1" in
        yakkety|zesty|artful|cosmic|disco|eoan|groovy|hirsute|impish|kinetic|lunar|mantic|oracular|plucky)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

rewrite_ubuntu_apt_sources() {
    local mode="$1"
    local os_id=""
    local changed=false
    local file backup_file
    local from_archive to_archive from_security to_security from_ports to_ports
    local -a source_files=("/etc/apt/sources.list" /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)

    if [[ -r /etc/os-release ]]; then
        os_id=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2; exit}' /etc/os-release 2>/dev/null)
    fi
    [[ "$os_id" == "ubuntu" ]] || return 1

    case "$mode" in
        primary)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://archive.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://security.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://ports.ubuntu.com/ubuntu-ports'
            ;;
        old-releases)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://old-releases.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://old-releases.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://old-releases.ubuntu.com/ubuntu'
            ;;
        *)
            return 1
            ;;
    esac

    for file in "${source_files[@]}"; do
        [[ -f "$file" ]] || continue
        if grep -Eq "$from_archive|$from_security|$from_ports" "$file" 2>/dev/null; then
            backup_file="${file}.bak.novaxtunnel"
            [[ -f "$backup_file" ]] || cp "$file" "$backup_file" 2>/dev/null || true
            sed -i -E \
                -e "s|$from_archive|$to_archive|g" \
                -e "s|$from_security|$to_security|g" \
                -e "s|$from_ports|$to_ports|g" \
                "$file" 2>/dev/null
            changed=true
        fi
    done

    $changed
}

repair_ubuntu_apt_mirrors() {
    rewrite_ubuntu_apt_sources "primary"
}

switch_ubuntu_to_old_releases() {
    local codename
    codename=$(get_ubuntu_codename)
    [[ -n "$codename" ]] || return 1
    is_known_eol_ubuntu_codename "$codename" || return 1
    rewrite_ubuntu_apt_sources "old-releases"
}

ff_apt_update() {
    local -a apt_opts=(
        -o Acquire::Retries=3
        -o Acquire::ForceIPv4=true
        -o Acquire::http::Timeout=20
        -o Acquire::https::Timeout=20
        -o Acquire::http::Pipeline-Depth=0
    )

    if (( APT_CACHE_READY == 1 )); then
        return 0
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
        APT_CACHE_READY=1
        return 0
    fi

    if repair_ubuntu_apt_mirrors; then
        echo -e "${C_YELLOW}⚠️ APT mirror timed out. Switching Ubuntu sources to archive.ubuntu.com and retrying...${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    if switch_ubuntu_to_old_releases; then
        echo -e "${C_YELLOW}⚠️ Detected an end-of-life Ubuntu release. Switching APT sources to old-releases.ubuntu.com and retrying...${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    echo -e "${C_RED}❌ Failed to refresh package lists. Please check VPS network, DNS, or blocked Ubuntu mirrors.${C_RESET}"
    return 1
}

ff_apt_install() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0

    ff_apt_update || return 1
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "${packages[@]}"
}

ff_apt_purge() {
    local -a packages=("$@")
    (( ${#packages[@]} > 0 )) || return 0
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "${packages[@]}"
}

# Mandatory Dependency Check (Added jq and curl)
check_environment() {
    local missing_packages=()
    local cmd

    for cmd in bc jq curl wget; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_packages+=("$cmd")
        fi
    done

    if (( ${#missing_packages[@]} > 0 )); then
        echo -e "${C_YELLOW}⚠️ Installing missing dependencies: ${missing_packages[*]}${C_RESET}"
        ff_apt_install "${missing_packages[@]}" >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Error: Failed to install required dependencies: ${missing_packages[*]}.${C_RESET}"
            exit 1
        }
    fi
}

ensure_novaxtunnel_dirs() {
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$BANDWIDTH_DIR" /etc/ssh/sshd_config.d
    touch "$DB_FILE"
}

ensure_novaxtunnel_system_group() {
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1 || true
}

db_has_user() {
    [[ -f "$DB_FILE" ]] || return 1
    awk -F: -v target="$1" '$1 == target { found=1; exit } END { exit(found ? 0 : 1) }' "$DB_FILE"
}

is_novaxtunnel_orphan_user() {
    local username="$1"
    local passwd_line system_user _ uid _ home shell

    passwd_line=$(getent passwd "$username" 2>/dev/null) || return 1
    IFS=: read -r system_user _ uid _ _ home shell <<< "$passwd_line"
    [[ "$uid" =~ ^[0-9]+$ ]] || return 1
    db_has_user "$username" && return 1

    if id -nG "$username" 2>/dev/null | tr ' ' '\n' | grep -Fxq "$FF_USERS_GROUP"; then
        return 0
    fi

    (( uid >= 1000 )) || return 1
    [[ "$home" == "/home/$username" || "$home" == /home/* ]] || return 1

    case "$shell" in
        /usr/sbin/nologin|/usr/bin/false|/bin/false) return 0 ;;
    esac

    return 1
}

get_novaxtunnel_orphan_users() {
    local username
    while IFS=: read -r username _rest; do
        [[ -n "$username" ]] || continue
        if is_novaxtunnel_orphan_user "$username"; then
            echo "$username"
        fi
    done < /etc/passwd
}

get_novaxtunnel_known_users() {
    local username
    local -A seen_users=()

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r username _rest; do
            [[ -n "$username" && "$username" != \#* ]] || continue
            seen_users["$username"]=1
        done < "$DB_FILE"
    fi

    while IFS= read -r username; do
        [[ -n "$username" ]] && seen_users["$username"]=1
    done < <(get_novaxtunnel_orphan_users)

    (( ${#seen_users[@]} > 0 )) || return 0
    printf "%s\n" "${!seen_users[@]}" | sort
}

delete_novaxtunnel_user_accounts() {
    local -a users_to_delete=("$@")
    local username

    [[ ${#users_to_delete[@]} -gt 0 ]] || return 0

    for username in "${users_to_delete[@]}"; do
        [[ -n "$username" ]] || continue
        killall -u "$username" -9 &>/dev/null
        if id "$username" &>/dev/null; then
            if userdel -r "$username" &>/dev/null; then
                echo -e " ✅ System user '${C_YELLOW}$username${C_RESET}' deleted."
            else
                echo -e " ❌ Failed to delete system user '${C_YELLOW}$username${C_RESET}'."
            fi
        else
            echo -e " ℹ️ System user '${C_YELLOW}$username${C_RESET}' was already missing. Removing manager data only."
        fi
        rm -f "$BANDWIDTH_DIR/${username}.usage"
        rm -rf "$BANDWIDTH_DIR/pidtrack/${username}"
    done

    if [[ -f "$DB_FILE" ]]; then
        local db_tmp
        db_tmp=$(mktemp)
        awk -F: 'NR==FNR { drop[$1]=1; next } !($1 in drop)' <(printf "%s\n" "${users_to_delete[@]}") "$DB_FILE" > "$db_tmp" && mv "$db_tmp" "$DB_FILE"
        rm -f "$db_tmp" 2>/dev/null
    fi

    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

require_interactive_terminal() {
    if [[ ! -t 0 || ! -t 1 ]]; then
        echo -e "${C_RED}❌ Error: The NOVA XTUNNEL menu must be run from an interactive terminal.${C_RESET}"
        exit 1
    fi
}

initial_setup() {
    echo -e "${C_BLUE}⚙️ Initializing NOVA XTUNNEL setup...${C_RESET}"
    check_environment
    
    ensure_novaxtunnel_dirs
    ensure_novaxtunnel_system_group
    
    echo -e "${C_BLUE}🔹 Configuring user limiter service...${C_RESET}"
    setup_limiter_service
    
    echo -e "${C_BLUE}🔹 Configuring bandwidth monitoring service...${C_RESET}"
    setup_bandwidth_service
    
    echo -e "${C_BLUE}🔹 Installing trial account cleanup script...${C_RESET}"
    setup_trial_cleanup_script
    
    echo -e "${C_BLUE}🔹 Cleaning legacy dynamic SSH banner hooks...${C_RESET}"
    disable_dynamic_ssh_banner_system
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true
    
    if [ ! -f "$INSTALL_FLAG_FILE" ]; then
        touch "$INSTALL_FLAG_FILE"
    fi
    echo -e "${C_GREEN}✅ Setup finished.${C_RESET}"
}

_is_valid_ipv4() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

check_and_open_firewall_port() {
    local port="$1"
    local protocol="${2:-tcp}"
    local firewall_detected=false

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        firewall_detected=true
        if ! ufw status | grep -qw "$port/$protocol"; then
            echo -e "${C_YELLOW}🔥 UFW firewall is active and port ${port}/${protocol} is closed.${C_RESET}"
            read -p "👉 Do you want to open this port now? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                ufw allow "$port/$protocol"
                echo -e "${C_GREEN}✅ Port ${port}/${protocol} has been opened in UFW.${C_RESET}"
            else
                echo -e "${C_RED}❌ Warning: Port ${port}/${protocol} was not opened. The service may not work correctly.${C_RESET}"
                return 1
            fi
        else
             echo -e "${C_GREEN}✅ Port ${port}/${protocol} is already open in UFW.${C_RESET}"
        fi
    fi

    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        firewall_detected=true
        if ! firewall-cmd --list-ports --permanent | grep -qw "$port/$protocol"; then
            echo -e "${C_YELLOW}🔥 firewalld is active and port ${port}/${protocol} is not open.${C_RESET}"
            read -p "👉 Do you want to open this port now? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                firewall-cmd --add-port="$port/$protocol" --permanent
                firewall-cmd --reload
                echo -e "${C_GREEN}✅ Port ${port}/${protocol} has been opened in firewalld.${C_RESET}"
            else
                echo -e "${C_RED}❌ Warning: Port ${port}/${protocol} was not opened. The service may not work correctly.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Port ${port}/${protocol} is already open in firewalld.${C_RESET}"
        fi
    fi

    if ! $firewall_detected; then
        echo -e "${C_BLUE}ℹ️ No active firewall (UFW or firewalld) detected. Assuming ports are open.${C_RESET}"
    fi
    return 0
}

check_and_free_ports() {
    local ports_to_check=("$@")
    for port in "${ports_to_check[@]}"; do
        echo -e "\n${C_BLUE}🔎 Checking if port $port is available...${C_RESET}"
        local conflicting_process_info
        conflicting_process_info=$(
            ss -H -lntp "( sport = :$port )" 2>/dev/null
            ss -H -lunp "( sport = :$port )" 2>/dev/null
        )
        
        if [[ -n "$conflicting_process_info" ]]; then
            local conflicting_pid
            conflicting_pid=$(echo "$conflicting_process_info" | grep -oP 'pid=\K[0-9]+' | head -n 1)
            local conflicting_name
            conflicting_name=$(echo "$conflicting_process_info" | grep -oP 'users:\(\("(\K[^"]+)' | head -n 1)
            
            echo -e "${C_YELLOW}⚠️ Warning: Port $port is in use by process '${conflicting_name:-unknown}' (PID: ${conflicting_pid:-N/A}).${C_RESET}"
            read -p "👉 Do you want to attempt to stop this process? (y/n): " kill_confirm
            if [[ "$kill_confirm" == "y" || "$kill_confirm" == "Y" ]]; then
                if [[ -z "$conflicting_pid" ]]; then
                    echo -e "${C_RED}❌ Could not determine which PID owns port $port. Please free it manually.${C_RESET}"
                    return 1
                fi
                echo -e "${C_GREEN}🛑 Stopping process PID $conflicting_pid...${C_RESET}"
                systemctl stop "$(ps -p "$conflicting_pid" -o comm=)" &>/dev/null || kill -9 "$conflicting_pid"
                sleep 2
                
                if ss -H -lntp "( sport = :$port )" 2>/dev/null | grep -q . || ss -H -lunp "( sport = :$port )" 2>/dev/null | grep -q .; then
                     echo -e "${C_RED}❌ Failed to free port $port. Please handle it manually. Aborting.${C_RESET}"
                     return 1
                else
                     echo -e "${C_GREEN}✅ Port $port has been successfully freed.${C_RESET}"
                fi
            else
                echo -e "${C_RED}❌ Cannot proceed without freeing port $port. Aborting.${C_RESET}"
                return 1
            fi
        else
            echo -e "${C_GREEN}✅ Port $port is free to use.${C_RESET}"
        fi
    done
    return 0
}


_ff_flush_dnat_to_port() {
    local internal_port="$1" rule
    while IFS= read -r rule; do
        [ -z "$rule" ] && continue
        # shellcheck disable=SC2086
        iptables -t nat -D ${rule#-A } 2>/dev/null
    done < <(iptables -t nat -S PREROUTING 2>/dev/null | grep -- "--to-destination :${internal_port}$")
}

# Opens/redirects an entire public UDP range towards a single internal listen port.
# Usage: check_and_open_firewall_udp_range <range_start> <range_end> <internal_port>
check_and_open_firewall_udp_range() {
    local range_start="$1" range_end="$2" internal_port="$3"

    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        if ! ufw status | grep -qw "${range_start}:${range_end}/udp"; then
            ufw allow "${range_start}:${range_end}/udp" >/dev/null
        fi
    fi

    if command -v firewall-cmd &> /dev/null && systemctl is-active --quiet firewalld; then
        if ! firewall-cmd --list-ports --permanent | grep -qw "${range_start}-${range_end}/udp"; then
            firewall-cmd --add-port="${range_start}-${range_end}/udp" --permanent >/dev/null
            firewall-cmd --reload >/dev/null
        fi
    fi

    local iface
    iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
    if [ -n "$iface" ]; then
        # Remove any previous rule redirecting this exact range (idempotent re-install/update)
        iptables -t nat -D PREROUTING -i "$iface" -p udp --dport "${range_start}:${range_end}" -j DNAT --to-destination ":${internal_port}" 2>/dev/null
        iptables -t nat -A PREROUTING -i "$iface" -p udp --dport "${range_start}:${range_end}" -j DNAT --to-destination ":${internal_port}"
    else
        echo -e "${C_YELLOW}⚠️ Could not detect default interface for IPTables redirection (${range_start}:${range_end} -> ${internal_port}).${C_RESET}"
    fi
}

# Two inclusive integer ranges [a1,a2] and [b1,b2] overlap if a1<=b2 AND b1<=a2.
_ff_ranges_overlap() {
    local a1=$1 a2=$2 b1=$3 b2=$4
    [ "$a1" -le "$b2" ] && [ "$b1" -le "$a2" ]
}


_ff_split_range() {
    local full_start="$1" full_end="$2"; shift 2
    local segs=("$full_start $full_end")
    while [ "$#" -ge 2 ]; do
        local exs="$1" exe="$2"; shift 2
        local new_segs=()
        local seg
        for seg in "${segs[@]}"; do
            local ss=${seg% *} se=${seg#* }
            if [ "$exe" -lt "$ss" ] || [ "$exs" -gt "$se" ]; then
                new_segs+=("$seg")
                continue
            fi
            [ "$exs" -gt "$ss" ] && new_segs+=("$ss $((exs-1))")
            [ "$exe" -lt "$se" ] && new_segs+=("$((exe+1)) $se")
        done
        segs=("${new_segs[@]}")
    done
    printf '%s\n' "${segs[@]}"
}

# Guards against installing udp-custom and ZiVPN with overlapping public UDP port ranges.
_ff_check_udp_range_conflict() {
    local this_start="$1" this_end="$2" other_start="$3" other_end="$4" other_name="$5"
    if _ff_ranges_overlap "$this_start" "$this_end" "$other_start" "$other_end"; then
        echo -e "${C_RED}❌ Conflit de plage UDP : ${this_start}-${this_end} chevauche la plage déjà utilisée par ${other_name} (${other_start}-${other_end}).${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Modifiez les variables de plage en haut du script pour que les deux plages soient totalement séparées.${C_RESET}"
        return 1
    fi
    return 0
}

setup_limiter_service() {
    # Combined limiter + bandwidth monitoring
    cat > "$LIMITER_SCRIPT" << 'EOF'
#!/bin/bash
# NOVA XTUNNEL limiter version 2026-08-10.1
DB_FILE="/etc/novaxtunnel/users.db"
BW_DIR="/etc/novaxtunnel/bandwidth"
PID_DIR="$BW_DIR/pidtrack"
BANNER_DIR="/etc/novaxtunnel/banners"
SCAN_INTERVAL=30

mkdir -p "$BW_DIR" "$PID_DIR"
shopt -s nullglob

write_banner_if_changed() {
    local user="$1"
    local content="$2"
    local banner_file="$BANNER_DIR/${user}.txt"
    local tmp_file="${banner_file}.tmp"

    printf "%s" "$content" > "$tmp_file"
    if ! cmp -s "$tmp_file" "$banner_file" 2>/dev/null; then
        mv "$tmp_file" "$banner_file"
    else
        rm -f "$tmp_file"
    fi
}

while true; do
    if [[ ! -s "$DB_FILE" ]]; then
        sleep "$SCAN_INTERVAL"
        continue
    fi

    current_ts=$(date +%s)
    dynamic_banners_enabled=false
    declare -A session_pids=()
    declare -A locked_users=()
    declare -A uid_to_user=()
    declare -A loginuid_pids=()
    declare -A monitor_ppids=()

    while IFS=: read -r username _ uid _rest; do
        [[ -n "$username" && "$uid" =~ ^[0-9]+$ ]] && uid_to_user["$uid"]="$username"
    done < /etc/passwd

    # OpenSSH privilege separation means EVERY login is actually TWO processes: a root-owned
    # "[priv]" monitor, and the child it forks after auth that drops privileges to run as the
    # real user (the one that shows up owned by the user below). We record each child's PPID
    # here so the loginuid pass further down can skip that monitor - otherwise one real login
    # gets counted as two sessions (this is what made a 1-person account show "2/2" and then
    # get hit by the connection-limit lock as soon as that one person opened one more real
    # connection).
    while read -r ssh_pid ssh_ppid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue

        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" ]]; then
            session_pids["$ssh_owner"]+="$ssh_pid "
            monitor_ppids["$ssh_ppid"]=1
        fi
    done < <(ps -C sshd -o pid=,ppid=,user= 2>/dev/null)

    for p in /proc/[0-9]*/loginuid; do
        [[ -f "$p" ]] || continue
        login_uid=""
        read -r login_uid < "$p" || login_uid=""
        [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]] || continue

        session_user="${uid_to_user[$login_uid]}"
        [[ -n "$session_user" ]] || continue


        pid_dir=$(dirname "$p")
        pid_num=$(basename "$pid_dir")

        # This pid is the privsep monitor of a session already counted directly in
        # session_pids above (its privilege-dropped child) - skip it, same login.
        [[ -n "${monitor_ppids[$pid_num]+x}" ]] && continue

        comm=""
        read -r comm < "$pid_dir/comm" || comm=""
        [[ "$comm" == "sshd" ]] || continue

        ppid_val=""
        while read -r key value; do
            if [[ "$key" == "PPid:" ]]; then
                ppid_val="${value:-}"
                break
            fi
        done < "$pid_dir/status"
        [[ "$ppid_val" == "1" ]] && continue

        loginuid_pids["$session_user"]+="$pid_num "
    done

    # Resolve each live sshd process to the remote peer IP it's actually talking to, so
    # that several processes/channels belonging to the SAME physical connection (common
    # with some tunneling clients - e.g. one process per forwarded port) collapse into a
    # single online session below, instead of being counted - and enforced against the
    # connection limit - separately.
    #
    # REMOVED: this server relays the tunneled client's own internet traffic (SSH dynamic
    # port forwarding), so a single login's sshd process legitimately holds MANY established
    # TCP connections - one per website/app the tunneled device happens to be using right
    # now (Google, a CDN, a chat app, ads...). Grouping by peer IP was actually counting
    # those unrelated destination servers as if they were separate client connections,
    # which could push online_count above the real limit for a SINGLE legitimate session
    # and get it killed/locked by the enforcement below. A login = one sshd process; see
    # unique_pids just below, which already gives the correct count on its own.

    while read -r passwd_user _ passwd_status _rest; do
        [[ "$passwd_status" == "L" ]] && locked_users["$passwd_user"]=1
    done < <(passwd -Sa 2>/dev/null)

    if [[ -f "/etc/novaxtunnel/banners_enabled" ]]; then
        mkdir -p "$BANNER_DIR"
        dynamic_banners_enabled=true
    fi

    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" || "$user" == \#* ]] && continue

        declare -A unique_pids=()
        for pid in ${session_pids["$user"]} ${loginuid_pids["$user"]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done

        # online_count (used for the connection-limit enforcement AND the banner display
        # below) counts DISTINCT SSHD SESSION PROCESSES - each entry in unique_pids is one
        # real login (see session_pids/loginuid_pids above). This is the actual number of
        # open connections against the account's limit, independent of how many outbound
        # destinations that session's tunneled traffic happens to be touching right now.
        online_count=${#unique_pids[@]}
        user_locked=false
        if [[ -n "${locked_users[$user]+x}" ]]; then
            user_locked=true
        fi

        expiry_ts=0
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    killall -u "$user" -9 &>/dev/null
                    locked_users["$user"]=1
                fi
                continue
            fi
        fi

        [[ "$limit" =~ ^[0-9]+$ ]] || limit=1
        if (( online_count > limit )); then
            if ! $user_locked; then
                usermod -L "$user" &>/dev/null
                killall -u "$user" -9 &>/dev/null
                (sleep 120; usermod -U "$user" &>/dev/null) &
                locked_users["$user"]=1
                user_locked=true
            else
                killall -u "$user" -9 &>/dev/null
            fi
        fi

        if $dynamic_banners_enabled; then
            days_left="N/A"
            if [[ "$expiry" != "Never" && -n "$expiry" && "$expiry_ts" =~ ^[0-9]+$ && $expiry_ts -gt 0 ]]; then
                diff_secs=$((expiry_ts - current_ts))
                if (( diff_secs <= 0 )); then
                    days_left="EXPIRED"
                else
                    d_l=$(( diff_secs / 86400 ))
                    h_l=$(( (diff_secs % 86400) / 3600 ))
                    if (( d_l == 0 )); then
                        days_left="${h_l}h left"
                    else
                        days_left="${d_l}d ${h_l}h"
                    fi
                fi
            fi

            bw_info="Unlimited"
            if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
                usagefile="$BW_DIR/${user}.usage"
                accum_disp=0
                if [[ -f "$usagefile" ]]; then
                    read -r accum_disp < "$usagefile"
                    [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0
                fi
                used_gb=$(awk "BEGIN {printf \"%.2f\", $accum_disp / 1073741824}")
                remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
                bw_info="${used_gb}/${bandwidth_gb} GB used | ${remain_gb} GB left"
            fi

            banner_content="<br><font color=\"yellow\"><b>      ✨ ACCOUNT STATUS ✨      </b></font><br><br>"
            banner_content+="<font color=\"white\">👤 <b>Username   :</b> $user</font><br>"
            banner_content+="<font color=\"white\">📅 <b>Expiration :</b> $expiry ($days_left)</font><br>"
            banner_content+="<font color=\"white\">📊 <b>Bandwidth  :</b> $bw_info</font><br>"
            banner_content+="<font color=\"white\">🔌 <b>Sessions   :</b> $online_count/$limit</font><br><br>"
            write_banner_if_changed "$user" "$banner_content"
        fi

        [[ -z "$bandwidth_gb" || "$bandwidth_gb" == "0" ]] && continue

        usagefile="$BW_DIR/${user}.usage"
        accumulated=0
        if [[ -f "$usagefile" ]]; then
            read -r accumulated < "$usagefile"
            [[ "$accumulated" =~ ^[0-9]+$ ]] || accumulated=0
        fi

        if (( ${#unique_pids[@]} == 0 )); then
            rm -f "$PID_DIR/${user}__"*.last 2>/dev/null
            continue
        fi

        delta_total=0
        for pid in "${!unique_pids[@]}"; do
            io_file="/proc/$pid/io"
            cur=0
            if [[ -r "$io_file" ]]; then
                rchar=0
                wchar=0
                while read -r key value; do
                    case "$key" in
                        rchar:) rchar=${value:-0} ;;
                        wchar:) wchar=${value:-0} ;;
                    esac
                done < "$io_file"
                cur=$((rchar + wchar))
            fi

            pidfile="$PID_DIR/${user}__${pid}.last"
            if [[ -f "$pidfile" ]]; then
                read -r prev < "$pidfile"
                [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
                if (( cur >= prev )); then
                    d=$((cur - prev))
                else
                    d=$cur
                fi
                delta_total=$((delta_total + d))
            fi
            printf "%s\n" "$cur" > "$pidfile"
        done

        for f in "$PID_DIR/${user}__"*.last; do
            [[ -f "$f" ]] || continue
            fpid=${f##*__}
            fpid=${fpid%.last}
            [[ -d "/proc/$fpid" ]] || rm -f "$f"
        done

        new_total=$((accumulated + delta_total))
        printf "%s\n" "$new_total" > "$usagefile"

        quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        if [[ "$quota_bytes" =~ ^[0-9]+$ ]] && (( new_total >= quota_bytes )); then
            if ! $user_locked; then
                usermod -L "$user" &>/dev/null
                killall -u "$user" -9 &>/dev/null
                locked_users["$user"]=1
            fi
        fi
    done < "$DB_FILE"

    sleep "$SCAN_INTERVAL"
done
EOF
    chmod +x "$LIMITER_SCRIPT"
    # Strip DOS line endings in case menu.sh was uploaded from Windows
    sed -i 's/\r$//' "$LIMITER_SCRIPT" 2>/dev/null

    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=NOVA XTUNNEL Active User Limiter
After=network.target

[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always
RestartSec=10
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7

[Install]
WantedBy=multi-user.target
EOF
    sed -i 's/\r$//' "$LIMITER_SERVICE" 2>/dev/null

    pkill -f "novaxtunnel-limiter" 2>/dev/null

    if ! systemctl is-active --quiet novaxtunnel-limiter; then
        systemctl daemon-reload
        systemctl enable novaxtunnel-limiter &>/dev/null
        systemctl start novaxtunnel-limiter --no-block &>/dev/null
        
    else
        systemctl restart novaxtunnel-limiter --no-block &>/dev/null
        
    fi
}

sync_runtime_components_if_needed() {
    local limiter_marker="# NOVA XTUNNEL limiter version 2026-04-05.1"
    cleanup_legacy_bandwidth_runtime
    ensure_ssh_client_alive_config
    if [[ ! -f "$LIMITER_SCRIPT" ]] || ! grep -Fqx "$limiter_marker" "$LIMITER_SCRIPT" 2>/dev/null; then
        setup_limiter_service >/dev/null 2>&1
    fi
    if [[ -f "$BADVPN_SERVICE_FILE" ]]; then
        ensure_badvpn_service_is_quiet
    fi
    if [[ -f "/etc/novaxtunnel/banners_enabled" ]]; then
        update_ssh_banners_config
    elif [[ -f "$SSHD_FF_CONFIG" ]]; then
        disable_dynamic_ssh_banner_system
        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null || true
    fi
}

SSHD_FF_KEEPALIVE_CONFIG="/etc/ssh/sshd_config.d/novaxtunnel-keepalive.conf"

# Makes sshd send a protocol-level "are you still there?" probe to each client every 15s,
# and drop the session if it misses 3 in a row (~45s). Without this, a client that loses
# network (common on mobile: tower handoff, app backgrounded, poor signal) leaves its old
# sshd session sitting as ESTABLISHED indefinitely - TCPKeepAlive alone relies on the
# kernel's default probe timers, which are typically hours. Those stale "ghost" sessions
# were exactly what made a 1-person account show "2/2 online" (an old dead session plus
# the real new one) and get locked out by the connection-limit enforcement.
ensure_ssh_client_alive_config() {
    if [[ ! -f "$SSHD_FF_KEEPALIVE_CONFIG" ]] || ! grep -q "^ClientAliveInterval 15" "$SSHD_FF_KEEPALIVE_CONFIG" 2>/dev/null; then
        mkdir -p /etc/ssh/sshd_config.d
        cat > "$SSHD_FF_KEEPALIVE_CONFIG" << 'EOF'
# Managed by NOVA XTUNNEL - detects and drops dead/ghost SSH sessions quickly
# (e.g. mobile clients that lost network without a clean disconnect), so the
# online/connection-limit count reflects reality instead of counting stale sessions.
ClientAliveInterval 15
ClientAliveCountMax 3
EOF
        if ! grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
            echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        fi
        if sshd -t 2>/dev/null; then
            systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
        fi
    fi
}

setup_bandwidth_service() {

    mkdir -p "$BANDWIDTH_DIR"
    # Bandwidth monitoring is now integrated into the limiter service above.
    cleanup_legacy_bandwidth_runtime
}

cleanup_legacy_bandwidth_runtime() {
    local needs_reload=false

    systemctl stop novaxtunnel-bandwidth &>/dev/null || true
    systemctl disable novaxtunnel-bandwidth &>/dev/null || true
    pkill -f "novaxtunnel-bandwidth" &>/dev/null || true

    if [[ -e "$BANDWIDTH_SERVICE" || -e "$BANDWIDTH_SCRIPT" || -e "$LEGACY_BANDWIDTH_DIR" ]]; then
        rm -f "$BANDWIDTH_SERVICE" "$BANDWIDTH_SCRIPT" 2>/dev/null
        rm -rf "$LEGACY_BANDWIDTH_DIR" 2>/dev/null
        needs_reload=true
    fi

    if $needs_reload; then
        systemctl daemon-reload &>/dev/null || true
    fi
}

setup_trial_cleanup_script() {
    cat > "$TRIAL_CLEANUP_SCRIPT" << 'TREOF'
#!/bin/bash
# NOVA XTUNNEL Trial Account Auto-Cleanup
# Usage: novaxtunnel-trial-cleanup.sh <username>
DB_FILE="/etc/novaxtunnel/users.db"
BW_DIR="/etc/novaxtunnel/bandwidth"

username="$1"
if [[ -z "$username" ]]; then exit 1; fi

# Kill active sessions
killall -u "$username" -9 &>/dev/null
sleep 1

# Delete system user
userdel -r "$username" &>/dev/null

# Remove from DB
sed -i "/^${username}:/d" "$DB_FILE"

# Remove bandwidth tracking
rm -f "$BW_DIR/${username}.usage"
rm -rf "$BW_DIR/pidtrack/${username}"
TREOF
    chmod +x "$TRIAL_CLEANUP_SCRIPT"
}

disable_dynamic_ssh_banner_system() {
    rm -f "/etc/novaxtunnel/banners_enabled" "$SSHD_FF_CONFIG" /usr/local/bin/novaxtunnel-login-info.sh 2>/dev/null
    rm -rf "/etc/novaxtunnel/banners" 2>/dev/null
    invalidate_banner_cache
}

disable_static_ssh_banner_in_sshd_config() {
    sed -i.bak -E "s|^[[:space:]]*Banner[[:space:]]+$SSH_BANNER_FILE[[:space:]]*$|# Banner $SSH_BANNER_FILE|" /etc/ssh/sshd_config 2>/dev/null
}

is_static_ssh_banner_enabled() {
    grep -q -E "^[[:space:]]*Banner[[:space:]]+$SSH_BANNER_FILE[[:space:]]*$" /etc/ssh/sshd_config 2>/dev/null && [ -f "$SSH_BANNER_FILE" ]
}

is_dynamic_ssh_banner_enabled() {
    [[ -f "/etc/novaxtunnel/banners_enabled" && -f "$SSHD_FF_CONFIG" ]]
}

get_ssh_banner_mode() {
    if is_dynamic_ssh_banner_enabled; then
        echo "dynamic"
    elif is_static_ssh_banner_enabled; then
        echo "static"
    else
        echo "disabled"
    fi
}

refresh_dynamic_banner_routing_if_enabled() {
    if is_dynamic_ssh_banner_enabled; then
        update_ssh_banners_config
    fi
}

update_ssh_banners_config() {
    local tmp_conf

    if [[ ! -f "/etc/novaxtunnel/banners_enabled" ]]; then
        if [[ -f "$SSHD_FF_CONFIG" ]]; then
            rm -f "$SSHD_FF_CONFIG" 2>/dev/null
            systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
        fi
        return
    fi

    ensure_novaxtunnel_dirs
    tmp_conf="/tmp/ff_banners_new.conf"
    echo "# NOVA XTUNNEL - Dynamic per-user SSH banners" > "$tmp_conf"

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r u _rest; do
            [[ -z "$u" || "$u" == \#* ]] && continue
            echo "Match User $u" >> "$tmp_conf"
            echo "    Banner /etc/novaxtunnel/banners/${u}.txt" >> "$tmp_conf"
        done < "$DB_FILE"
    fi

    if ! cmp -s "$tmp_conf" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp_conf" "$SSHD_FF_CONFIG"
        if ! grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
            echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        fi
        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    else
        rm -f "$tmp_conf"
    fi
}

setup_ssh_login_info() {
    ensure_novaxtunnel_dirs || return 1
    if ! touch "/etc/novaxtunnel/banners_enabled"; then
        echo -e "${C_RED}❌ Failed to enable dynamic SSH banners.${C_RESET}"
        return 1
    fi
    disable_static_ssh_banner_in_sshd_config
    update_ssh_banners_config
    return 0
}


generate_dns_record() {
    echo -e "\n${C_BLUE}⚙️ Generating a random domain...${C_RESET}"
    if ! command -v jq &> /dev/null; then
        echo -e "${C_YELLOW}⚠️ jq not found, attempting to install...${C_RESET}"
        ff_apt_install jq >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to install jq. Cannot manage DNS records.${C_RESET}"
            return 1
        }
    fi
    local SERVER_IPV4
    SERVER_IPV4=$(curl -s -4 icanhazip.com)
    if ! _is_valid_ipv4 "$SERVER_IPV4"; then
        echo -e "\n${C_RED}❌ Error: Could not retrieve a valid public IPv4 address from icanhazip.com.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Please check your server's network connection and DNS resolver settings.${C_RESET}"
        echo -e "   Output received: '$SERVER_IPV4'"
        return 1
    fi

    local SERVER_IPV6
    SERVER_IPV6=$(curl -s -6 icanhazip.com --max-time 5)

    local RANDOM_SUBDOMAIN="vps-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    local FULL_DOMAIN="$RANDOM_SUBDOMAIN.$DESEC_DOMAIN"
    local HAS_IPV6="false"

    local API_DATA
    API_DATA=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$RANDOM_SUBDOMAIN" "$SERVER_IPV4")

    if [[ -n "$SERVER_IPV6" ]]; then
        local aaaa_record
        aaaa_record=$(printf ',{"subname": "%s", "type": "AAAA", "ttl": 3600, "records": ["%s"]}' "$RANDOM_SUBDOMAIN" "$SERVER_IPV6")
        API_DATA="${API_DATA%?}${aaaa_record}]"
        HAS_IPV6="true"
    fi

    local CREATE_RESPONSE
    CREATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" \
        --data "$API_DATA")
    
    local HTTP_CODE=${CREATE_RESPONSE: -3}
    local RESPONSE_BODY=${CREATE_RESPONSE:0:${#CREATE_RESPONSE}-3}

    if [[ "$HTTP_CODE" -ne 201 ]]; then
        echo -e "${C_RED}❌ Failed to create DNS records. API returned HTTP $HTTP_CODE.${C_RESET}"
        if ! echo "$RESPONSE_BODY" | jq . > /dev/null 2>&1; then
            echo "Raw Response: $RESPONSE_BODY"
        else
            echo "Response: $RESPONSE_BODY" | jq
        fi
        return 1
    fi
    
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$RANDOM_SUBDOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
HAS_IPV6="$HAS_IPV6"
EOF
    echo -e "\n${C_GREEN}✅ Successfully created domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
}

delete_dns_record() {
    if [ ! -f "$DNS_INFO_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No domain to delete.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}🗑️ Deleting DNS records...${C_RESET}"
    source "$DNS_INFO_FILE"
    if [[ -z "$SUBDOMAIN" ]]; then
        echo -e "${C_RED}❌ Could not read record details from config file. Skipping deletion.${C_RESET}"
        return
    fi

    curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" \
         -H "Authorization: Token $DESEC_TOKEN" > /dev/null

    if [[ "$HAS_IPV6" == "true" ]]; then
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/AAAA/" \
             -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    fi

    echo -e "\n${C_GREEN}✅ Deleted domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
    rm -f "$DNS_INFO_FILE"
}

dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Domain Management ---${C_RESET}"
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "\nℹ️ A domain already exists for this server:"
        echo -e "  - ${C_CYAN}Domain:${C_RESET} ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        echo
        read -p "👉 Do you want to DELETE this domain? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            delete_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        fi
    else
        echo -e "\nℹ️ No domain has been generated for this server yet."
        echo
        read -p "👉 Do you want to generate a new random domain now? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            generate_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        fi
    fi
}

_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found in the database.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    local -A all_user_lookup=()
    local username
    for username in "${all_users[@]}"; do
        all_user_lookup["$username"]=1
    done
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter a search term (or press Enter to list all): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No users found matching your criteria.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    echo -e "\nPlease select a user:\n"
    for i in "${!users[@]}"; do
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"
    done
    echo -e "\n  ${C_RED} [ 0]${C_RESET} ↩️ Cancel and return to main menu"
    echo -e "${C_CYAN}💡 Tip: you can also type the exact username directly.${C_RESET}"
    echo
    local choice
    while true; do
        if ! read -r -p "👉 Enter the number or exact username: " choice; then
            echo
            SELECTED_USER=""
            return
        fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#users[@]}" ]; then
            if [ "$choice" -eq 0 ]; then
                SELECTED_USER=""; return
            else
                SELECTED_USER="${users[$((choice-1))]}"; return
            fi
        elif [[ -n "${all_user_lookup[$choice]+x}" ]]; then
            SELECTED_USER="$choice"; return
        else
            echo -e "${C_RED}❌ Invalid selection. Please try again.${C_RESET}"
        fi
    done
}

_select_multi_user_interface() {
    local title="$1"
    local include_orphan_users="${2:-false}"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    SELECTED_USERS=()
    local -a all_users=()
    local -a orphan_users=()
    local -A all_user_lookup=()
    local -A orphan_user_lookup=()
    local username

    if [[ -s $DB_FILE ]]; then
        mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    fi

    if [[ "$include_orphan_users" == "true" ]]; then
        mapfile -t orphan_users < <(get_novaxtunnel_orphan_users)
        for username in "${orphan_users[@]}"; do
            orphan_user_lookup["$username"]=1
            if ! printf "%s\n" "${all_users[@]}" | grep -Fxq "$username"; then
                all_users+=("$username")
            fi
        done
        if [[ ${#all_users[@]} -gt 0 ]]; then
            mapfile -t all_users < <(printf "%s\n" "${all_users[@]}" | sort)
        fi
    fi

    if [[ ${#all_users[@]} -eq 0 ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found in the manager database.${C_RESET}"
        if [[ "$include_orphan_users" == "true" ]]; then
            echo -e "${C_DIM}No orphan NOVA XTUNNEL system users were found either.${C_RESET}"
        fi
        SELECTED_USERS=("NO_USERS"); return
    fi

    for username in "${all_users[@]}"; do
        all_user_lookup["$username"]=1
    done
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter a search term (or press Enter to list all): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No users found matching your criteria.${C_RESET}"
        SELECTED_USERS=("NO_USERS"); return
    fi
    echo -e "\nPlease select users:\n"
    for i in "${!users[@]}"; do
        local display_user="${users[$i]}"
        if [[ "$include_orphan_users" == "true" && -n "${orphan_user_lookup[${users[$i]}]+x}" ]]; then
            display_user="${display_user} ${C_DIM}(system-only)${C_RESET}"
        fi
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "$display_user"
    done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Select ALL listed users"
    echo -e "  ${C_RED}  [0]${C_RESET} ↩️ Cancel and return to main menu"
    echo -e "\n${C_CYAN}💡 You can select multiple by number, range, or exact username.${C_RESET}"
    echo -e "${C_CYAN}   Examples: '1 3 5' or '1,3' or '1-4' or 'alice bob'${C_RESET}"
    if [[ "$include_orphan_users" == "true" ]]; then
        echo -e "${C_CYAN}   Users marked '(system-only)' are old accounts still on the VPS but missing from users.db${C_RESET}"
    fi
    echo
    local choice
    while true; do
        if ! read -r -p "👉 Enter user numbers or usernames: " choice; then
            echo
            SELECTED_USERS=()
            return
        fi
        choice=$(echo "$choice" | tr ',' ' ') # Replace commas with spaces
        
        if [[ -z "$choice" ]]; then
            echo -e "${C_RED}❌ Invalid selection. Please try again.${C_RESET}"
            continue
        fi

        if [[ "$choice" == "0" ]]; then
            SELECTED_USERS=(); return
        fi
        
        if [[ "${choice,,}" == "all" ]]; then
            SELECTED_USERS=("${users[@]}")
            return
        fi
        
        local valid=true
        local selected_indices=()
        local selected_names=()
        for token in $choice; do
            if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
                local start=${token%-*}
                local end=${token#*-}
                if [ "$start" -le "$end" ]; then
                    for (( idx=start; idx<=end; idx++ )); do
                        if [ "$idx" -ge 1 ] && [ "$idx" -le "${#users[@]}" ]; then
                            selected_indices+=($idx)
                        else
                            valid=false; break
                        fi
                    done
                else
                    valid=false; break
                fi
            elif [[ "$token" =~ ^[0-9]+$ ]]; then
                if [ "$token" -ge 1 ] && [ "$token" -le "${#users[@]}" ]; then
                    selected_indices+=($token)
                elif [[ -n "${all_user_lookup[$token]+x}" ]]; then
                    selected_names+=("$token")
                else
                    valid=false; break
                fi
            elif [[ -n "${all_user_lookup[$token]+x}" ]]; then
                selected_names+=("$token")
            else
                valid=false; break
            fi
        done
        
        if [[ "$valid" == true && ( ${#selected_indices[@]} -gt 0 || ${#selected_names[@]} -gt 0 ) ]]; then
            mapfile -t unique_indices < <(printf "%s\n" "${selected_indices[@]}" | sort -u -n)
            for idx in "${unique_indices[@]}"; do
                SELECTED_USERS+=("${users[$((idx-1))]}")
            done
            mapfile -t unique_names < <(printf "%s\n" "${selected_names[@]}" | sort -u)
            for username in "${unique_names[@]}"; do
                if ! printf "%s\n" "${SELECTED_USERS[@]}" | grep -Fxq "$username"; then
                    SELECTED_USERS+=("$username")
                fi
            done
            return
        else
            echo -e "${C_RED}❌ Invalid selection. Please check your numbers or usernames.${C_RESET}"
            SELECTED_USERS=()
            selected_indices=()
            selected_names=()
        fi
    done
}

get_user_status() {
    local username="$1"
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}Not Found${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; fi
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    if [[ $expiry_ts -lt $current_ts ]]; then echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; fi
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Enter username (or '0' to cancel): " username
    local adopt_existing=false
    if [[ "$username" == "0" ]]; then
        echo -e "\n${C_YELLOW}❌ User creation cancelled.${C_RESET}"
        return
    fi
    if [[ -z "$username" ]]; then
        echo -e "\n${C_RED}❌ Error: Username cannot be empty.${C_RESET}"
        return
    fi
    if db_has_user "$username"; then
        echo -e "\n${C_RED}❌ Error: User '$username' already exists in NOVA XTUNNEL.${C_RESET}"
        return
    fi
    if id "$username" &>/dev/null; then
        if is_novaxtunnel_orphan_user "$username"; then
            echo -e "\n${C_YELLOW}⚠️ User '$username' already exists on the system but is missing from users.db.${C_RESET}"
            echo -e "${C_DIM}This usually happens after uninstalling the script without deleting the SSH users.${C_RESET}"
            read -p "👉 Do you want to take control of this existing user and manage it with NOVA XTUNNEL? (y/n): " adopt_confirm
            if [[ "$adopt_confirm" == "y" || "$adopt_confirm" == "Y" ]]; then
                adopt_existing=true
            else
                echo -e "\n${C_YELLOW}❌ User creation cancelled.${C_RESET}"
                return
            fi
        else
            echo -e "\n${C_RED}❌ Error: System user '$username' already exists and does not look like a NOVA XTUNNEL SSH account.${C_RESET}"
            return
        fi
    fi
    local password=""
    while true; do
        read -p "🔑 Enter password (or press Enter for auto-generated): " password
        if [[ -z "$password" ]]; then
            password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
            echo -e "${C_GREEN}🔑 Auto-generated password: ${C_YELLOW}$password${C_RESET}"
            break
        else
            break
        fi
    done
    read -p "🗓️ Enter account duration (in days) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📶 Enter simultaneous connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📦 Enter bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    local expire_date
    expire_date=$(date -d "+$days days" +%Y-%m-%d)
    ensure_novaxtunnel_system_group
    if [[ "$adopt_existing" == "true" ]]; then
        usermod -s /usr/sbin/nologin "$username" &>/dev/null
    else
        useradd -m -s /usr/sbin/nologin "$username"
    fi
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd; chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
    
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    
    clear; show_banner
    if [[ "$adopt_existing" == "true" ]]; then
        echo -e "${C_GREEN}✅ Existing system user '$username' has been imported into NOVA XTUNNEL!${C_RESET}\n"
    else
        echo -e "${C_GREEN}✅ User '$username' created successfully!${C_RESET}\n"
    fi
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - 🗓️ Expires on:        ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Bandwidth Limit:   ${C_YELLOW}$bw_display${C_RESET}"
    echo -e "    ${C_DIM}(Active monitoring service will enforce these limits)${C_RESET}"

    # Auto-ask for config generation
    echo
    read -p "👉 Do you want to generate a client connection config for this user? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete NOVA XTUNNEL Users ---" "true"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_RED}⚠️ You selected ${#SELECTED_USERS[@]} user(s) to delete: ${C_YELLOW}${SELECTED_USERS[*]}${C_RESET}"
    read -p "👉 Are you sure you want to PERMANENTLY delete them? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "\n${C_YELLOW}❌ Deletion cancelled.${C_RESET}"; return; fi
    
    echo -e "\n${C_BLUE}🗑️ Deleting selected users...${C_RESET}"
    delete_novaxtunnel_user_accounts "${SELECTED_USERS[@]}"
}

edit_user() {
    _select_user_interface "--- ✏️ Edit a User ---"
    local username=$SELECTED_USER
    if [[ "$username" == "NO_USERS" ]] || [[ -z "$username" ]]; then return; fi
    while true; do
        clear; show_banner; echo -e "${C_BOLD}${C_PURPLE}--- Editing User: ${C_YELLOW}$username${C_PURPLE} ---${C_RESET}"
        
        # Show current user details
        local current_line; current_line=$(grep "^$username:" "$DB_FILE")
        local cur_pass; cur_pass=$(echo "$current_line" | cut -d: -f2)
        local cur_expiry; cur_expiry=$(echo "$current_line" | cut -d: -f3)
        local cur_limit; cur_limit=$(echo "$current_line" | cut -d: -f4)
        local cur_bw; cur_bw=$(echo "$current_line" | cut -d: -f5)
        [[ -z "$cur_bw" ]] && cur_bw="0"
        local cur_bw_display="Unlimited"; [[ "$cur_bw" != "0" ]] && cur_bw_display="${cur_bw} GB"
        
        # Show bandwidth usage
        local bw_used_display="N/A"
        if [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
            local used_bytes; used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null)
            if [[ -n "$used_bytes" && "$used_bytes" != "0" ]]; then
                bw_used_display=$(awk "BEGIN {printf \"%.2f GB\", $used_bytes / 1073741824}")
            else
                bw_used_display="0.00 GB"
            fi
        fi
        
        echo -e "\n  ${C_DIM}Current: Pass=${C_YELLOW}$cur_pass${C_RESET}${C_DIM} Exp=${C_YELLOW}$cur_expiry${C_RESET}${C_DIM} Conn=${C_YELLOW}$cur_limit${C_RESET}${C_DIM} BW=${C_YELLOW}$cur_bw_display${C_RESET}${C_DIM} Used=${C_CYAN}$bw_used_display${C_RESET}"
        echo -e "\nSelect a detail to edit:\n"
        printf "  ${C_GREEN}[ 1]${C_RESET} %-35s\n" "🔑 Change Password"
        printf "  ${C_GREEN}[ 2]${C_RESET} %-35s\n" "🗓️ Change Expiration Date"
        printf "  ${C_GREEN}[ 3]${C_RESET} %-35s\n" "📶 Change Connection Limit"
        printf "  ${C_GREEN}[ 4]${C_RESET} %-35s\n" "📦 Change Bandwidth Limit"
        printf "  ${C_GREEN}[ 5]${C_RESET} %-35s\n" "🔄 Reset Bandwidth Counter"
        echo -e "\n  ${C_RED}[ 0]${C_RESET} ✅ Finish Editing"
        echo
        if ! read -r -p "👉 Enter your choice: " edit_choice; then
            echo
            return
        fi
        case $edit_choice in
            1)
               local new_pass=""
               read -p "Enter new password (or press Enter for auto-generated): " new_pass
               if [[ -z "$new_pass" ]]; then
                   new_pass=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
                   echo -e "${C_GREEN}🔑 Auto-generated: ${C_YELLOW}$new_pass${C_RESET}"
               fi
               echo "$username:$new_pass" | chpasswd
               sed -i "s/^$username:.*/$username:$new_pass:$cur_expiry:$cur_limit:$cur_bw/" "$DB_FILE"
               echo -e "\n${C_GREEN}✅ Password for '$username' changed to: ${C_YELLOW}$new_pass${C_RESET}"
               ;;
            2) read -p "Enter new duration (in days from today): " days
               if [[ "$days" =~ ^[0-9]+$ ]]; then
                   local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d); chage -E "$new_expire_date" "$username"
                   sed -i "s/^$username:.*/$username:$cur_pass:$new_expire_date:$cur_limit:$cur_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Expiration for '$username' set to ${C_YELLOW}$new_expire_date${C_RESET}."
               else echo -e "\n${C_RED}❌ Invalid number of days.${C_RESET}"; fi ;;
            3) read -p "Enter new simultaneous connection limit: " new_limit
               if [[ "$new_limit" =~ ^[0-9]+$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$new_limit:$cur_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Connection limit for '$username' set to ${C_YELLOW}$new_limit${C_RESET}."
               else echo -e "\n${C_RED}❌ Invalid limit.${C_RESET}"; fi ;;
            4) read -p "Enter new bandwidth limit in GB (0 = unlimited): " new_bw
               if [[ "$new_bw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$new_bw/" "$DB_FILE"
                   local bw_msg="Unlimited"; [[ "$new_bw" != "0" ]] && bw_msg="${new_bw} GB"
                   echo -e "\n${C_GREEN}✅ Bandwidth limit for '$username' set to ${C_YELLOW}$bw_msg${C_RESET}."
                   # Unlock user if they were locked due to bandwidth
                   if [[ "$new_bw" == "0" ]] || [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
                       local used_bytes; used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null || echo 0)
                       local new_quota_bytes; new_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $new_bw * 1073741824}")
                       if [[ "$new_bw" == "0" ]] || [[ "$used_bytes" -lt "$new_quota_bytes" ]]; then
                           usermod -U "$username" &>/dev/null
                       fi
                   fi
               else echo -e "\n${C_RED}❌ Invalid bandwidth value.${C_RESET}"; fi ;;
            5)
               echo "0" > "$BANDWIDTH_DIR/${username}.usage"
               # Unlock user if they were locked due to bandwidth
               usermod -U "$username" &>/dev/null
               echo -e "\n${C_GREEN}✅ Bandwidth counter for '$username' has been reset to 0.${C_RESET}"
               ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" ;;
        esac
        echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue editing..." && read -r || return
    done
}

lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users (from DB) ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔒 Locking selected users...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ User '${C_YELLOW}$u${C_RESET}' does not exist on this system."
             continue
        fi
        
        usermod -L "$u"
        if [ $? -eq 0 ]; then
            killall -u "$u" -9 &>/dev/null
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} locked and active sessions killed."
        else
            echo -e " ❌ Failed to lock ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users (from DB) ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔓 Unlocking selected users...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ User '${C_YELLOW}$u${C_RESET}' does not exist on this system."
             continue
        fi
        
        usermod -U "$u"
        if [ $? -eq 0 ]; then
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} unlocked."
        else
            echo -e " ❌ Failed to unlock ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

list_users() {
    clear; show_banner
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_YELLOW}ℹ️ No users are currently being managed.${C_RESET}"
        return
    fi
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Managed Users ---${C_RESET}"
    echo -e "${C_CYAN}=========================================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-18s | %-12s | %-10s | %-15s | %-20s${C_RESET}\n" "USERNAME" "EXPIRES" "CONNS" "BANDWIDTH" "STATUS"
    echo -e "${C_CYAN}-----------------------------------------------------------------------------------------${C_RESET}"

    local current_ts
    current_ts=$(date +%s)
    local -A system_user_lookup=()
    local -A locked_user_lookup=()

    while IFS=: read -r system_user _rest; do
        [[ -n "$system_user" ]] && system_user_lookup["$system_user"]=1
    done < /etc/passwd

    while read -r passwd_user _ passwd_status _rest; do
        [[ -z "$passwd_user" ]] && continue
        if [[ "$passwd_status" == "L" ]]; then
            locked_user_lookup["$passwd_user"]=1
        fi
    done < <(passwd -Sa 2>/dev/null)
    refresh_ssh_session_cache

    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        local online_count="${SSH_SESSION_COUNTS[$user]:-0}"
        local connection_string="$online_count / $limit"
        local plain_status="Active"
        local status="${C_GREEN}🟢 Active${C_RESET}"
        local quota_exceeded=false

        [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
        local bw_string="Unlimited"
        if [[ "$bandwidth_gb" != "0" ]]; then
            local used_bytes=0
            if [[ -f "$BANDWIDTH_DIR/${user}.usage" ]]; then
                used_bytes=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null)
                [[ "$used_bytes" =~ ^[0-9]+$ ]] || used_bytes=0
            fi
            local used_gb
            used_gb=$(awk "BEGIN {printf \"%.1f\", $used_bytes / 1073741824}")
            bw_string="${used_gb}/${bandwidth_gb}GB"
            local quota_bytes
            quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
            if [[ "$quota_bytes" =~ ^[0-9]+$ ]] && (( used_bytes >= quota_bytes )); then
                quota_exceeded=true
            fi
        fi

        if [[ -z "${system_user_lookup[$user]+x}" ]]; then
            plain_status="Not Found"
            status="${C_RED}Not Found${C_RESET}"
        elif [[ -n "$expiry" && "$expiry" != "Never" ]]; then
            local expiry_ts
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                plain_status="Expired"
                status="${C_RED}🗓️ Expired${C_RESET}"
            fi
        fi

        if [[ "$plain_status" == "Active" && "$quota_exceeded" == true ]]; then
            if [[ -n "${locked_user_lookup[$user]+x}" ]]; then
                plain_status="BW Locked"
                status="${C_RED}🔒 BW Locked${C_RESET}"
            else
                plain_status="Quota Exceeded"
                status="${C_RED}📦 Quota Exceeded${C_RESET}"
            fi
        elif [[ "$plain_status" == "Active" && -n "${locked_user_lookup[$user]+x}" ]]; then
            plain_status="Locked"
            status="${C_YELLOW}🔒 Locked${C_RESET}"
        fi

        local line_color="$C_WHITE"
        case "$plain_status" in
            "Active") line_color="$C_GREEN" ;;
            "Locked") line_color="$C_YELLOW" ;;
            "Expired") line_color="$C_RED" ;;
            "BW Locked") line_color="$C_RED" ;;
            "Quota Exceeded") line_color="$C_RED" ;;
            "Not Found") line_color="$C_DIM" ;;
        esac

        printf "${line_color}%-18s ${C_RESET}| ${C_YELLOW}%-12s ${C_RESET}| ${C_CYAN}%-10s ${C_RESET}| ${C_ORANGE}%-15s ${C_RESET}| %-20s\n" "$user" "$expiry" "$connection_string" "$bw_string" "$status"
    done < <(sort "$DB_FILE")
    echo -e "${C_CYAN}=========================================================================================${C_RESET}\n"
}

renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    read -p "👉 Enter number of days to extend the account(s): " days; if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d)
    
    echo -e "\n${C_BLUE}🔄 Renewing selected users for $days days...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$new_expire_date" "$u"
        local line; line=$(grep "^$u:" "$DB_FILE"); local pass; pass=$(echo "$line"|cut -d: -f2); local limit; limit=$(echo "$line"|cut -d: -f4); local bw; bw=$(echo "$line"|cut -d: -f5)
        [[ -z "$bw" ]] && bw="0"
        sed -i "s/^$u:.*/$u:$pass:$new_expire_date:$limit:$bw/" "$DB_FILE"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} renewed until ${C_GREEN}${new_expire_date}${C_RESET}."
    done
}

cleanup_expired() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧹 Cleanup Expired Users ---${C_RESET}"
    
    local expired_users=()
    local current_ts
    current_ts=$(date +%s)

    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_GREEN}✅ User database is empty. No expired users found.${C_RESET}"
        return
    fi
    
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        local expiry_ts
        expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        
        if [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]]; then
            expired_users+=("$user")
        fi
    done < "$DB_FILE"

    if [ ${#expired_users[@]} -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ No expired users found.${C_RESET}"
        return
    fi

    echo -e "\nThe following users have expired: ${C_RED}${expired_users[*]}${C_RESET}"
    read -p "👉 Do you want to delete all of them? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        for user in "${expired_users[@]}"; do
            echo " - Deleting ${C_YELLOW}$user...${C_RESET}"
            killall -u "$user" -9 &>/dev/null
            # Clean up bandwidth tracking
            rm -f "$BANDWIDTH_DIR/${user}.usage"
            rm -rf "$BANDWIDTH_DIR/pidtrack/${user}"
            userdel -r "$user" &>/dev/null
            sed -i "/^$user:/d" "$DB_FILE"
        done
        echo -e "\n${C_GREEN}✅ Expired users have been cleaned up.${C_RESET}"
        invalidate_banner_cache
        refresh_dynamic_banner_routing_if_enabled
    else
        echo -e "\n${C_YELLOW}❌ Cleanup cancelled.${C_RESET}"
    fi
}


backup_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💾 Backup User Data ---${C_RESET}"
    read -p "👉 Enter path for backup file [/root/novaxtunnel_users.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/novaxtunnel_users.tar.gz}
    if [ ! -d "$DB_DIR" ] || [ ! -s "$DB_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No user data found to back up.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}⚙️ Backing up user database and settings to ${C_YELLOW}$backup_path${C_RESET}..."
    tar -czf "$backup_path" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")"
    if [ $? -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ SUCCESS: User data backup created at ${C_YELLOW}$backup_path${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: Backup failed.${C_RESET}"
    fi
}

restore_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Restore User Data ---${C_RESET}"
    read -p "👉 Enter the full path to the user data backup file [/root/novaxtunnel_users.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/novaxtunnel_users.tar.gz}
    if [ ! -f "$backup_path" ]; then
        echo -e "\n${C_RED}❌ ERROR: Backup file not found at '$backup_path'.${C_RESET}"
        return
    fi
    echo -e "\n${C_RED}${C_BOLD}⚠️ WARNING:${C_RESET} This will overwrite all current users and settings."
    echo -e "It will restore user accounts, passwords, limits, and expiration dates from the backup file."
    read -p "👉 Are you absolutely sure you want to proceed? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "\n${C_YELLOW}❌ Restore cancelled.${C_RESET}"; return; fi
    local temp_dir
    temp_dir=$(mktemp -d)
    echo -e "\n${C_BLUE}⚙️ Extracting backup file to a temporary location...${C_RESET}"
    tar -xzf "$backup_path" -C "$temp_dir"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ ERROR: Failed to extract backup file. Aborting.${C_RESET}"
        rm -rf "$temp_dir"
        return
    fi
    local restored_root="$temp_dir/$(basename "$DB_DIR")"
    local restored_db_file="$restored_root/users.db"
    if [ ! -f "$restored_db_file" ]; then
        echo -e "\n${C_RED}❌ ERROR: users.db not found in the backup. Cannot restore user accounts.${C_RESET}"
        rm -rf "$temp_dir"
        return
    fi
    echo -e "${C_BLUE}⚙️ Overwriting current user database...${C_RESET}"
    mkdir -p "$DB_DIR"
    cp "$restored_db_file" "$DB_FILE"
    if [ -d "$restored_root/ssl" ]; then
        cp -r "$restored_root/ssl" "$DB_DIR/"
    fi
    if [ -d "$restored_root/dnstt" ]; then
        cp -r "$restored_root/dnstt" "$DB_DIR/"
    fi
    if [ -f "$restored_root/dns_info.conf" ]; then
        cp "$restored_root/dns_info.conf" "$DB_DIR/"
    fi
    if [ -f "$restored_root/dnstt_info.conf" ]; then
        cp "$restored_root/dnstt_info.conf" "$DB_DIR/"
    fi
    if [ -f "$restored_root/falconproxy_config.conf" ]; then
        cp "$restored_root/falconproxy_config.conf" "$DB_DIR/"
    fi
    
    echo -e "${C_BLUE}⚙️ Re-synchronizing system accounts with the restored database...${C_RESET}"
    ensure_novaxtunnel_system_group
    
    while IFS=: read -r user pass expiry limit; do
        echo "Processing user: ${C_YELLOW}$user${C_RESET}"
        if ! id "$user" &>/dev/null; then
            echo " - User does not exist in system. Creating..."
            useradd -m -s /usr/sbin/nologin "$user"
        fi
        usermod -aG "$FF_USERS_GROUP" "$user" 2>/dev/null
        echo " - Setting password..."
        echo "$user:$pass" | chpasswd
        echo " - Setting expiration to $expiry..."
        chage -E "$expiry" "$user"
        echo " - Connection limit is $limit (enforced by PAM)"
    done < "$DB_FILE"
    rm -rf "$temp_dir"
    echo -e "\n${C_GREEN}✅ SUCCESS: User data restore completed.${C_RESET}"
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

_enable_banner_in_sshd_config() {
    echo -e "\n${C_BLUE}⚙️ Configuring sshd_config...${C_RESET}"
    disable_dynamic_ssh_banner_system
    sed -i.bak -E 's/^( *Banner *).*/#\1/' /etc/ssh/sshd_config
    if ! grep -q -E "^Banner $SSH_BANNER_FILE" /etc/ssh/sshd_config; then
        echo -e "\n# NOVA XTUNNEL SSH Banner\nBanner $SSH_BANNER_FILE" >> /etc/ssh/sshd_config
    fi
    echo -e "${C_GREEN}✅ sshd_config updated.${C_RESET}"
}

_restart_ssh() {
    echo -e "\n${C_BLUE}🔄 Restarting SSH service to apply changes...${C_RESET}"
    local ssh_service_name=""
    if [ -f /lib/systemd/system/sshd.service ]; then
        ssh_service_name="sshd.service"
    elif [ -f /lib/systemd/system/ssh.service ]; then
        ssh_service_name="ssh.service"
    else
        echo -e "${C_RED}❌ Could not find sshd.service or ssh.service. Cannot restart SSH.${C_RESET}"
        return 1
    fi

    systemctl restart "${ssh_service_name}"
    if [ $? -eq 0 ]; then
        echo -e "${C_GREEN}✅ SSH service ('${ssh_service_name}') restarted successfully.${C_RESET}"
    else
        echo -e "${C_RED}❌ Failed to restart SSH service ('${ssh_service_name}'). Please check 'journalctl -u ${ssh_service_name}' for errors.${C_RESET}"
    fi
}

set_ssh_banner_paste() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Paste Static SSH Banner ---${C_RESET}"
    echo -e "Paste your custom banner below. Press ${C_YELLOW}[Ctrl+D]${C_RESET} when you are finished."
    echo -e "${C_DIM}This will be shown to all SSH users through 'Banner $SSH_BANNER_FILE'.${C_RESET}"
    echo -e "${C_DIM}The current banner (if any) will be overwritten.${C_RESET}"
    echo -e "--------------------------------------------------"
    cat > "$SSH_BANNER_FILE"
    chmod 644 "$SSH_BANNER_FILE"
    echo -e "\n--------------------------------------------------"
    echo -e "\n${C_GREEN}✅ Static banner content saved.${C_RESET}"
    _enable_banner_in_sshd_config
    _restart_ssh
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
}

view_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👁️ Current SSH Banner ---${C_RESET}"
    if [ -f "$SSH_BANNER_FILE" ]; then
        echo -e "\n${C_CYAN}--- BEGIN BANNER ---${C_RESET}"
        cat "$SSH_BANNER_FILE"
        echo -e "${C_CYAN}---- END BANNER ----${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No banner file found at $SSH_BANNER_FILE.${C_RESET}"
    fi
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
}

remove_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Disable SSH Banners ---${C_RESET}"
    read -p "👉 Are you sure you want to disable all SSH banners? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
        return
    fi
    if [ -f "$SSH_BANNER_FILE" ]; then
        rm -f "$SSH_BANNER_FILE"
        echo -e "\n${C_GREEN}✅ Removed banner file: $SSH_BANNER_FILE${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No banner file to remove.${C_RESET}"
    fi
    disable_dynamic_ssh_banner_system
    echo -e "\n${C_BLUE}⚙️ Disabling banner in sshd_config...${C_RESET}"
    disable_static_ssh_banner_in_sshd_config
    echo -e "${C_GREEN}✅ Banner disabled in configuration.${C_RESET}"
    _restart_ssh
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
}

preview_dynamic_ssh_banner() {
    if ! is_dynamic_ssh_banner_enabled; then
        echo -e "\n${C_RED}❌ Dynamic banners are not enabled right now.${C_RESET}"
        press_enter
        return
    fi

    echo -e "${C_DIM}Refreshing dynamic banner worker...${C_RESET}"
    setup_limiter_service >/dev/null 2>&1
    _select_user_interface "--- 📝 Preview Dynamic Banner ---"
    local u=$SELECTED_USER
    if [[ -z "$u" || "$u" == "NO_USERS" ]]; then
        return
    fi

    echo -e "\n${C_CYAN}--- Dynamic Banner Preview for user '$u' ---${C_RESET}\n"
    if [[ -f "/etc/novaxtunnel/banners/${u}.txt" ]]; then
        cat "/etc/novaxtunnel/banners/${u}.txt"
    else
        echo -e "${C_RED}Banner file not generated yet. Waiting up to 10s for the worker...${C_RESET}"
        sleep 5
        if ! cat "/etc/novaxtunnel/banners/${u}.txt" 2>/dev/null; then
            echo -e "\n${C_RED}Still not generated. Here are the last limiter logs:${C_RESET}"
            echo -e "----------------------------------------------------------------------"
            journalctl -u novaxtunnel-limiter -n 15 --no-pager
            echo -e "----------------------------------------------------------------------"
        fi
    fi
    press_enter
}

ssh_banner_menu() {
    while true; do
        show_banner
        local banner_status
        if grep -q -E "^\s*Banner\s+$SSH_BANNER_FILE" /etc/ssh/sshd_config && [ -f "$SSH_BANNER_FILE" ]; then
            banner_status="${C_STATUS_A}(Active)${C_RESET}"
        else
            banner_status="${C_STATUS_I}(Inactive)${C_RESET}"
        fi
        
        echo -e "\n   ${C_TITLE}═════════════════[ ${C_BOLD}🎨 SSH Banner Management ${banner_status} ${C_RESET}${C_TITLE}]═════════════════${C_RESET}"
        printf "     ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "📋 Paste or Edit Banner"
        printf "     ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "👁️ View Current Banner"
        printf "     ${C_DANGER}[ 3]${C_RESET} %-40s\n" "🗑️ Disable and Remove Banner"
        echo -e "   ${C_DIM}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${C_RESET}"
        echo -e "     ${C_WARN}[ 0]${C_RESET} ↩️ Return to Main Menu"
        echo
        read -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice
        case $choice in
            1) set_ssh_banner_paste ;;
            2) view_ssh_banner ;;
            3) remove_ssh_banner ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" && sleep 2 ;;
        esac
    done
}

install_udp_custom() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing udp-custom ---${C_RESET}"
    if [ -f "$UDP_CUSTOM_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ udp-custom is already installed.${C_RESET}"
        return
    fi

    echo -e "\n${C_GREEN}⚙️ Creating directory for udp-custom...${C_RESET}"
    rm -rf "$UDP_CUSTOM_DIR"
    mkdir -p "$UDP_CUSTOM_DIR"

    echo -e "\n${C_GREEN}⚙️ Detecting system architecture...${C_RESET}"
    local arch
    arch=$(uname -m)
    local binary_url=""
    if [[ "$arch" == "x86_64" ]]; then
        binary_url="https://github.com/NOSTRA-DevOps/nova-xtunnel/raw/main/udp/udp-custom-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Detected x86_64 (amd64) architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_url="https://github.com/NOSTRA-DevOps/nova-xtunnel/raw/main/udp/udp-custom-linux-arm"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Unsupported architecture: $arch. Cannot install udp-custom.${C_RESET}"
        rm -rf "$UDP_CUSTOM_DIR"
        return
    fi

    echo -e "\n${C_GREEN}📥 Downloading udp-custom binary...${C_RESET}"
    wget -q --show-progress -O "$UDP_CUSTOM_DIR/udp-custom" "$binary_url"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Failed to download the udp-custom binary.${C_RESET}"
        rm -rf "$UDP_CUSTOM_DIR"
        return
    fi
    chmod +x "$UDP_CUSTOM_DIR/udp-custom"

    echo -e "\n${C_GREEN}📝 Creating default config.json...${C_RESET}"
    cat > "$UDP_CUSTOM_DIR/config.json" <<EOF
{
  "listen": ":${UDP_CUSTOM_LISTEN_PORT}",
  "stream_buffer": 33554432,
  "receive_buffer": 83886080,
  "auth": {
    "mode": "passwords"
  }
}
EOF
    chmod 644 "$UDP_CUSTOM_DIR/config.json"

    echo -e "\n${C_GREEN}📝 Creating systemd service file...${C_RESET}"
    cat > "$UDP_CUSTOM_SERVICE_FILE" <<EOF
[Unit]
Description=UDP Custom by NOVA XTUNNEL
After=network.target

[Service]
User=root
Type=simple
ExecStart=$UDP_CUSTOM_DIR/udp-custom server -exclude 53,5300
WorkingDirectory=$UDP_CUSTOM_DIR/
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF

    echo -e "\n${C_BLUE}🔥 Configuring Firewall Rules (${UDP_CUSTOM_RANGE_START}-${UDP_CUSTOM_RANGE_END}, excl. ${UDP_CUSTOM_EXCLUDE_SINGLE_PORTS// /,} + ${ZIVPN_RANGE_START}-${ZIVPN_RANGE_END} -> ${UDP_CUSTOM_LISTEN_PORT})...${C_RESET}"
    _ff_flush_dnat_to_port "$UDP_CUSTOM_LISTEN_PORT"
    local _udpc_excl_args=()
    local _p
    for _p in $UDP_CUSTOM_EXCLUDE_SINGLE_PORTS; do
        _udpc_excl_args+=("$_p" "$_p")
    done
    _udpc_excl_args+=("$ZIVPN_RANGE_START" "$ZIVPN_RANGE_END")
    local _udpc_seg
    while read -r _udpc_seg; do
        [ -z "$_udpc_seg" ] && continue
        local _seg_start=${_udpc_seg% *} _seg_end=${_udpc_seg#* }
        check_and_open_firewall_udp_range "$_seg_start" "$_seg_end" "$UDP_CUSTOM_LISTEN_PORT"
    done < <(_ff_split_range "$UDP_CUSTOM_RANGE_START" "$UDP_CUSTOM_RANGE_END" "${_udpc_excl_args[@]}")

    echo -e "\n${C_GREEN}▶️ Enabling and starting udp-custom service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable udp-custom.service
    systemctl start udp-custom.service
    sleep 2
    if systemctl is-active --quiet udp-custom; then
        echo -e "\n${C_GREEN}✅ SUCCESS: udp-custom is installed and active.${C_RESET}"
        echo -e "   Plage publique: ${C_YELLOW}${UDP_CUSTOM_RANGE_START}-${UDP_CUSTOM_RANGE_END}${C_RESET} (exclut ${UDP_CUSTOM_EXCLUDE_SINGLE_PORTS// /,} et ${ZIVPN_RANGE_START}-${ZIVPN_RANGE_END}, redirigée vers le port interne ${UDP_CUSTOM_LISTEN_PORT})"
    else
        echo -e "\n${C_RED}❌ ERROR: udp-custom service failed to start.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Displaying last 15 lines of the service log for diagnostics:${C_RESET}"
        journalctl -u udp-custom.service -n 15 --no-pager
    fi
}

uninstall_udp_custom() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling udp-custom ---${C_RESET}"
    if [ ! -f "$UDP_CUSTOM_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ udp-custom is not installed, skipping.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling udp-custom service...${C_RESET}"
    systemctl stop udp-custom.service >/dev/null 2>&1
    systemctl disable udp-custom.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Removing systemd service file...${C_RESET}"
    rm -f "$UDP_CUSTOM_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Removing udp-custom directory and files...${C_RESET}"
    rm -rf "$UDP_CUSTOM_DIR"
    echo -e "${C_GREEN}✅ udp-custom has been uninstalled successfully.${C_RESET}"
}


ensure_badvpn_service_is_quiet() {
    if [[ ! -f "$BADVPN_SERVICE_FILE" ]] || grep -q "^StandardOutput=null$" "$BADVPN_SERVICE_FILE" 2>/dev/null; then
        return
    fi

    local tmp_service
    tmp_service=$(mktemp)
    awk '
        /^\[Service\]$/ {
            print
            print "StandardOutput=null"
            print "StandardError=null"
            next
        }
        { print }
    ' "$BADVPN_SERVICE_FILE" > "$tmp_service" && mv "$tmp_service" "$BADVPN_SERVICE_FILE"
    rm -f "$tmp_service" 2>/dev/null
    systemctl daemon-reload
    systemctl restart badvpn.service >/dev/null 2>&1 || true
}

install_badvpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing badvpn (udpgw) ---${C_RESET}"
    
    if [ -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ badvpn is already installed.${C_RESET}"
        return
    fi
    
    check_and_open_firewall_port 7300 udp || return
    
    echo -e "\n${C_GREEN}🔄 Updating package lists...${C_RESET}"
    ff_apt_update || return
    
    echo -e "\n${C_GREEN}📦 Installing all required packages...${C_RESET}"
    ff_apt_install cmake g++ make screen git build-essential libssl-dev libnspr4-dev libnss3-dev pkg-config || {
        echo -e "${C_RED}❌ Failed to install badvpn build dependencies.${C_RESET}"
        return
    }
    
    echo -e "\n${C_GREEN}📥 Cloning badvpn from github...${C_RESET}"
    git clone https://github.com/ambrop72/badvpn.git "$BADVPN_BUILD_DIR" || {
        echo -e "${C_RED}❌ Failed to clone repository.${C_RESET}"
        return
    }
    
    cd "$BADVPN_BUILD_DIR" || {
        echo -e "${C_RED}❌ Failed to change directory to build folder.${C_RESET}"
        rm -rf "$BADVPN_BUILD_DIR"
        return
    }
    
    echo -e "\n${C_GREEN}⚙️ Running CMake...${C_RESET}"
    cmake -DCMAKE_POLICY_VERSION_MINIMUM=3.5 . || {
        echo -e "${C_RED}❌ CMake configuration failed.${C_RESET}"
        rm -rf "$BADVPN_BUILD_DIR"
        return
    }
    
    echo -e "\n${C_GREEN}🛠️ Compiling source...${C_RESET}"
    make -j$(nproc) || {
        echo -e "${C_RED}❌ Compilation (make) failed.${C_RESET}"
        rm -rf "$BADVPN_BUILD_DIR"
        return
    }
    
    echo -e "\n${C_GREEN}📦 Installing badvpn...${C_RESET}"
    make install || {
        echo -e "${C_RED}❌ Installation (make install) failed.${C_RESET}"
        rm -rf "$BADVPN_BUILD_DIR"
        return
    }
    
    local badvpn_binary
    badvpn_binary=$(find "$BADVPN_BUILD_DIR" -name "badvpn-udpgw" -type f | head -n 1)
    
    if [[ -z "$badvpn_binary" || ! -f "$badvpn_binary" ]]; then
        echo -e "${C_RED}❌ ERROR: Could not find the compiled 'badvpn-udpgw' binary after compilation.${C_RESET}"
        rm -rf "$BADVPN_BUILD_DIR"
        return
    fi
    
    echo -e "${C_GREEN}ℹ️ Found binary at: $badvpn_binary${C_RESET}"
    chmod +x "$badvpn_binary"
    
    echo -e "\n${C_GREEN}📝 Creating systemd service file...${C_RESET}"
    cat > "$BADVPN_SERVICE_FILE" <<-EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target
[Service]
ExecStart=$badvpn_binary --listen-addr 0.0.0.0:7300 --max-clients 1000 --max-connections-for-client 8
User=root
Restart=always
RestartSec=3
StandardOutput=null
StandardError=null
[Install]
WantedBy=multi-user.target
EOF
    echo -e "\n${C_GREEN}▶️ Enabling and starting badvpn service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable badvpn.service
    systemctl start badvpn.service
    sleep 2
    if systemctl is-active --quiet badvpn; then
        echo -e "\n${C_GREEN}✅ SUCCESS: badvpn (udpgw) is installed and active on port 7300.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ ERROR: badvpn service failed to start.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Displaying last 15 lines of the service log for diagnostics:${C_RESET}"
        journalctl -u badvpn.service -n 15 --no-pager
    fi
}

uninstall_badvpn() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling badvpn (udpgw) ---${C_RESET}"
    if [ ! -f "$BADVPN_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ badvpn is not installed, skipping.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling badvpn service...${C_RESET}"
    systemctl stop badvpn.service >/dev/null 2>&1
    systemctl disable badvpn.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Removing systemd service file...${C_RESET}"
    rm -f "$BADVPN_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Removing badvpn build directory...${C_RESET}"
    rm -rf "$BADVPN_BUILD_DIR"
    echo -e "${C_GREEN}✅ badvpn has been uninstalled successfully.${C_RESET}"
}

load_edge_cert_info() {
    EDGE_CERT_MODE=""
    EDGE_DOMAIN=""
    EDGE_EMAIL=""
    if [ -f "$EDGE_CERT_INFO_FILE" ]; then
        source "$EDGE_CERT_INFO_FILE"
    fi
}

save_edge_cert_info() {
    local cert_mode="$1"
    local cert_domain="$2"
    local cert_email="$3"
    mkdir -p "$DB_DIR"
    cat > "$EDGE_CERT_INFO_FILE" <<EOF
EDGE_CERT_MODE="$cert_mode"
EDGE_DOMAIN="$cert_domain"
EDGE_EMAIL="$cert_email"
EOF
}

detect_preferred_host() {
    local host_domain=""
    load_edge_cert_info
    if [[ -n "$EDGE_DOMAIN" ]]; then
        host_domain="$EDGE_DOMAIN"
    fi
    if [[ -z "$host_domain" && -f "$DNS_INFO_FILE" ]]; then
        host_domain=$(grep 'FULL_DOMAIN' "$DNS_INFO_FILE" | cut -d'"' -f2)
    fi
    if [[ -z "$host_domain" && -f "$NGINX_CONFIG_FILE" ]]; then
        local nginx_domain
        nginx_domain=$(grep -oP 'server_name \K[^\s;]+' "$NGINX_CONFIG_FILE" 2>/dev/null | head -n 1)
        if [[ "$nginx_domain" != "_" && -n "$nginx_domain" ]]; then
            host_domain="$nginx_domain"
        fi
    fi
    if [[ -z "$host_domain" ]]; then
        host_domain=$(curl -s -4 icanhazip.com)
    fi
    echo "$host_domain"
}

backup_edge_configs() {
    if [ -f "$NGINX_CONFIG_FILE" ] && [ ! -f "${NGINX_CONFIG_FILE}.bak.novaxtunnel" ]; then
        cp "$NGINX_CONFIG_FILE" "${NGINX_CONFIG_FILE}.bak.novaxtunnel" 2>/dev/null
    fi
    if [ -f "$HAPROXY_CONFIG" ] && [ ! -f "${HAPROXY_CONFIG}.bak.novaxtunnel" ]; then
        cp "$HAPROXY_CONFIG" "${HAPROXY_CONFIG}.bak.novaxtunnel" 2>/dev/null
    fi
}

ensure_edge_stack_packages() {
    local missing_packages=()
    command -v haproxy &> /dev/null || missing_packages+=("haproxy")
    command -v nginx &> /dev/null || missing_packages+=("nginx")
    command -v openssl &> /dev/null || missing_packages+=("openssl")

    if (( ${#missing_packages[@]} > 0 )); then
        echo -e "\n${C_BLUE}📦 Installing required packages: ${missing_packages[*]}${C_RESET}"
        ff_apt_install "${missing_packages[@]}" || {
            echo -e "${C_RED}❌ Failed to install the required packages.${C_RESET}"
            return 1
        }
    fi
    return 0
}

build_shared_tls_bundle() {
    if [ ! -s "$SSL_CERT_CHAIN_FILE" ] || [ ! -s "$SSL_CERT_KEY_FILE" ]; then
        echo -e "${C_RED}❌ Certificate chain or key is missing.${C_RESET}"
        return 1
    fi
    cat "$SSL_CERT_CHAIN_FILE" "$SSL_CERT_KEY_FILE" > "$SSL_CERT_FILE" || return 1
    chmod 644 "$SSL_CERT_CHAIN_FILE"
    chmod 600 "$SSL_CERT_KEY_FILE" "$SSL_CERT_FILE"
    return 0
}

generate_self_signed_edge_cert() {
    local common_name="$1"
    mkdir -p "$SSL_CERT_DIR"
    echo -e "\n${C_GREEN}🔐 Generating a shared self-signed certificate...${C_RESET}"
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout "$SSL_CERT_KEY_FILE" \
        -out "$SSL_CERT_CHAIN_FILE" \
        -subj "/CN=$common_name" \
        >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to generate the self-signed certificate.${C_RESET}"
            return 1
        }
    build_shared_tls_bundle || return 1
    save_edge_cert_info "self-signed" "$common_name" ""
    echo -e "${C_GREEN}✅ Shared certificate created for ${C_YELLOW}$common_name${C_RESET}"
    return 0
}

_install_certbot() {
    if command -v certbot &> /dev/null; then
        echo -e "${C_GREEN}✅ Certbot is already installed.${C_RESET}"
        return 0
    fi
    echo -e "${C_BLUE}📦 Installing Certbot...${C_RESET}"
    ff_apt_install certbot || {
        echo -e "${C_RED}❌ Failed to install Certbot.${C_RESET}"
        return 1
    }
    echo -e "${C_GREEN}✅ Certbot installed successfully.${C_RESET}"
    return 0
}

obtain_certbot_edge_cert() {
    local domain_name="$1"
    local email="$2"
    local restart_haproxy=0
    local restart_nginx=0

    mkdir -p "$SSL_CERT_DIR"
    _install_certbot || return 1

    if systemctl is-active --quiet haproxy; then restart_haproxy=1; fi
    if systemctl is-active --quiet nginx; then restart_nginx=1; fi

    echo -e "\n${C_BLUE}🛑 Stopping HAProxy and Nginx for Certbot validation...${C_RESET}"
    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 2

    check_and_free_ports "$EDGE_PUBLIC_HTTP_PORT" "$EDGE_PUBLIC_TLS_PORT" || {
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    }

    echo -e "\n${C_BLUE}🚀 Requesting a Certbot certificate for ${C_YELLOW}$domain_name${C_RESET}"
    certbot certonly --standalone -d "$domain_name" --non-interactive --agree-tos -m "$email"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Certbot failed to obtain a certificate.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Make sure the domain points to this server and port 80 is reachable.${C_RESET}"
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    fi

    local certbot_chain="/etc/letsencrypt/live/$domain_name/fullchain.pem"
    local certbot_key="/etc/letsencrypt/live/$domain_name/privkey.pem"
    if [ ! -f "$certbot_chain" ] || [ ! -f "$certbot_key" ]; then
        echo -e "\n${C_RED}❌ Certbot completed, but the certificate files were not found.${C_RESET}"
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    fi

    cp "$certbot_chain" "$SSL_CERT_CHAIN_FILE"
    cp "$certbot_key" "$SSL_CERT_KEY_FILE"
    build_shared_tls_bundle || {
        [[ "$restart_nginx" -eq 1 ]] && systemctl start nginx >/dev/null 2>&1
        [[ "$restart_haproxy" -eq 1 ]] && systemctl start haproxy >/dev/null 2>&1
        return 1
    }
    save_edge_cert_info "certbot" "$domain_name" "$email"
    echo -e "${C_GREEN}✅ Certbot certificate copied into ${C_YELLOW}$SSL_CERT_DIR${C_RESET}"
    return 0
}

select_edge_certificate() {
    local preferred_host
    local cert_choice
    local has_existing_cert=false

    preferred_host=$(detect_preferred_host)
    if [[ -z "$preferred_host" ]]; then
        preferred_host="novaxtunnel.local"
    fi

    if [ -s "$SSL_CERT_FILE" ] && [ -s "$SSL_CERT_CHAIN_FILE" ] && [ -s "$SSL_CERT_KEY_FILE" ]; then
        has_existing_cert=true
    fi

    load_edge_cert_info

    echo -e "\n${C_BOLD}${C_PURPLE}--- 🔐 Shared TLS Certificate ---${C_RESET}"
    echo -e "${C_DIM}The same certificate will be used by HAProxy and the internal Nginx proxy.${C_RESET}"

    if $has_existing_cert; then
        local existing_label="${EDGE_CERT_MODE:-existing}"
        if [[ -n "$EDGE_DOMAIN" ]]; then
            existing_label="$existing_label - $EDGE_DOMAIN"
        fi
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-52s\n" "Reuse existing certificate (${existing_label})"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-52s\n" "Replace with a new self-signed certificate"
        printf "  ${C_CHOICE}[ 3]${C_RESET} %-52s\n" "Replace with a Certbot certificate"
        echo
        read -p "👉 Enter choice [1]: " cert_choice
        cert_choice=${cert_choice:-1}
    else
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-52s\n" "Generate a self-signed certificate"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-52s\n" "Use a Certbot certificate"
        echo
        read -p "👉 Enter choice [1]: " cert_choice
        cert_choice=${cert_choice:-1}
    fi

    case "$cert_choice" in
        1)
            if $has_existing_cert; then
                echo -e "${C_GREEN}✅ Reusing the existing shared certificate.${C_RESET}"
                return 0
            fi
            local common_name
            read -p "👉 Enter the certificate Common Name / SNI label [$preferred_host]: " common_name
            common_name=${common_name:-$preferred_host}
            generate_self_signed_edge_cert "$common_name"
            ;;
        2)
            if $has_existing_cert; then
                local common_name
                read -p "👉 Enter the certificate Common Name / SNI label [$preferred_host]: " common_name
                common_name=${common_name:-$preferred_host}
                generate_self_signed_edge_cert "$common_name"
            else
                local default_domain=""
                local domain_name
                local email
                if ! _is_valid_ipv4 "$preferred_host"; then
                    default_domain="$preferred_host"
                fi
                if [[ -n "$default_domain" ]]; then
                    read -p "👉 Enter your domain name [$default_domain]: " domain_name
                    domain_name=${domain_name:-$default_domain}
                else
                    read -p "👉 Enter your domain name (e.g. vpn.example.com): " domain_name
                fi
                if [[ -z "$domain_name" ]]; then
                    echo -e "${C_RED}❌ Domain name cannot be empty.${C_RESET}"
                    return 1
                fi
                if _is_valid_ipv4 "$domain_name"; then
                    echo -e "${C_RED}❌ Certbot requires a real domain name, not a raw IP address.${C_RESET}"
                    return 1
                fi
                read -p "👉 Enter your email for Let's Encrypt: " email
                if [[ -z "$email" ]]; then
                    echo -e "${C_RED}❌ Email cannot be empty.${C_RESET}"
                    return 1
                fi
                obtain_certbot_edge_cert "$domain_name" "$email"
            fi
            ;;
        3)
            if ! $has_existing_cert; then
                echo -e "${C_RED}❌ Invalid option.${C_RESET}"
                return 1
            fi
            local default_domain=""
            local domain_name
            local email
            if [[ -n "$EDGE_DOMAIN" ]] && ! _is_valid_ipv4 "$EDGE_DOMAIN"; then
                default_domain="$EDGE_DOMAIN"
            fi
            if [[ -z "$default_domain" ]] && ! _is_valid_ipv4 "$preferred_host"; then
                default_domain="$preferred_host"
            fi
            if [[ -n "$default_domain" ]]; then
                read -p "👉 Enter your domain name [$default_domain]: " domain_name
                domain_name=${domain_name:-$default_domain}
            else
                read -p "👉 Enter your domain name (e.g. vpn.example.com): " domain_name
            fi
            if [[ -z "$domain_name" ]]; then
                echo -e "${C_RED}❌ Domain name cannot be empty.${C_RESET}"
                return 1
            fi
            if _is_valid_ipv4 "$domain_name"; then
                echo -e "${C_RED}❌ Certbot requires a real domain name, not a raw IP address.${C_RESET}"
                return 1
            fi
            read -p "👉 Enter your email for Let's Encrypt [${EDGE_EMAIL}]: " email
            email=${email:-$EDGE_EMAIL}
            if [[ -z "$email" ]]; then
                echo -e "${C_RED}❌ Email cannot be empty.${C_RESET}"
                return 1
            fi
            obtain_certbot_edge_cert "$domain_name" "$email"
            ;;
        *)
            echo -e "${C_RED}❌ Invalid option.${C_RESET}"
            return 1
            ;;
    esac
}

write_internal_nginx_config() {
    local server_name="$1"
    [[ -z "$server_name" ]] && server_name="_"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    cat > "$NGINX_CONFIG_FILE" <<EOF
server {
    listen 127.0.0.1:${NGINX_INTERNAL_HTTP_PORT} default_server;
    listen 127.0.0.1:${NGINX_INTERNAL_TLS_PORT} ssl http2 default_server;
    server_tokens off;
    server_name ${server_name};

    ssl_certificate ${SSL_CERT_CHAIN_FILE};
    ssl_certificate_key ${SSL_CERT_KEY_FILE};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!MD5:!DES:!RC4:!ADH:!SSLv3:!EXP:!PSK:!DSS;
    resolver 1.1.1.1 8.8.8.8 ipv6=off valid=300s;

    location ~ ^/(?<fwdport>\d+)/(?<fwdpath>.*)$ {
        client_max_body_size 0;
        client_body_timeout 1d;
        grpc_read_timeout 1d;
        grpc_socket_keepalive on;
        proxy_read_timeout 1d;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_socket_keepalive on;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        if (\$content_type ~* "GRPC") { grpc_pass grpc://127.0.0.1:\$fwdport\$is_args\$args; break; }
        proxy_pass http://127.0.0.1:\$fwdport\$is_args\$args;
        break;
    }

    location / {
        proxy_read_timeout 3600s;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_socket_keepalive on;
        tcp_nodelay on;
        tcp_nopush off;
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
    ln -sf "$NGINX_CONFIG_FILE" /etc/nginx/sites-enabled/default
}

write_haproxy_edge_config() {
    mkdir -p /etc/haproxy
    cat > "$HAPROXY_CONFIG" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5s
    timeout client  24h
    timeout server  24h

# ====================================================================
# TIER 1: PORT ${EDGE_PUBLIC_HTTP_PORT} (Cleartext Payloads & Raw SSH)
# ====================================================================
frontend port_80_edge
    bind *:80
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30
    acl is_payload payload(0,16) -m reg "^(GET|POST|OPTIONS|ACL|TRACE|CONNECT|PATCH|HEAD|PUT|DELETE|POLL|HTTP/)"

    tcp-request content accept if is_payload
    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP

    use_backend direct_sshp if is_payload
    default_backend nginx_cleartext

# ====================================================================
# TIER 1: PORT 443 (TLS v2ray, SSL Payloads, Raw SSH)
# ====================================================================
frontend port_443_edge
    bind *:443
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30
    acl is_tls req.ssl_hello_type 1
    acl has_web_alpn req.ssl_alpn -m sub h2 http/1.1
    acl is_payload payload(0,7) -m reg "^(GET|POST|OPTIONS|ACL|TRACE|CONNECT|PATCH|HEAD|PUT|DELETE|POLL|HTTP/)"

    tcp-request content accept if is_payload
    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP
    tcp-request content accept if is_tls

    use_backend direct_ssht if is_payload
    use_backend nginx_cleartext if HTTP
    use_backend nginx_tls if is_tls has_web_alpn
    default_backend loopback_ssl_terminator

# ====================================================================
# TIER 2: INTERNAL DECRYPTOR (Only for Any-SNI SSH-TLS)
# ====================================================================
frontend internal_decryptor
    bind 127.0.0.1:${HAPROXY_INTERNAL_DECRYPT_PORT} ssl crt ${SSL_CERT_FILE}
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30
    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP

    use_backend direct_ssh if is_ssh
    default_backend nginx_cleartext

# ====================================================================
# DESTINATION BACKENDS (Clean handoffs, no proxy headers)
# ====================================================================
backend direct_ssh
    mode tcp
    server ssh_server 127.0.0.1:22

backend direct_sshp
    mode tcp
    server ssh_server 127.0.0.1:8888

backend direct_ssht
    mode tcp
    server ssh_server 127.0.0.1:444

backend nginx_cleartext
    mode tcp
    server nginx_8880 127.0.0.1:${NGINX_INTERNAL_HTTP_PORT}

backend nginx_tls
    mode tcp
    server nginx_8443 127.0.0.1:${NGINX_INTERNAL_TLS_PORT}

backend loopback_ssl_terminator
    mode tcp
    server haproxy_ssl 127.0.0.1:${HAPROXY_INTERNAL_DECRYPT_PORT}
EOF
}

save_edge_ports_info() {
    cat > "$NGINX_PORTS_FILE" <<EOF
EDGE_HTTP_PORT="${EDGE_PUBLIC_HTTP_PORT}"
EDGE_TLS_PORT="${EDGE_PUBLIC_TLS_PORT}"
HTTP_PORTS="${NGINX_INTERNAL_HTTP_PORT}"
TLS_PORTS="${NGINX_INTERNAL_TLS_PORT}"
EOF
}

configure_edge_stack() {
    local server_name="$1"
    [[ -z "$server_name" ]] && server_name="_"

    backup_edge_configs

    echo -e "\n${C_BLUE}📝 Writing internal Nginx config (127.0.0.1:${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT})...${C_RESET}"
    write_internal_nginx_config "$server_name"

    echo -e "${C_BLUE}📝 Writing HAProxy edge config (${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT})...${C_RESET}"
    write_haproxy_edge_config

    echo -e "\n${C_BLUE}🧪 Validating Nginx configuration...${C_RESET}"
    if ! nginx -t >/dev/null 2>&1; then
        echo -e "${C_RED}❌ Nginx configuration validation failed.${C_RESET}"
        nginx -t
        return 1
    fi

    echo -e "${C_BLUE}🧪 Validating HAProxy configuration...${C_RESET}"
    if ! haproxy -c -f "$HAPROXY_CONFIG" >/dev/null 2>&1; then
        echo -e "${C_RED}❌ HAProxy configuration validation failed.${C_RESET}"
        haproxy -c -f "$HAPROXY_CONFIG"
        return 1
    fi

    systemctl daemon-reload
    systemctl enable nginx >/dev/null 2>&1
    systemctl enable haproxy >/dev/null 2>&1

    echo -e "\n${C_BLUE}▶️ Restarting internal Nginx...${C_RESET}"
    systemctl restart nginx || {
        echo -e "${C_RED}❌ Nginx failed to restart.${C_RESET}"
        systemctl status nginx --no-pager
        return 1
    }

    echo -e "${C_BLUE}▶️ Restarting HAProxy edge...${C_RESET}"
    systemctl restart haproxy || {
        echo -e "${C_RED}❌ HAProxy failed to restart.${C_RESET}"
        systemctl status haproxy --no-pager
        return 1
    }

    sleep 2
    if ! systemctl is-active --quiet nginx; then
        echo -e "${C_RED}❌ Nginx is not active after restart.${C_RESET}"
        systemctl status nginx --no-pager
        return 1
    fi
    if ! systemctl is-active --quiet haproxy; then
        echo -e "${C_RED}❌ HAProxy is not active after restart.${C_RESET}"
        systemctl status haproxy --no-pager
        return 1
    fi

    save_edge_ports_info
    return 0
}

install_ssl_tunnel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing HAProxy Edge Stack (80/443 -> 8880/8443) ---${C_RESET}"
    echo -e "\n${C_CYAN}This installer will configure:${C_RESET}"
    echo -e "   • HAProxy on ${C_WHITE}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Internal Nginx on ${C_WHITE}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "   • Loopback SSL decryptor on ${C_WHITE}${HAPROXY_INTERNAL_DECRYPT_PORT}${C_RESET}"

    if [ -f "$HAPROXY_CONFIG" ] || [ -f "$NGINX_CONFIG_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ Existing HAProxy/Nginx configs will be replaced with the NOVA XTUNNEL edge layout.${C_RESET}"
        read -p "👉 Continue with the replacement? (y/n): " confirm_replace
        if [[ "$confirm_replace" != "y" && "$confirm_replace" != "Y" ]]; then
            echo -e "${C_RED}❌ Installation cancelled.${C_RESET}"
            return
        fi
    fi

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"

    ensure_edge_stack_packages || return

    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 1

    check_and_free_ports \
        "$EDGE_PUBLIC_HTTP_PORT" \
        "$EDGE_PUBLIC_TLS_PORT" \
        "$NGINX_INTERNAL_HTTP_PORT" \
        "$NGINX_INTERNAL_TLS_PORT" \
        "$HAPROXY_INTERNAL_DECRYPT_PORT" || return

    check_and_open_firewall_port "$EDGE_PUBLIC_HTTP_PORT" tcp || return
    check_and_open_firewall_port "$EDGE_PUBLIC_TLS_PORT" tcp || return

    select_edge_certificate || return

    load_edge_cert_info
    local server_name="${EDGE_DOMAIN:-$(detect_preferred_host)}"
    [[ -z "$server_name" ]] && server_name="_"

    configure_edge_stack "$server_name" || return

    echo -e "\n${C_GREEN}✅ SUCCESS: HAProxy edge stack is active.${C_RESET}"
    echo -e "   • Public edge ports: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Internal Nginx ports: ${C_YELLOW}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "   • Shared certificate: ${C_YELLOW}${EDGE_CERT_MODE:-unknown}${C_RESET}"
}

uninstall_ssl_tunnel() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling HAProxy Edge Stack ---${C_RESET}"
    if ! command -v haproxy &> /dev/null; then
        echo -e "${C_YELLOW}ℹ️ HAProxy is not installed, skipping service removal.${C_RESET}"
    else
        echo -e "${C_GREEN}🛑 Stopping and disabling HAProxy...${C_RESET}"
        systemctl stop haproxy >/dev/null 2>&1
        systemctl disable haproxy >/dev/null 2>&1
    fi

    if [ -f "$HAPROXY_CONFIG" ]; then
        cat > "$HAPROXY_CONFIG" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice

defaults
    log     global
EOF
    fi

    local delete_cert="n"
    if [[ "$UNINSTALL_MODE" == "silent" ]]; then
        delete_cert="y"
    elif [ -f "$SSL_CERT_FILE" ] || [ -f "$SSL_CERT_CHAIN_FILE" ] || [ -f "$SSL_CERT_KEY_FILE" ]; then
        if systemctl is-active --quiet nginx; then
            echo -e "${C_YELLOW}⚠️ The shared certificate is also used by the internal Nginx proxy.${C_RESET}"
        fi
        read -p "👉 Delete the shared TLS certificate too? (y/n): " delete_cert
    fi

    if [[ "$delete_cert" == "y" || "$delete_cert" == "Y" ]]; then
        if systemctl is-active --quiet nginx; then
            echo -e "${C_GREEN}🛑 Stopping Nginx because the shared certificate is being removed...${C_RESET}"
            systemctl stop nginx >/dev/null 2>&1
        fi
        rm -f "$SSL_CERT_FILE" "$SSL_CERT_CHAIN_FILE" "$SSL_CERT_KEY_FILE" "$EDGE_CERT_INFO_FILE"
        rm -f "$NGINX_PORTS_FILE"
        echo -e "${C_GREEN}🗑️ Shared certificate files removed.${C_RESET}"
    fi

    echo -e "${C_GREEN}✅ HAProxy edge stack has been removed.${C_RESET}"
    if systemctl is-active --quiet nginx; then
        echo -e "${C_DIM}The internal Nginx proxy is still installed on ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"
    fi
}

show_dnstt_details() {
    if [ ! -f "$DNSTT_CONFIG_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ DNSTT configuration file not found.${C_RESET}"
        return 1
    fi
    
    source "$DNSTT_CONFIG_FILE"
    
    # Détection du mode simultané
    local is_multi=false
    if [[ "$MULTI_TARGET" == "true" ]] || [[ "$FORWARD_DESC" == *"SSH + V2Ray"* ]] || \
       [[ -f "/etc/systemd/system/dnstt-mux.service" ]] && systemctl is-active --quiet dnstt-mux.service 2>/dev/null; then
        is_multi=true
    fi
    
    echo -e "\n${C_GREEN}=====================================================${C_RESET}"
    echo -e "${C_GREEN}            📡 DNSTT Connection Details             ${C_RESET}"
    echo -e "${C_GREEN}=====================================================${C_RESET}"
    
    echo -e "\n${C_WHITE}Connection Details:${C_RESET}"
    echo -e "  - ${C_CYAN}Tunnel Domain:${C_RESET} ${C_YELLOW}$TUNNEL_DOMAIN${C_RESET}"
    echo -e "  - ${C_CYAN}Nameserver:${C_RESET}    ${C_YELLOW}$NS_DOMAIN${C_RESET}"
    echo -e "  - ${C_CYAN}Public Key:${C_RESET}    ${C_YELLOW}$PUBLIC_KEY${C_RESET}"
    
    if [[ -n "$MTU_VALUE" ]]; then
        echo -e "  - ${C_CYAN}MTU Value:${C_RESET}     ${C_YELLOW}$MTU_VALUE${C_RESET}"
    fi
    
    # Mode
    if [[ "$is_multi" == "true" ]]; then
        echo -e "  - ${C_CYAN}Mode:${C_RESET}          ${C_GREEN}SSH + V2Ray${C_RESET}"
        echo -e "  - ${C_CYAN}Backend:${C_RESET}       ${C_YELLOW}127.0.0.1:10022 (HAProxy)${C_RESET}"
        echo -e "  - ${C_CYAN}SSH →:${C_RESET}         ${C_YELLOW}127.0.0.1:22${C_RESET}"
        echo -e "  - ${C_CYAN}V2Ray →:${C_RESET}       ${C_YELLOW}127.0.0.1:8787${C_RESET}"
    elif [[ "$FORWARD_DESC" == *"V2Ray"* ]]; then
        echo -e "  - ${C_CYAN}Mode:${C_RESET}          ${C_GREEN}V2Ray only${C_RESET}"
        echo -e "  - ${C_CYAN}Forward:${C_RESET}       ${C_YELLOW}127.0.0.1:8787${C_RESET}"
    elif [[ "$FORWARD_DESC" == *"SSH"* ]]; then
        echo -e "  - ${C_CYAN}Mode:${C_RESET}          ${C_GREEN}SSH only${C_RESET}"
        echo -e "  - ${C_CYAN}Forward:${C_RESET}       ${C_YELLOW}127.0.0.1:22${C_RESET}"
    fi
    
    # Statut
    echo -e "\n${C_WHITE}Service Status:${C_RESET}"
    if systemctl is-active --quiet dnstt.service 2>/dev/null; then
        echo -e "  - ${C_GREEN}✅ DNSTT: Running${C_RESET}"
    else
        echo -e "  - ${C_RED}❌ DNSTT: Stopped${C_RESET}"
    fi
    
    if [[ "$is_multi" == "true" ]]; then
        if systemctl is-active --quiet dnstt-mux.service 2>/dev/null; then
            echo -e "  - ${C_GREEN}✅ Multiplexer: Running${C_RESET}"
        else
            echo -e "  - ${C_RED}❌ Multiplexer: Stopped${C_RESET}"
        fi
    fi
    
    # Exemples clients
    echo -e "\n${C_WHITE}Client Examples:${C_RESET}"
    if [[ "$is_multi" == "true" ]]; then
        echo -e "  ${C_YELLOW}SSH:${C_RESET}"
        echo -e "    ssh -o ProxyCommand=\"./dnstt-client -dns $NS_DOMAIN -pubkey $PUBLIC_KEY $TUNNEL_DOMAIN %h %p\" user@localhost"
        echo -e "  ${C_YELLOW}V2Ray:${C_RESET}"
        echo -e "    DNS: $TUNNEL_DOMAIN (port 53)"
    elif [[ "$FORWARD_DESC" == *"V2Ray"* ]]; then
        echo -e "  ${C_YELLOW}V2Ray:${C_RESET}"
        echo -e "    DNS: $TUNNEL_DOMAIN (port 53)"
    else
        echo -e "  ${C_YELLOW}SSH:${C_RESET}"
        echo -e "    ssh -o ProxyCommand=\"./dnstt-client -dns $NS_DOMAIN -pubkey $PUBLIC_KEY $TUNNEL_DOMAIN %h %p\" user@localhost"
    fi
    
    echo -e "\n${C_DIM}💡 Logs: journalctl -u dnstt.service -f${C_RESET}"
    echo -e "${C_GREEN}=====================================================${C_RESET}"
}


install_dnstt() {
    clear
    show_banner

    echo -e "${C_BOLD}${C_PURPLE}--- 📡 DNSTT (DNS Tunnel) Management ---${C_RESET}"

    # ================================================================
    # VARIABLES
    # ================================================================

    local MUX_PORT="10022"
    local MUX_CONFIG="/etc/haproxy/haproxy-dnstt-mux.cfg"
    local MUX_SERVICE_FILE="/etc/systemd/system/dnstt-mux.service"

    # ================================================================
    # FONCTION : CONFIGURER LE MULTIPLEXEUR SSH + V2RAY
    # ================================================================

    configure_dnstt_mux() {

        echo -e "\n${C_BLUE}🔀 Configuring SSH + V2Ray multiplexer...${C_RESET}"

        # ------------------------------------------------------------
        # Vérification SSH
        # ------------------------------------------------------------

        if ss -lnt 2>/dev/null | grep -qE '(^|:)22[[:space:]]'; then
            echo -e "${C_GREEN}✅ SSH detected on port 22.${C_RESET}"
        else
            echo -e "${C_YELLOW}⚠️ SSH does not appear to listen on port 22.${C_RESET}"
        fi

        # ------------------------------------------------------------
        # Vérification V2Ray
        # ------------------------------------------------------------

        if ss -lnt 2>/dev/null | grep -qE '(^|:)8787[[:space:]]'; then
            echo -e "${C_GREEN}✅ V2Ray detected on port 8787.${C_RESET}"
        else
            echo -e "${C_YELLOW}⚠️ V2Ray does not appear to listen on port 8787.${C_RESET}"
            echo -e "${C_DIM}   Make sure your V2Ray inbound uses 127.0.0.1:8787.${C_RESET}"
        fi

        # ------------------------------------------------------------
        # HAProxy nécessaire pour le multiplexage
        # ------------------------------------------------------------

        if ! command -v haproxy >/dev/null 2>&1; then

            echo -e "${C_BLUE}📦 HAProxy is required for the multiplexer.${C_RESET}"

            ff_apt_install haproxy || {
                echo -e "${C_RED}❌ Failed to install HAProxy.${C_RESET}"
                return 1
            }
        fi

        # ------------------------------------------------------------
        # Vérifier le port 10022
        # ------------------------------------------------------------

        if ss -lnt 2>/dev/null | grep -q ":${MUX_PORT} "; then

            echo -e "${C_YELLOW}⚠️ Port ${MUX_PORT} is already in use.${C_RESET}"

            echo
            ss -lntp 2>/dev/null | grep ":${MUX_PORT}" || true

            echo
            read -p "👉 Continue using this port? (y/n) [n]: " mux_continue

            if [[ "$mux_continue" != "y" && "$mux_continue" != "Y" ]]; then
                echo -e "${C_RED}❌ Multiplexer installation cancelled.${C_RESET}"
                return 1
            fi
        fi

        # ------------------------------------------------------------
        # Création configuration HAProxy
        # ------------------------------------------------------------

        mkdir -p /etc/haproxy

        cat > "$MUX_CONFIG" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

defaults
    log global
    mode tcp
    option tcplog
    option dontlognull

    timeout connect 5s
    timeout client 24h
    timeout server 24h

frontend dnstt_mux
    bind 127.0.0.1:${MUX_PORT}
    mode tcp

    # ------------------------------------------------------------
    # SSH detection
    #
    # SSH normally begins with:
    #
    # SSH-2.0-
    #
    # Hex:
    # 53 53 48 2D 32 2E 30
    # ------------------------------------------------------------

    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30

    tcp-request content accept if is_ssh

    # SSH
    use_backend dnstt_ssh if is_ssh

    # Everything else
    # goes to V2Ray
    default_backend dnstt_v2ray


backend dnstt_ssh
    mode tcp
    server ssh_backend 127.0.0.1:22 check


backend dnstt_v2ray
    mode tcp
    server v2ray_backend 127.0.0.1:8787 check
EOF

        # ------------------------------------------------------------
        # Validation HAProxy
        # ------------------------------------------------------------

        echo -e "${C_BLUE}🧪 Validating multiplexer configuration...${C_RESET}"

        if ! haproxy -c -f "$MUX_CONFIG"; then
            echo -e "${C_RED}❌ HAProxy multiplexer configuration is invalid.${C_RESET}"
            return 1
        fi

        # ------------------------------------------------------------
        # Service systemd séparé
        # ------------------------------------------------------------

        cat > "$MUX_SERVICE_FILE" <<EOF
[Unit]
Description=DNSTT SSH + V2Ray Multiplexer
After=network.target

[Service]
Type=simple
ExecStart=/usr/sbin/haproxy -f ${MUX_CONFIG} -db
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

        systemctl daemon-reload

        systemctl enable dnstt-mux.service >/dev/null 2>&1

        systemctl restart dnstt-mux.service

        sleep 2

        if ! systemctl is-active --quiet dnstt-mux.service; then

            echo -e "${C_RED}❌ DNSTT multiplexer failed to start.${C_RESET}"

            journalctl \
                -u dnstt-mux.service \
                -n 30 \
                --no-pager

            return 1
        fi

        echo -e "${C_GREEN}✅ SSH + V2Ray multiplexer is active.${C_RESET}"
        echo -e "   ${C_YELLOW}DNSTT → 127.0.0.1:${MUX_PORT}${C_RESET}"
        echo -e "   ${C_YELLOW}SSH   → 127.0.0.1:22${C_RESET}"
        echo -e "   ${C_YELLOW}V2Ray → 127.0.0.1:8787${C_RESET}"

        return 0
    }


    # ================================================================
    # FUNCTION : SET DNSTT DESTINATION
    # ================================================================

    set_dnstt_destination() {

        local destination="$1"
        local description="$2"

        if [[ -z "$destination" ]]; then
            echo -e "${C_RED}❌ Empty DNSTT destination.${C_RESET}"
            return 1
        fi

        if [[ ! -f "$DNSTT_SERVICE_FILE" ]]; then
            echo -e "${C_RED}❌ DNSTT service file not found.${C_RESET}"
            return 1
        fi

        # Backup
        cp "$DNSTT_SERVICE_FILE" \
            "${DNSTT_SERVICE_FILE}.bak.$(date +%Y%m%d%H%M%S)"

        # ------------------------------------------------------------
        # On remplace uniquement le dernier argument de ExecStart.
        #
        # Exemple :
        #
        # ... tunnel.example.com 127.0.0.1:22
        #
        # devient :
        #
        # ... tunnel.example.com 127.0.0.1:10022
        # ------------------------------------------------------------

        sed -i -E \
            's#([[:space:]])127\.0\.0\.1:[0-9]+([[:space:]]*)$#\1'"$destination"'\2#' \
            "$DNSTT_SERVICE_FILE"

        # Description
        sed -i \
            's/^Description=.*/Description=DNSTT - '"$description"'/' \
            "$DNSTT_SERVICE_FILE"

        systemctl daemon-reload

        return 0
    }


    # ================================================================
    # CASE 1 : DNSTT ALREADY INSTALLED
    # ================================================================

    if [[ -f "$DNSTT_SERVICE_FILE" ]]; then

        echo -e "\n${C_YELLOW}ℹ️ DNSTT is already installed.${C_RESET}"

        show_dnstt_details

        echo
        echo -e "${C_BOLD}${C_PURPLE}--- 🔀 DNSTT Configuration ---${C_RESET}"
        echo
        echo -e "  ${C_GREEN}[ 1]${C_RESET} Keep current configuration"
        echo -e "  ${C_GREEN}[ 2]${C_RESET} SSH only"
        echo -e "  ${C_GREEN}[ 3]${C_RESET} V2Ray only"
        echo -e "  ${C_GREEN}[ 4]${C_RESET} SSH + V2Ray"
        echo

        read -p "👉 Enter choice [1]: " existing_choice
        existing_choice=${existing_choice:-1}

        case "$existing_choice" in

            1)

                echo -e "${C_GREEN}✅ Keeping existing DNSTT configuration.${C_RESET}"
                return 0
                ;;

            2)

                echo -e "\n${C_BLUE}🔧 Configuring DNSTT → SSH...${C_RESET}"

                set_dnstt_destination \
                    "127.0.0.1:22" \
                    "SSH only" || return 1

                # Si le multiplexeur existait, on peut le laisser arrêté.
                if [[ -f "$MUX_SERVICE_FILE" ]]; then
                    systemctl stop dnstt-mux.service >/dev/null 2>&1
                    systemctl disable dnstt-mux.service >/dev/null 2>&1
                fi

                systemctl restart dnstt.service

                sleep 2

                if systemctl is-active --quiet dnstt.service; then
                    echo -e "${C_GREEN}✅ DNSTT is now configured for SSH only.${C_RESET}"
                else
                    echo -e "${C_RED}❌ DNSTT failed to restart.${C_RESET}"
                    journalctl -u dnstt.service -n 30 --no-pager
                    return 1
                fi

                return 0
                ;;

            3)

                echo -e "\n${C_BLUE}🔧 Configuring DNSTT → V2Ray...${C_RESET}"

                set_dnstt_destination \
                    "127.0.0.1:8787" \
                    "V2Ray only" || return 1

                if [[ -f "$MUX_SERVICE_FILE" ]]; then
                    systemctl stop dnstt-mux.service >/dev/null 2>&1
                    systemctl disable dnstt-mux.service >/dev/null 2>&1
                fi

                systemctl restart dnstt.service

                sleep 2

                if systemctl is-active --quiet dnstt.service; then
                    echo -e "${C_GREEN}✅ DNSTT is now configured for V2Ray only.${C_RESET}"
                else
                    echo -e "${C_RED}❌ DNSTT failed to restart.${C_RESET}"
                    journalctl -u dnstt.service -n 30 --no-pager
                    return 1
                fi

                return 0
                ;;

            4)

                echo -e "\n${C_BLUE}🔀 Upgrading DNSTT → SSH + V2Ray...${C_RESET}"

                # ----------------------------------------------------
                # Créer le multiplexeur
                # ----------------------------------------------------

                configure_dnstt_mux || return 1

                # ----------------------------------------------------
                # DNSTT → multiplexeur
                # ----------------------------------------------------

                set_dnstt_destination \
                    "127.0.0.1:${MUX_PORT}" \
                    "SSH + V2Ray" || return 1

                # ----------------------------------------------------
                # Redémarrer DNSTT
                # ----------------------------------------------------

                systemctl daemon-reload
                systemctl restart dnstt.service

                sleep 2

                if ! systemctl is-active --quiet dnstt.service; then

                    echo -e "${C_RED}❌ DNSTT failed after upgrade.${C_RESET}"

                    journalctl \
                        -u dnstt.service \
                        -n 30 \
                        --no-pager

                    return 1
                fi

                echo
                echo -e "${C_GREEN}==============================================${C_RESET}"
                echo -e "${C_GREEN}✅ DNSTT upgraded to SSH + V2Ray${C_RESET}"
                echo -e "${C_GREEN}==============================================${C_RESET}"
                echo
                echo -e "   DNSTT : ${C_YELLOW}127.0.0.1:${MUX_PORT}${C_RESET}"
                echo -e "   SSH   : ${C_YELLOW}127.0.0.1:22${C_RESET}"
                echo -e "   V2Ray : ${C_YELLOW}127.0.0.1:8787${C_RESET}"
                echo

                return 0
                ;;

            *)

                echo -e "${C_RED}❌ Invalid choice.${C_RESET}"
                return 1
                ;;

        esac
    fi


    # ================================================================
    # CASE 2 : DNSTT NOT INSTALLED
    # ================================================================


    echo -e "${C_GREEN}⚙️ Forcing release of Port 53...${C_RESET}"

    systemctl stop systemd-resolved >/dev/null 2>&1
    systemctl disable systemd-resolved >/dev/null 2>&1

    chattr -i /etc/resolv.conf >/dev/null 2>&1
    rm -f /etc/resolv.conf

    echo "nameserver 8.8.8.8" > /etc/resolv.conf

    echo -e "\n${C_BLUE}🔎 Checking port 53/UDP...${C_RESET}"

    if ss -lunp 2>/dev/null | grep -qE '(:|[[:space:]])53[[:space:]]'; then

        echo -e "${C_RED}❌ Port 53/UDP is still in use.${C_RESET}"

        ss -lunp 2>/dev/null | grep -E '(:|[[:space:]])53[[:space:]]'

        return 1

    else

        echo -e "${C_GREEN}✅ Port 53/UDP is available.${C_RESET}"

    fi

    check_and_open_firewall_port 53 udp || return 1


    local forward_port=""
    local forward_desc=""

    echo
    echo -e "${C_BLUE}Please choose the DNSTT backend:${C_RESET}"
    echo
    echo -e "  ${C_GREEN}[ 1]${C_RESET} SSH only"
    echo -e "  ${C_GREEN}[ 2]${C_RESET} V2Ray only"
    echo -e "  ${C_GREEN}[ 3]${C_RESET} SSH + V2Ray"
    echo

    read -p "👉 Enter your choice [3]: " fwd_choice
    fwd_choice=${fwd_choice:-3}

    case "$fwd_choice" in

        1)

            forward_port="22"
            forward_desc="SSH only"

            echo -e "${C_GREEN}ℹ️ DNSTT → 127.0.0.1:22${C_RESET}"

            ;;

        2)

            forward_port="8787"
            forward_desc="V2Ray only"

            echo -e "${C_GREEN}ℹ️ DNSTT → 127.0.0.1:8787${C_RESET}"

            ;;

        3)

            forward_port="$MUX_PORT"
            forward_desc="SSH + V2Ray"

            echo -e "${C_GREEN}ℹ️ DNSTT → SSH + V2Ray multiplexer${C_RESET}"

            configure_dnstt_mux || return 1

            ;;

        *)

            echo -e "${C_RED}❌ Invalid choice. Aborting.${C_RESET}"
            return 1

            ;;

    esac

    local FORWARD_TARGET="127.0.0.1:${forward_port}"



    local NS_DOMAIN=""
    local TUNNEL_DOMAIN=""
    local DNSTT_RECORDS_MANAGED="true"
    local NS_SUBDOMAIN=""
    local TUNNEL_SUBDOMAIN=""
    local HAS_IPV6="false"


    # ================================================================
    # DNS
    # ================================================================

    read -p \
        "👉 Auto-generate DNS records or use custom ones? (auto/custom) [auto]: " \
        dns_choice

    dns_choice=${dns_choice:-auto}

    if [[ "$dns_choice" == "custom" ]]; then

        DNSTT_RECORDS_MANAGED="false"

        read -p \
            "👉 Enter your full nameserver domain (e.g., ns1.yourdomain.com): " \
            NS_DOMAIN

        if [[ -z "$NS_DOMAIN" ]]; then
            echo -e "${C_RED}❌ Nameserver domain cannot be empty.${C_RESET}"
            return 1
        fi

        read -p \
            "👉 Enter your full tunnel domain (e.g., tun.yourdomain.com): " \
            TUNNEL_DOMAIN

        if [[ -z "$TUNNEL_DOMAIN" ]]; then
            echo -e "${C_RED}❌ Tunnel domain cannot be empty.${C_RESET}"
            return 1
        fi

    else

        echo -e "\n${C_BLUE}⚙️ Configuring DNS records for DNSTT...${C_RESET}"

        local SERVER_IPV4
        SERVER_IPV4=$(curl -s -4 --max-time 10 icanhazip.com)

        if ! _is_valid_ipv4 "$SERVER_IPV4"; then

            echo -e "${C_RED}❌ Could not retrieve a valid IPv4 address.${C_RESET}"
            echo -e "${C_DIM}Output: $SERVER_IPV4${C_RESET}"

            return 1
        fi


        local SERVER_IPV6
        SERVER_IPV6=$(curl -s -6 --max-time 5 icanhazip.com 2>/dev/null || true)


        local RANDOM_STR
        RANDOM_STR=$(tr -dc a-z0-9 </dev/urandom | head -c 6)

        NS_SUBDOMAIN="ns-${RANDOM_STR}"
        TUNNEL_SUBDOMAIN="tun-${RANDOM_STR}"

        NS_DOMAIN="${NS_SUBDOMAIN}.${DESEC_DOMAIN}"
        TUNNEL_DOMAIN="${TUNNEL_SUBDOMAIN}.${DESEC_DOMAIN}"


        local API_DATA

        API_DATA=$(printf \
            '[{"subname":"%s","type":"A","ttl":3600,"records":["%s"]},{"subname":"%s","type":"NS","ttl":3600,"records":["%s."]}]' \
            "$NS_SUBDOMAIN" \
            "$SERVER_IPV4" \
            "$TUNNEL_SUBDOMAIN" \
            "$NS_DOMAIN")


        if [[ -n "$SERVER_IPV6" ]]; then

            API_DATA="${API_DATA%]}"

            API_DATA="${API_DATA},$(printf \
                '{"subname":"%s","type":"AAAA","ttl":3600,"records":["%s"]}' \
                "$NS_SUBDOMAIN" \
                "$SERVER_IPV6") ]"

            API_DATA="${API_DATA/ ]/]}"

            HAS_IPV6="true"
        fi


        local CREATE_RESPONSE

        CREATE_RESPONSE=$(curl \
            -s \
            -w "%{http_code}" \
            -X POST \
            "https://desec.io/api/v1/domains/${DESEC_DOMAIN}/rrsets/" \
            -H "Authorization: Token ${DESEC_TOKEN}" \
            -H "Content-Type: application/json" \
            --data "$API_DATA")


        local HTTP_CODE="${CREATE_RESPONSE: -3}"
        local RESPONSE_BODY="${CREATE_RESPONSE:0:${#CREATE_RESPONSE}-3}"


        if [[ "$HTTP_CODE" != "201" ]]; then

            echo -e "${C_RED}❌ Failed to create DNS records.${C_RESET}"
            echo -e "${C_YELLOW}HTTP code: ${HTTP_CODE}${C_RESET}"

            if command -v jq >/dev/null 2>&1; then
                echo "$RESPONSE_BODY" | jq .
            else
                echo "$RESPONSE_BODY"
            fi

            return 1
        fi

        echo -e "${C_GREEN}✅ DNS records created.${C_RESET}"

    fi


    # ================================================================
    # MTU
    # ================================================================

    read -p \
        "👉 Enter MTU value (e.g., 512, 1200) or press [Enter] for default: " \
        mtu_value

    local mtu_string=""

    if [[ "$mtu_value" =~ ^[0-9]+$ ]]; then

        mtu_string=" -mtu ${mtu_value}"

        echo -e "${C_GREEN}ℹ️ Using MTU: ${mtu_value}${C_RESET}"

    else

        mtu_value=""

        echo -e "${C_YELLOW}ℹ️ Using default MTU.${C_RESET}"

    fi



    echo -e "\n${C_BLUE}📥 Downloading DNSTT server binary...${C_RESET}"

    local arch
    local binary_url=""

    arch=$(uname -m)

    case "$arch" in

        x86_64)

            binary_url="https://dnstt.network/dnstt-server-linux-amd64"

            ;;

        aarch64|arm64)

            binary_url="https://dnstt.network/dnstt-server-linux-arm64"

            ;;

        *)

            echo -e "${C_RED}❌ Unsupported architecture: ${arch}${C_RESET}"
            return 1

            ;;

    esac


    if ! curl -fL \
        --connect-timeout 10 \
        --max-time 120 \
        "$binary_url" \
        -o "$DNSTT_BINARY"; then

        echo -e "${C_RED}❌ Failed to download DNSTT binary.${C_RESET}"
        return 1

    fi

    chmod +x "$DNSTT_BINARY"



    echo -e "${C_BLUE}🔐 Generating cryptographic keys...${C_RESET}"

    mkdir -p "$DNSTT_KEYS_DIR"

    if [[ ! -f "$DNSTT_KEYS_DIR/server.key" ]]; then

        "$DNSTT_BINARY" \
            -gen-key \
            -privkey-file "$DNSTT_KEYS_DIR/server.key" \
            -pubkey-file "$DNSTT_KEYS_DIR/server.pub"

        if [[ ! -f "$DNSTT_KEYS_DIR/server.key" ]]; then

            echo -e "${C_RED}❌ Failed to generate DNSTT keys.${C_RESET}"
            return 1

        fi

    else

        echo -e "${C_GREEN}✅ Existing DNSTT key retained.${C_RESET}"

    fi


    chmod 600 "$DNSTT_KEYS_DIR/server.key"

    local PUBLIC_KEY
    PUBLIC_KEY=$(cat "$DNSTT_KEYS_DIR/server.pub")


    # ================================================================
    # SERVICE SYSTEMD DNSTT
    # ================================================================

    echo -e "\n${C_BLUE}📝 Creating DNSTT systemd service...${C_RESET}"

    cat > "$DNSTT_SERVICE_FILE" <<EOF
[Unit]
Description=DNSTT - ${forward_desc}
After=network.target

[Service]
Type=simple
User=root
ExecStart=${DNSTT_BINARY} -udp :53${mtu_string} -privkey-file ${DNSTT_KEYS_DIR}/server.key ${TUNNEL_DOMAIN} ${FORWARD_TARGET}
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF



    echo -e "\n${C_BLUE}💾 Saving configuration...${C_RESET}"

    cat > "$DNSTT_CONFIG_FILE" <<EOF
NS_SUBDOMAIN="${NS_SUBDOMAIN}"
TUNNEL_SUBDOMAIN="${TUNNEL_SUBDOMAIN}"
NS_DOMAIN="${NS_DOMAIN}"
TUNNEL_DOMAIN="${TUNNEL_DOMAIN}"
PUBLIC_KEY="${PUBLIC_KEY}"
FORWARD_DESC="${forward_desc}"
FORWARD_TARGET="${FORWARD_TARGET}"
DNSTT_RECORDS_MANAGED="${DNSTT_RECORDS_MANAGED}"
HAS_IPV6="${HAS_IPV6}"
MTU_VALUE="${mtu_value}"
EOF


    systemctl daemon-reload

    systemctl enable dnstt.service >/dev/null 2>&1
    systemctl restart dnstt.service

    sleep 2


    if systemctl is-active --quiet dnstt.service; then

        echo
        echo -e "${C_GREEN}==============================================${C_RESET}"
        echo -e "${C_GREEN}✅ DNSTT installation successful${C_RESET}"
        echo -e "${C_GREEN}==============================================${C_RESET}"

        echo -e "   Domain : ${C_YELLOW}${TUNNEL_DOMAIN}${C_RESET}"
        echo -e "   Mode   : ${C_YELLOW}${forward_desc}${C_RESET}"
        echo -e "   Target : ${C_YELLOW}${FORWARD_TARGET}${C_RESET}"

        if [[ "$fwd_choice" == "3" ]]; then
            echo -e "   SSH    : ${C_YELLOW}127.0.0.1:22${C_RESET}"
            echo -e "   V2Ray  : ${C_YELLOW}127.0.0.1:8787${C_RESET}"
        fi

        echo

        show_dnstt_details

    else

        echo -e "${C_RED}❌ DNSTT service failed to start.${C_RESET}"

        journalctl \
            -u dnstt.service \
            -n 30 \
            --no-pager

        return 1

    fi
}

uninstall_dnstt() {
    clear
    show_banner
    
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling DNSTT ---${C_RESET}"
    
    
    local MUX_SERVICE_FILE="/etc/systemd/system/dnstt-mux.service"
    local MUX_CONFIG="/etc/haproxy/haproxy-dnstt-mux.cfg"
    local DNSTT_CLIENT_BINARY="/usr/local/bin/dnstt-client"
    
    
    if [ ! -f "$DNSTT_SERVICE_FILE" ] && [ ! -f "$MUX_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ DNSTT does not appear to be installed.${C_RESET}"
        return 0
    fi
    

    local confirm="y"
    if [[ "$UNINSTALL_MODE" != "silent" ]]; then
        echo -e "\n${C_YELLOW}⚠️ Warning: This operation will remove:${C_RESET}"
        echo -e "  • DNSTT service"
        echo -e "  • HAProxy multiplexer (if present)"
        echo -e "  • All cryptographic keys"
        echo -e "  • DNS records (if they were auto-generated)"
        echo -e "  • The DNSTT client (/usr/local/bin/dnstt-client)"
        echo
        read -p "👉 Are you sure you want to uninstall DNSTT? (y/n): " confirm
    fi
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"
        return 0
    fi
    
  
    
    echo -e "\n${C_BLUE}🛑 Stopping and disabling services...${C_RESET}"
    
    # Stop DNSTT
    if systemctl is-active --quiet dnstt.service 2>/dev/null; then
        systemctl stop dnstt.service >/dev/null 2>&1
        echo -e "${C_GREEN}✅ DNSTT stopped${C_RESET}"
    fi
    systemctl disable dnstt.service >/dev/null 2>&1
    
    # Stop the multiplexer
    if systemctl is-active --quiet dnstt-mux.service 2>/dev/null; then
        systemctl stop dnstt-mux.service >/dev/null 2>&1
        echo -e "${C_GREEN}✅ Multiplexer stopped${C_RESET}"
    fi
    systemctl disable dnstt-mux.service >/dev/null 2>&1
    
    # ================================================================
    # REMOVING DNS RECORDS
    # ================================================================
    
    if [ -f "$DNSTT_CONFIG_FILE" ]; then
        source "$DNSTT_CONFIG_FILE"
        
        if [[ "$DNSTT_RECORDS_MANAGED" == "true" ]]; then
            echo -e "\n${C_BLUE}🗑️ Removing auto-generated DNS records...${C_RESET}"
            
            # Remove NS records
            if [[ -n "$TUNNEL_SUBDOMAIN" ]] && [[ -n "$DESEC_DOMAIN" ]] && [[ -n "$DESEC_TOKEN" ]]; then
                # Remove the wildcard NS record if present
                if [[ "$TUNNEL_SUBDOMAIN" == "*" ]]; then
                    curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/%2A/NS/" \
                        -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ Wildcard NS record removed${C_RESET}"
                else
                    curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$TUNNEL_SUBDOMAIN/NS/" \
                        -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ NS record removed${C_RESET}"
                fi
                
                # Remove A records
                curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$NS_SUBDOMAIN/A/" \
                    -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1
                echo -e "${C_GREEN}✅ A record removed${C_RESET}"
                
                # Remove AAAA records if present
                if [[ "$HAS_IPV6" == "true" ]]; then
                    curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$NS_SUBDOMAIN/AAAA/" \
                        -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ AAAA record removed${C_RESET}"
                fi
            fi
        else
            echo -e "\n${C_YELLOW}⚠️ DNS records were configured manually.${C_RESET}"
            echo -e "${C_YELLOW}💡 Please remove them manually from your DNS provider.${C_RESET}"
            echo -e "   Affected domains:"
            [[ -n "$NS_DOMAIN" ]] && echo -e "   • $NS_DOMAIN"
            [[ -n "$TUNNEL_DOMAIN" ]] && echo -e "   • $TUNNEL_DOMAIN"
        fi
    fi
    
    # ================================================================
    # REMOVING SERVICE FILES
    # ================================================================
    
    echo -e "\n${C_BLUE}🗑️ Removing service files...${C_RESET}"
    
    # Remove service files
    rm -f "$DNSTT_SERVICE_FILE"
    rm -f "$MUX_SERVICE_FILE"
    echo -e "${C_GREEN}✅ Service files removed${C_RESET}"
    
    # Remove HAProxy configuration
    if [[ -f "$MUX_CONFIG" ]]; then
        rm -f "$MUX_CONFIG"
        echo -e "${C_GREEN}✅ HAProxy configuration removed${C_RESET}"
    fi
    
    # ================================================================
    # REMOVING BINARIES
    # ================================================================
    
    echo -e "\n${C_BLUE}🗑️ Removing binaries...${C_RESET}"
    
    # Remove the server binary
    if [[ -f "$DNSTT_BINARY" ]]; then
        rm -f "$DNSTT_BINARY"
        echo -e "${C_GREEN}✅ DNSTT server binary removed${C_RESET}"
    fi
    
    # Remove the client binary
    if [[ -f "$DNSTT_CLIENT_BINARY" ]]; then
        rm -f "$DNSTT_CLIENT_BINARY"
        echo -e "${C_GREEN}✅ DNSTT client binary removed${C_RESET}"
    fi
    

    
    echo -e "\n${C_BLUE}🗑️ Removing cryptographic keys...${C_RESET}"
    if [[ -d "$DNSTT_KEYS_DIR" ]]; then
        rm -rf "$DNSTT_KEYS_DIR"
        echo -e "${C_GREEN}✅ Keys removed${C_RESET}"
    fi
    

    
    echo -e "\n${C_BLUE}🗑️ Removing configuration files...${C_RESET}"
    rm -f "$DNSTT_CONFIG_FILE"
    rm -f /root/.ssh_slowdns_config 2>/dev/null
    rm -f /root/.v2ray_slowdns_config 2>/dev/null
    echo -e "${C_GREEN}✅ Configuration files removed${C_RESET}"
    

    echo -e "\n${C_YELLOW}ℹ️ Restoring DNS configuration...${C_RESET}"
    
    # Make /etc/resolv.conf editable again
    chattr -i /etc/resolv.conf >/dev/null 2>&1
    
    # Restore systemd-resolved if available
    if systemctl list-unit-files | grep -q systemd-resolved; then
        echo -e "${C_BLUE}🔄 Re-enabling systemd-resolved...${C_RESET}"
        systemctl enable systemd-resolved >/dev/null 2>&1
        systemctl start systemd-resolved >/dev/null 2>&1
        echo -e "${C_GREEN}✅ systemd-resolved re-enabled${C_RESET}"
    else
        # Configure a default DNS
        cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
        echo -e "${C_GREEN}✅ DNS configured with 8.8.8.8 and 1.1.1.1${C_RESET}"
    fi
    

    
    echo -e "\n${C_BLUE}🧹 Reloading systemd...${C_RESET}"
    systemctl daemon-reload
    
    # Check that the ports were freed
    echo -e "\n${C_BLUE}🔍 Checking ports...${C_RESET}"
    if ! ss -lunp 2>/dev/null | grep -q ':53\s'; then
        echo -e "${C_GREEN}✅ Port 53 freed${C_RESET}"
    else
        echo -e "${C_YELLOW}⚠️ Port 53 is still in use by:${C_RESET}"
        ss -lunp 2>/dev/null | grep ':53\s'
    fi
    

    
    echo -e "\n${C_GREEN}==============================================${C_RESET}"
    echo -e "${C_GREEN}✅ DNSTT was uninstalled successfully${C_RESET}"
    echo -e "${C_GREEN}==============================================${C_RESET}"
    
    echo -e "\n${C_BLUE}Uninstallation summary:${C_RESET}"
    echo -e "  ${C_GREEN}✓${C_RESET} Services stopped and disabled"
    echo -e "  ${C_GREEN}✓${C_RESET} DNS records removed (if auto-generated)"
    echo -e "  ${C_GREEN}✓${C_RESET} Service files removed"
    echo -e "  ${C_GREEN}✓${C_RESET} Binaries removed"
    echo -e "  ${C_GREEN}✓${C_RESET} Cryptographic keys removed"
    echo -e "  ${C_GREEN}✓${C_RESET} DNS configuration restored"
    
    # Show logs if present
    if journalctl -u dnstt.service --no-pager 2>/dev/null | grep -q .; then
        echo -e "\n${C_DIM}💡 Logs are still available via:${C_RESET}"
        echo -e "   ${C_DIM}journalctl -u dnstt.service${C_RESET}"
    fi
    
    echo -e "\n${C_YELLOW}ℹ️ Remember to:${C_RESET}"
    echo -e "  • Check that port 53 is available"
    echo -e "  • Remove iptables/firewall rules if needed"
    echo -e "  • Restart the server if issues persist"
    echo
}


install_falcon_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🦅 Installing Falcon Proxy (Websockets/Socks) ---${C_RESET}"
    
    if [ -f "$FALCONPROXY_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ Falcon Proxy is already installed.${C_RESET}"
        if [ -f "$FALCONPROXY_CONFIG_FILE" ]; then
            source "$FALCONPROXY_CONFIG_FILE"
            echo -e "   It is configured to run on port(s): ${C_YELLOW}$PORTS${C_RESET}"
            echo -e "   Installed Version: ${C_YELLOW}${INSTALLED_VERSION:-Unknown}${C_RESET}"
            echo -e "   Version Type: ${C_YELLOW}${VERSION_TYPE:-Unknown}${C_RESET}"
        fi
        read -p "👉 Do you want to reinstall/update? (y/n): " confirm_reinstall
        if [[ "$confirm_reinstall" != "y" ]]; then return; fi
    fi

    echo -e "\n${C_GREEN}⚙️ Detecting system architecture...${C_RESET}"
    local arch=$(uname -m)
    local binary_name=""
    if [[ "$arch" == "x86_64" ]]; then
        binary_name="falconproxy"
        echo -e "${C_BLUE}ℹ️ Detected x86_64 (amd64) architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_name="falconproxyarm"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Unsupported architecture: $arch. Cannot install Falcon Proxy.${C_RESET}"
        return
    fi

    # --- Sélection de la version ---
    echo -e "\n${C_CYAN}📦 Select Falcon Proxy version:${C_RESET}"
    echo -e "  ${C_GREEN}[1]${C_RESET} 🚀 Fast Rust Edition (High Performance - Multi-threaded)"
    echo -e "  ${C_GREEN}[2]${C_RESET} 🔌 WebSocket v2.0 Edition (WebSocket & WSS Support)"
    echo -e "  ${C_RED} [0]${C_RESET} ↩️ Cancel"
    
    local version_choice
    while true; do
        read -p "👉 Enter your choice [1]: " version_choice
        version_choice=${version_choice:-1}
        if [[ "$version_choice" == "0" ]]; then return; fi
        if [[ "$version_choice" =~ ^[12]$ ]]; then
            break
        else
            echo -e "${C_RED}❌ Invalid selection. Please choose 1 or 2.${C_RESET}"
        fi
    done

    # --- Déterminer les chemins selon la version choisie ---
    local SELECTED_VERSION=""
    local VERSION_TYPE=""
    local version_folder=""
    
    case $version_choice in
        1)
            VERSION_TYPE="fast-rust"
            version_folder="fast-rust"
            SELECTED_VERSION="v1.0.0"
            echo -e "\n${C_GREEN}🚀 Selected: Fast Rust Edition${C_RESET}"
            echo -e "${C_BLUE}ℹ️ Optimized for high performance with Rust's zero-cost abstractions${C_RESET}"
            ;;
        2)
            VERSION_TYPE="websocket-v2"
            version_folder="websocket-v2"
            SELECTED_VERSION="v2.0.0"
            echo -e "\n${C_GREEN}🔌 Selected: WebSocket v2.0 Edition${C_RESET}"
            echo -e "${C_BLUE}ℹ️ Full WebSocket support with WSS (Secure WebSocket)${C_RESET}"
            ;;
    esac

    # --- Vérifier si le binaire existe en local ---
    local local_binary_path="$FALCONPROXY_BUNDLE_DIR/$version_folder/$binary_name"
    local use_bundled=false
    
    if [ -f "$local_binary_path" ]; then
        use_bundled=true
        echo -e "\n${C_GREEN}📦 Binaire local détecté dans ${FALCONPROXY_BUNDLE_DIR}/$version_folder/, installation hors-ligne.${C_RESET}"
        
        if [ -f "$FALCONPROXY_BUNDLE_DIR/$version_folder/VERSION" ]; then
            SELECTED_VERSION=$(cat "$FALCONPROXY_BUNDLE_DIR/$version_folder/VERSION")
            echo -e "${C_BLUE}ℹ️ Version: $SELECTED_VERSION${C_RESET}"
        fi
    fi

    # --- Gestion des ports ---
    local default_ports=""
    if [[ "$VERSION_TYPE" == "fast-rust" ]]; then
        default_ports="8080"
        echo -e "\n${C_CYAN}💡 Fast Rust supports multiple ports for better concurrency${C_RESET}"
    else
        default_ports="8080 8443"
        echo -e "\n${C_CYAN}💡 WebSocket v2.0 supports HTTP, WebSocket, and WSS${C_RESET}"
    fi
    
    local ports
    read -p "👉 Enter port(s) for Falcon Proxy (e.g., 8080 or 9999) [$default_ports]: " ports
    ports=${ports:-$default_ports}

    local port_array=($ports)
    for port in "${port_array[@]}"; do
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo -e "\n${C_RED}❌ Invalid port number: $port. Aborting.${C_RESET}"
            return
        fi
        check_and_free_ports "$port" || return
        check_and_open_firewall_port "$port" tcp || return
    done

    # --- Installation du binaire ---
    if $use_bundled; then
        echo -e "\n${C_GREEN}📥 Copie du binaire local Falcon Proxy ($binary_name)...${C_RESET}"
        # Auto-réparation : une ancienne version buguée pouvait laisser un DOSSIER à
        # l'emplacement de FALCONPROXY_BINARY (au lieu d'un simple binaire), ce qui
        # faisait échouer la copie.
        [ -d "$FALCONPROXY_BINARY" ] && rm -rf "$FALCONPROXY_BINARY"
        cp -f "$local_binary_path" "$FALCONPROXY_BINARY"
        if [ $? -ne 0 ]; then
            echo -e "\n${C_RED}❌ Échec de la copie du binaire local ${local_binary_path}.${C_RESET}"
            return
        fi
    else
        echo -e "\n${C_BLUE}🌐 Téléchargement depuis GitHub...${C_RESET}"
        
        # Construire l'URL de téléchargement
        local download_url=""
        if [[ "$VERSION_TYPE" == "fast-rust" ]]; then
            download_url="https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/download/$SELECTED_VERSION/${binary_name}-fast"
        else
            download_url="https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/download/$SELECTED_VERSION/${binary_name}-ws2"
        fi
        
        echo -e "${C_YELLOW}ℹ️ Downloading from: $download_url${C_RESET}"
        
        [ -d "$FALCONPROXY_BINARY" ] && rm -rf "$FALCONPROXY_BINARY"
        wget -q --show-progress -O "$FALCONPROXY_BINARY" "$download_url"
        if [ $? -ne 0 ]; then
            echo -e "\n${C_RED}❌ Failed to download the binary. Please ensure version $SELECTED_VERSION has the correct asset.${C_RESET}"
            return
        fi
    fi
    
    chmod +x "$FALCONPROXY_BINARY"

    # --- Création du service systemd ---
    echo -e "\n${C_GREEN}📝 Creating systemd service file...${C_RESET}"
    
    local service_desc="Falcon Proxy"
    if [[ "$VERSION_TYPE" == "fast-rust" ]]; then
        service_desc="Falcon Proxy - Fast Rust Edition"
    else
        service_desc="Falcon Proxy - WebSocket v2.0 Edition"
    fi
    
    cat > "$FALCONPROXY_SERVICE_FILE" <<EOF
[Unit]
Description=$service_desc ($SELECTED_VERSION)
After=network.target

[Service]
User=root
Type=simple
ExecStart=$FALCONPROXY_BINARY -p $ports
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF

    echo -e "\n${C_GREEN}💾 Saving configuration...${C_RESET}"
    cat > "$FALCONPROXY_CONFIG_FILE" <<EOF
PORTS="$ports"
INSTALLED_VERSION="$SELECTED_VERSION"
VERSION_TYPE="$VERSION_TYPE"
ARCHITECTURE="$arch"
EOF

    echo -e "\n${C_GREEN}▶️ Enabling and starting Falcon Proxy service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable falconproxy.service
    systemctl restart falconproxy.service
    sleep 2
    
    if systemctl is-active --quiet falconproxy; then
        echo -e "\n${C_GREEN}✅ SUCCESS: Falcon Proxy $SELECTED_VERSION is installed and active.${C_RESET}"
        echo -e "   Type: ${C_YELLOW}$VERSION_TYPE${C_RESET}"
        echo -e "   Listening on port(s): ${C_YELLOW}$ports${C_RESET}"
        echo -e "   Binary: ${C_YELLOW}$FALCONPROXY_BINARY${C_RESET}"
        
        # Afficher des informations spécifiques selon la version
        if [[ "$VERSION_TYPE" == "websocket-v2" ]]; then
            echo -e "\n${C_YELLOW}🔌 WebSocket v2.0 endpoints:${C_RESET}"
            echo -e "  • HTTP:       http://localhost:${port_array[0]}"
            if [ ${#port_array[@]} -gt 1 ]; then
                echo -e "  • WebSocket:  ws://localhost:${port_array[1]}"
                echo -e "  • WSS:        wss://your-domain:${port_array[1]}"
            fi
        else
            echo -e "\n${C_YELLOW}🚀 Fast Rust endpoints:${C_RESET}"
            echo -e "  • Proxy:      http://localhost:${port_array[0]}"
            if [ ${#port_array[@]} -gt 1 ]; then
                echo -e "  • Additional ports: ${C_YELLOW}${ports}${C_RESET}"
            fi
        fi
    else
        echo -e "\n${C_RED}❌ ERROR: Falcon Proxy service failed to start.${C_RESET}"
        echo -e "${C_YELLOW}ℹ️ Displaying last 15 lines of the service log for diagnostics:${C_RESET}"
        journalctl -u falconproxy.service -n 15 --no-pager
    fi
}

uninstall_falcon_proxy() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling Falcon Proxy ---${C_RESET}"
    if [ ! -f "$FALCONPROXY_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ Falcon Proxy is not installed, skipping.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling Falcon Proxy service...${C_RESET}"
    systemctl stop falconproxy.service >/dev/null 2>&1
    systemctl disable falconproxy.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Removing service file...${C_RESET}"
    rm -f "$FALCONPROXY_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Removing binary and config files...${C_RESET}"
    rm -f "$FALCONPROXY_BINARY"
    rm -f "$FALCONPROXY_CONFIG_FILE"
    echo -e "${C_GREEN}✅ Falcon Proxy has been uninstalled successfully.${C_RESET}"
}

# --- PY SOCKS/WS Proxy Installation Logic ---
_write_pyproxy_script() {
    mkdir -p "$PYPROXY_DIR"
    cat > "$PYPROXY_SCRIPT" <<'PYEOF'
#!/usr/bin/env python3
# encoding: utf-8
# NOVA XTUNNEL - CONNECT/SOCKS-over-HTTP tunnel (Python 3 port of proxy.py / wsproxy.py)
import socket
import threading
import select
import sys
import argparse

BUFLEN = 8196 * 8
TIMEOUT = 60


class Server(threading.Thread):
    def __init__(self, host, port, response, default_host):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.response = response
        self.default_host = default_host
        self.threads = []
        self.threads_lock = threading.Lock()
        self.log_lock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        self.soc.bind((self.host, self.port))
        self.soc.listen(5)
        self.running = True
        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(True)
                except socket.timeout:
                    continue
                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.add_conn(conn)
        finally:
            self.running = False
            self.soc.close()

    def print_log(self, log):
        with self.log_lock:
            print(log, flush=True)

    def add_conn(self, conn):
        with self.threads_lock:
            if self.running:
                self.threads.append(conn)

    def remove_conn(self, conn):
        with self.threads_lock:
            if conn in self.threads:
                self.threads.remove(conn)

    def close(self):
        self.running = False
        with self.threads_lock:
            for c in list(self.threads):
                c.close()


class ConnectionHandler(threading.Thread):
    def __init__(self, sock_client, server, addr):
        threading.Thread.__init__(self)
        self.client_closed = False
        self.target_closed = True
        self.client = sock_client
        self.target = None
        self.server = server
        self.log = 'Connection: ' + str(addr)

    def close(self):
        try:
            if not self.client_closed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except OSError:
            pass
        finally:
            self.client_closed = True
        try:
            if not self.target_closed and self.target:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except OSError:
            pass
        finally:
            self.target_closed = True

    def run(self):
        try:
            client_buffer = self.client.recv(BUFLEN)
            host_port = self.find_header(client_buffer, b'X-Real-Host')
            if not host_port:
                host_port = self.server.default_host

            if self.find_header(client_buffer, b'X-Split'):
                self.client.recv(BUFLEN)

            if host_port:
                self.method_connect(host_port)
            else:
                self.server.print_log('- No X-Real-Host!')
                self.client.send(b'HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            self.log += ' - error: ' + str(e)
            self.server.print_log(self.log)
        finally:
            self.close()
            self.server.remove_conn(self)

    @staticmethod
    def find_header(head, header):
        idx = head.find(header + b': ')
        if idx == -1:
            return ''
        idx = head.find(b':', idx)
        head = head[idx + 2:]
        end = head.find(b'\r\n')
        if end == -1:
            return ''
        return head[:end].decode(errors='ignore')

    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i + 1:])
            host = host[:i]
        else:
            port = 443

        addr_info = socket.getaddrinfo(host, port)[0]
        soc_family, soc_type, proto, _, address = addr_info
        self.target = socket.socket(soc_family, soc_type, proto)
        self.target_closed = False
        self.target.connect(address)

    def method_connect(self, path):
        self.log += ' - CONNECT ' + path
        self.connect_target(path)
        self.client.sendall(self.server.response.encode())
        self.server.print_log(self.log)
        self.do_connect()

    def do_connect(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            recv, _, err = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
                    try:
                        data = in_.recv(BUFLEN)
                        if data:
                            if in_ is self.target:
                                self.client.send(data)
                            else:
                                while data:
                                    sent = self.target.send(data)
                                    data = data[sent:]
                            count = 0
                        else:
                            error = True
                            break
                    except OSError:
                        error = True
                        break
            if count >= TIMEOUT or error:
                break


def main():
    parser = argparse.ArgumentParser(description='NOVA XTUNNEL - PY SOCKS/WS proxy')
    parser.add_argument('-b', '--bind', default='0.0.0.0')
    parser.add_argument('-p', '--port', type=int, required=True)
    parser.add_argument('--response-code', default='101')
    parser.add_argument('--response-msg', default='@NOVAXTUNNEL')
    parser.add_argument('--default-host', default='127.0.0.1:22')
    args = parser.parse_args()

    response = "HTTP/1.1 {} {}\r\n\r\n".format(args.response_code, args.response_msg)

    print("NOVA XTUNNEL PY Proxy - listening on {}:{}".format(args.bind, args.port))
    server = Server(args.bind, args.port, response, args.default_host)
    server.start()
    try:
        while True:
            server.join(2)
            if not server.is_alive():
                break
    except KeyboardInterrupt:
        print('Stopping...')
        server.close()


if __name__ == '__main__':
    main()
PYEOF
    chmod +x "$PYPROXY_SCRIPT"
}

install_pyproxy() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🐍 Install PY SOCKS/WS Proxy (legacy) ---${C_RESET}"

    if [ -f "$PYPROXY_SOCKS_SERVICE" ] || [ -f "$PYPROXY_WS_SERVICE" ]; then
        echo -e "${C_YELLOW}ℹ️ PY SOCKS/WS Proxy is already installed.${C_RESET}"
        return
    fi

    if ! command -v python3 &> /dev/null; then
        echo -e "${C_YELLOW}⚙️ Installing python3...${C_RESET}"
        apt-get update -y >/dev/null 2>&1
        apt-get install -y python3 >/dev/null 2>&1
    fi

    local socks_port ws_port
    read -p "👉 Port for SOCKS/CONNECT proxy (HTTP 200 response) [8888]: " socks_port
    socks_port=${socks_port:-8888}
    read -p "👉 Port for WebSocket-style proxy (HTTP 101 response) [444]: " ws_port
    ws_port=${ws_port:-444}

    for p in "$socks_port" "$ws_port"; do
        if ! [[ "$p" =~ ^[0-9]+$ ]] || [ "$p" -lt 1 ] || [ "$p" -gt 65535 ]; then
            echo -e "\n${C_RED}❌ Invalid port number: $p. Aborting.${C_RESET}"
            return
        fi
    done
    if [ "$socks_port" == "$ws_port" ]; then
        echo -e "\n${C_RED}❌ SOCKS and WebSocket ports must be different.${C_RESET}"
        return
    fi
    check_and_free_ports "$socks_port" "$ws_port" || return
    check_and_open_firewall_port "$socks_port" tcp || return
    check_and_open_firewall_port "$ws_port" tcp || return

    echo -e "\n${C_GREEN}📝 Writing proxy script (Python 3)...${C_RESET}"
    _write_pyproxy_script

    echo -e "${C_GREEN}📝 Creating systemd services...${C_RESET}"
    cat > "$PYPROXY_SOCKS_SERVICE" <<EOF
[Unit]
Description=NOVA XTUNNEL PY SOCKS Proxy
After=network.target

[Service]
User=root
Type=simple
ExecStart=/usr/bin/python3 $PYPROXY_SCRIPT -p $socks_port --response-code 200 --response-msg @Labokingfreesurf --default-host 0.0.0.0:22
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF

    cat > "$PYPROXY_WS_SERVICE" <<EOF
[Unit]
Description=NOVA XTUNNEL PY WebSocket Proxy
After=network.target

[Service]
User=root
Type=simple
ExecStart=/usr/bin/python3 $PYPROXY_SCRIPT -p $ws_port --response-code 101 --response-msg @Labokingfreesurf --default-host 127.0.0.1:22
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF

    echo "SOCKS_PORT=$socks_port" > "$PYPROXY_CONFIG_FILE"
    echo "WS_PORT=$ws_port" >> "$PYPROXY_CONFIG_FILE"

    systemctl daemon-reload
    systemctl enable pyproxy-socks.service pyproxy-ws.service >/dev/null 2>&1
    systemctl start pyproxy-socks.service pyproxy-ws.service
    sleep 2

    if systemctl is-active --quiet pyproxy-socks.service && systemctl is-active --quiet pyproxy-ws.service; then
        echo -e "\n${C_GREEN}✅ SUCCESS: PY SOCKS/WS Proxy installed and active.${C_RESET}"
        echo -e "   - SOCKS proxy port: ${C_YELLOW}$socks_port${C_RESET} (HTTP 200)"
        echo -e "   - WebSocket proxy port: ${C_YELLOW}$ws_port${C_RESET} (HTTP 101)"
    else
        echo -e "\n${C_RED}❌ ERROR: one of the services failed to start.${C_RESET}"
        journalctl -u pyproxy-socks.service -u pyproxy-ws.service -n 20 --no-pager
    fi
}

uninstall_pyproxy() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling PY SOCKS/WS Proxy ---${C_RESET}"
    if [ ! -f "$PYPROXY_SOCKS_SERVICE" ] && [ ! -f "$PYPROXY_WS_SERVICE" ]; then
        echo -e "${C_YELLOW}ℹ️ PY SOCKS/WS Proxy is not installed, skipping.${C_RESET}"
        return
    fi
    systemctl stop pyproxy-socks.service pyproxy-ws.service >/dev/null 2>&1
    systemctl disable pyproxy-socks.service pyproxy-ws.service >/dev/null 2>&1
    rm -f "$PYPROXY_SOCKS_SERVICE" "$PYPROXY_WS_SERVICE"
    systemctl daemon-reload
    rm -rf "$PYPROXY_DIR"
    rm -f "$PYPROXY_CONFIG_FILE"
    echo -e "${C_GREEN}✅ PY SOCKS/WS Proxy has been uninstalled successfully.${C_RESET}"
}

# --- ZiVPN Installation Logic ---
install_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing ZiVPN (UDP/VPN) ---${C_RESET}"
    
    if [ -f "$ZIVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN is already installed.${C_RESET}"
        return
    fi

.
    echo -e "\n${C_GREEN}⚙️ Checking system architecture...${C_RESET}"
    local arch=$(uname -m)
    local zivpn_url=""
    
    if [[ "$arch" == "x86_64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Detected AMD64/x86_64 architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    elif [[ "$arch" == "armv7l" || "$arch" == "arm" ]]; then
         zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm"
         echo -e "${C_BLUE}ℹ️ Detected ARM architecture.${C_RESET}"
    else
        echo -e "${C_RED}❌ Unsupported architecture: $arch${C_RESET}"
        return
    fi

    echo -e "\n${C_GREEN}📦 Downloading ZiVPN binary...${C_RESET}"
    if ! wget -q --show-progress -O "$ZIVPN_BIN" "$zivpn_url"; then
        echo -e "${C_RED}❌ Download failed. Check internet connection.${C_RESET}"
        return
    fi
    chmod +x "$ZIVPN_BIN"

    echo -e "\n${C_GREEN}⚙️ Configuring ZIVPN...${C_RESET}"
    mkdir -p "$ZIVPN_DIR"
    
    # Generate Certificates
    echo -e "${C_BLUE}🔐 Generating self-signed certificates...${C_RESET}"
    if ! command -v openssl &>/dev/null; then
        ff_apt_install openssl >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to install openssl for ZiVPN certificate generation.${C_RESET}"
            return
        }
    fi
    
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
        -keyout "$ZIVPN_KEY_FILE" -out "$ZIVPN_CERT_FILE" 2>/dev/null

    if [ ! -f "$ZIVPN_CERT_FILE" ]; then
        echo -e "${C_RED}❌ Failed to generate certificates.${C_RESET}"
        return
    fi

    # System Tuning
    echo -e "${C_BLUE}🔧 Tuning system network parameters...${C_RESET}"
    sysctl -w net.core.rmem_max=16777216 >/dev/null
    sysctl -w net.core.wmem_max=16777216 >/dev/null

    # Create Service
    echo -e "${C_BLUE}📝 Creating systemd service file...${C_RESET}"
    cat <<EOF > "$ZIVPN_SERVICE_FILE"
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$ZIVPN_DIR
ExecStart=$ZIVPN_BIN server -c $ZIVPN_CONFIG_FILE
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    # Configure Passwords
    echo -e "\n${C_YELLOW}🔑 ZiVPN Password Setup${C_RESET}"
    read -p "👉 Enter passwords separated by commas (e.g., user1,user2) [Default: 'zi']: " input_config
    
    if [ -n "$input_config" ]; then
        IFS=',' read -r -a config_array <<< "$input_config"
        # Ensure array format for JSON
        json_passwords=$(printf '"%s",' "${config_array[@]}")
        json_passwords="[${json_passwords%,}]"
    else
        json_passwords='["zi"]'
    fi

    # Create Config File
    cat <<EOF > "$ZIVPN_CONFIG_FILE"
{
  "listen": ":${ZIVPN_LISTEN_PORT}",
   "cert": "$ZIVPN_CERT_FILE",
   "key": "$ZIVPN_KEY_FILE",
   "obfs":"zivpn",
   "auth": {
    "mode": "passwords", 
    "config": $json_passwords
  }
}
EOF

    echo -e "\n${C_GREEN}🚀 Starting ZiVPN Service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable zivpn.service
    systemctl start zivpn.service

    # Port Forwarding / Firewall
    echo -e "${C_BLUE}🔥 Configuring Firewall Rules (Redirecting ${ZIVPN_RANGE_START}-${ZIVPN_RANGE_END} -> ${ZIVPN_LISTEN_PORT})...${C_RESET}"
    _ff_flush_dnat_to_port "$ZIVPN_LISTEN_PORT"
    check_and_open_firewall_udp_range "$ZIVPN_RANGE_START" "$ZIVPN_RANGE_END" "$ZIVPN_LISTEN_PORT"
    if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
        ufw allow "${ZIVPN_LISTEN_PORT}/udp" >/dev/null
    fi

    # Cleanup
    rm -f zi.sh zi2.sh 2>/dev/null

    if systemctl is-active --quiet zivpn.service; then
        echo -e "\n${C_GREEN}✅ ZiVPN Installed Successfully!${C_RESET}"
        echo -e "   - UDP Port: ${ZIVPN_LISTEN_PORT} (Direct)"
        echo -e "   - UDP Ports: ${ZIVPN_RANGE_START}-${ZIVPN_RANGE_END} (Forwarded)"
    else
        echo -e "\n${C_RED}❌ ZiVPN Service failed to start. Check logs: journalctl -u zivpn.service${C_RESET}"
    fi
}

uninstall_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Uninstall ZiVPN ---${C_RESET}"
    
    if [ ! -f "$ZIVPN_SERVICE_FILE" ] && [ ! -f "$ZIVPN_BIN" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN does not appear to be installed.${C_RESET}"
        return
    fi

    read -p "👉 Are you sure you want to uninstall ZiVPN? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "${C_YELLOW}Cancelled.${C_RESET}"; return; fi

    echo -e "\n${C_BLUE}🛑 Stopping services...${C_RESET}"
    systemctl stop zivpn.service 2>/dev/null
    systemctl disable zivpn.service 2>/dev/null
    
    echo -e "${C_BLUE}🗑️ Removing files...${C_RESET}"
    rm -f "$ZIVPN_SERVICE_FILE"
    rm -rf "$ZIVPN_DIR"
    rm -f "$ZIVPN_BIN"
    rm -f "$ZIVPN_CLEANUP_SCRIPT"
    (crontab -l 2>/dev/null | grep -v "$ZIVPN_CLEANUP_CRON_MARKER") | crontab - 2>/dev/null
    
    systemctl daemon-reload
    
    # Clean cache (from original uninstall script logic)
    echo -e "${C_BLUE}🧹 Cleaning memory cache...${C_RESET}"
    sync; echo 3 > /proc/sys/vm/drop_caches

    echo -e "\n${C_GREEN}✅ ZiVPN Uninstalled Successfully.${C_RESET}"
}

_zivpn_meta_init() {
    mkdir -p "$ZIVPN_DIR" 2>/dev/null
    if [ ! -f "$ZIVPN_META_FILE" ]; then
        echo '{}' > "$ZIVPN_META_FILE"
    fi
}

# Get a metadata field ("expires" or "quota_gb") for a password. Prints "never" / "unlimited" if unset.
_zivpn_meta_get() {
    local pwd="$1" field="$2" default_val="$3"
    _zivpn_meta_init
    local val
    val=$(jq -r --arg p "$pwd" --arg f "$field" '.[$p][$f] // empty' "$ZIVPN_META_FILE" 2>/dev/null)
    [ -z "$val" ] && val="$default_val"
    echo "$val"
}

_zivpn_meta_set() {
    local pwd="$1" expires="$2" quota_gb="$3"
    _zivpn_meta_init
    local today; today=$(date +%F)
    jq --arg p "$pwd" --arg e "$expires" --arg q "$quota_gb" --arg c "$today" \
        '.[$p] = {expires: $e, quota_gb: $q, created: (.[$p].created // $c)}' \
        "$ZIVPN_META_FILE" > /tmp/zivpn_meta.json && mv /tmp/zivpn_meta.json "$ZIVPN_META_FILE"
}

_zivpn_meta_rename() {
    local old_pwd="$1" new_pwd="$2"
    _zivpn_meta_init
    jq --arg o "$old_pwd" --arg n "$new_pwd" \
        'if has($o) then .[$n] = .[$o] | del(.[$o]) else . end' \
        "$ZIVPN_META_FILE" > /tmp/zivpn_meta.json && mv /tmp/zivpn_meta.json "$ZIVPN_META_FILE"
}

_zivpn_meta_delete() {
    local pwd="$1"
    _zivpn_meta_init
    jq --arg p "$pwd" 'del(.[$p])' "$ZIVPN_META_FILE" > /tmp/zivpn_meta.json && mv /tmp/zivpn_meta.json "$ZIVPN_META_FILE"
}

# Prompts for an expiration date and a data quota, used by Add/Edit flows.
# Sets globals: _Z_EXPIRES, _Z_QUOTA
_zivpn_prompt_expiry_quota() {
    local default_expires="$1" default_quota="$2"
    _Z_EXPIRES="$default_expires"
    _Z_QUOTA="$default_quota"

    read -r -p "👉 Nombre de jours avant expiration (0 = never, laisser vide = garder '${default_expires}'): " in_days
    if [ -n "$in_days" ]; then
        if [[ "$in_days" == "never" ]] || [[ "$in_days" =~ ^[0-9]+$ && "$in_days" -eq 0 ]]; then
            _Z_EXPIRES="never"
        elif [[ "$in_days" =~ ^[0-9]+$ ]]; then
            _Z_EXPIRES=$(date -d "+${in_days} days" +%F)
        else
            echo -e "${C_YELLOW}⚠️ Valeur invalide, on garde '${default_expires}'.${C_RESET}"
        fi
    fi

    read -r -p "👉 Data quota in GB, 'unlimited', or blank to keep '${default_quota}': " in_quota
    if [ -n "$in_quota" ]; then
        if [[ "$in_quota" == "unlimited" ]]; then
            _Z_QUOTA="unlimited"
        elif [[ "$in_quota" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            _Z_QUOTA="$in_quota"
        else
            echo -e "${C_YELLOW}⚠️ Invalid quota, keeping '${default_quota}'.${C_RESET}"
        fi
    fi
}

# Removes any ZiVPN password whose expiry date has passed. Safe to run repeatedly (cron/manual).
zivpn_cleanup_expired_passwords() {
    _zivpn_meta_init
    [ -f "$ZIVPN_CONFIG_FILE" ] || return 0
    command -v jq >/dev/null 2>&1 || return 0

    local today; today=$(date +%F)
    local removed_any=false
    local expired_pwds
    expired_pwds=$(jq -r --arg today "$today" \
        'to_entries[] | select(.value.expires != null and .value.expires != "never" and .value.expires != "" and (.value.expires < $today)) | .key' \
        "$ZIVPN_META_FILE" 2>/dev/null)

    while IFS= read -r pwd; do
        [ -z "$pwd" ] && continue
        jq --arg p "$pwd" '.auth.config -= [$p]' "$ZIVPN_CONFIG_FILE" > /tmp/zivpn.json 2>/dev/null && mv /tmp/zivpn.json "$ZIVPN_CONFIG_FILE"
        _zivpn_meta_delete "$pwd"
        removed_any=true
    done <<< "$expired_pwds"

    if $removed_any; then
        systemctl restart zivpn 2>/dev/null
    fi
}

# Installs a cron job that periodically sweeps expired ZiVPN passwords (additive only,
# does not touch the already-installed zivpn service/binary/config).
_zivpn_install_cleanup_cron() {
    cat > "$ZIVPN_CLEANUP_SCRIPT" << CLEOF
#!/bin/bash
# NOVA XTUNNEL - ZiVPN expired password sweeper
ZIVPN_CONFIG_FILE="$ZIVPN_CONFIG_FILE"
ZIVPN_META_FILE="$ZIVPN_META_FILE"
command -v jq >/dev/null 2>&1 || exit 0
[ -f "\$ZIVPN_CONFIG_FILE" ] || exit 0
[ -f "\$ZIVPN_META_FILE" ] || exit 0
today=\$(date +%F)
removed_any=false
expired_pwds=\$(jq -r --arg today "\$today" \
    'to_entries[] | select(.value.expires != null and .value.expires != "never" and .value.expires != "" and (.value.expires < \$today)) | .key' \
    "\$ZIVPN_META_FILE" 2>/dev/null)
while IFS= read -r pwd; do
    [ -z "\$pwd" ] && continue
    jq --arg p "\$pwd" '.auth.config -= [\$p]' "\$ZIVPN_CONFIG_FILE" > /tmp/zivpn_cron.json 2>/dev/null && mv /tmp/zivpn_cron.json "\$ZIVPN_CONFIG_FILE"
    jq --arg p "\$pwd" 'del(.[\$p])' "\$ZIVPN_META_FILE" > /tmp/zivpn_meta_cron.json 2>/dev/null && mv /tmp/zivpn_meta_cron.json "\$ZIVPN_META_FILE"
    removed_any=true
done <<< "\$expired_pwds"
if [ "\$removed_any" = "true" ]; then
    systemctl restart zivpn 2>/dev/null
fi
CLEOF
    chmod +x "$ZIVPN_CLEANUP_SCRIPT"

    (crontab -l 2>/dev/null | grep -v "$ZIVPN_CLEANUP_CRON_MARKER") | crontab - 2>/dev/null
    (crontab -l 2>/dev/null; echo "*/15 * * * * $ZIVPN_CLEANUP_SCRIPT # $ZIVPN_CLEANUP_CRON_MARKER") | crontab -
}

zivpn_manage_passwords() {
    clear
    show_banner

    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 ZiVPN Password Management ---${C_RESET}"

    if ! command -v jq >/dev/null 2>&1; then
        echo -e "${C_RED}❌ jq not installed${C_RESET}"
        return
    fi

    if [ ! -f "$ZIVPN_CONFIG_FILE" ]; then
        echo -e "${C_RED}❌ Config not found${C_RESET}"
        return
    fi

    _zivpn_meta_init
    # Make sure the expiry sweeper cron job exists (idempotent, additive-only).
    if ! crontab -l 2>/dev/null | grep -q "$ZIVPN_CLEANUP_CRON_MARKER"; then
        _zivpn_install_cleanup_cron
    fi
    # Sweep now so the list below is accurate.
    zivpn_cleanup_expired_passwords

    # Charger passwords
    mapfile -t passwords < <(jq -r '.auth.config[]' "$ZIVPN_CONFIG_FILE")

    echo -e "\n${C_CYAN}Current passwords:${C_RESET}"

    if [ ${#passwords[@]} -gt 0 ]; then
        for i in "${!passwords[@]}"; do
            local p_expires p_quota
            p_expires=$(_zivpn_meta_get "${passwords[$i]}" "expires" "never")
            p_quota=$(_zivpn_meta_get "${passwords[$i]}" "quota_gb" "unlimited")
            [[ "$p_quota" != "unlimited" ]] && p_quota="${p_quota} GB"
            echo -e "  ${C_GREEN}[$((i+1))]${C_RESET} ${C_YELLOW}${passwords[$i]}${C_RESET} ${C_DIM}(expires: ${C_RESET}${p_expires}${C_DIM}, quota: ${C_RESET}${p_quota}${C_DIM})${C_RESET}"
        done
    else
        echo -e "  ${C_DIM}No passwords${C_RESET}"
    fi

    echo -e "\n${C_BOLD}Options:${C_RESET}"
    echo -e "  ${C_GREEN}[1] Add${C_RESET}"
    echo -e "  ${C_GREEN}[2] Remove${C_RESET}"
    echo -e "  ${C_GREEN}[3] Modify (change password value)${C_RESET}"
    echo -e "  ${C_GREEN}[4] Restart${C_RESET}"
    echo -e "  ${C_GREEN}[5] Edit expiration date / data quota${C_RESET}"
    echo -e "  ${C_RED}[0] Back${C_RESET}"

    read -r -p "👉 Choice: " choice

    case "$choice" in

        1)
            read -r -p "👉 New password: " new_pwd
            [ -z "$new_pwd" ] && echo "❌ Empty" && return

            # Ajouter
            jq --arg pwd "$new_pwd" \
            '.auth.config += [$pwd]' \
            "$ZIVPN_CONFIG_FILE" > /tmp/zivpn.json && mv /tmp/zivpn.json "$ZIVPN_CONFIG_FILE"

            _zivpn_prompt_expiry_quota "never" "unlimited"
            _zivpn_meta_set "$new_pwd" "$_Z_EXPIRES" "$_Z_QUOTA"

            systemctl restart zivpn
            echo "✅ Added (expires: $_Z_EXPIRES, quota: $_Z_QUOTA)"
            ;;

        2)
            read -r -p "👉 Number: " num

            if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt ${#passwords[@]} ]; then
                echo "❌ Invalid"
                return
            fi

            idx=$((num-1))
            old_pwd="${passwords[$idx]}"

            jq --argjson i "$idx" \
            'del(.auth.config[$i])' \
            "$ZIVPN_CONFIG_FILE" > /tmp/zivpn.json && mv /tmp/zivpn.json "$ZIVPN_CONFIG_FILE"
            _zivpn_meta_delete "$old_pwd"

            systemctl restart zivpn
            echo "✅ Removed"
            ;;

        3)
            read -r -p "👉 Number: " num
            read -r -p "👉 New password: " new_pwd

            if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt ${#passwords[@]} ]; then
                echo "❌ Invalid"
                return
            fi

            [ -z "$new_pwd" ] && echo "❌ Empty" && return

            idx=$((num-1))
            old_pwd="${passwords[$idx]}"

            jq --argjson i "$idx" --arg new "$new_pwd" \
            '.auth.config[$i] = $new' \
            "$ZIVPN_CONFIG_FILE" > /tmp/zivpn.json && mv /tmp/zivpn.json "$ZIVPN_CONFIG_FILE"
            _zivpn_meta_rename "$old_pwd" "$new_pwd"

            systemctl restart zivpn
            echo "✅ Modified"
            ;;

        4)
            systemctl restart zivpn
            echo "✅ Restarted"
            ;;

        5)
            read -r -p "👉 Number: " num

            if ! [[ "$num" =~ ^[0-9]+$ ]] || [ "$num" -lt 1 ] || [ "$num" -gt ${#passwords[@]} ]; then
                echo "❌ Invalid"
                return
            fi

            idx=$((num-1))
            target_pwd="${passwords[$idx]}"
            cur_expires=$(_zivpn_meta_get "$target_pwd" "expires" "never")
            cur_quota=$(_zivpn_meta_get "$target_pwd" "quota_gb" "unlimited")

            echo -e "${C_DIM}Editing '${target_pwd}' — current expires: ${cur_expires}, current quota: ${cur_quota}${C_RESET}"
            _zivpn_prompt_expiry_quota "$cur_expires" "$cur_quota"
            _zivpn_meta_set "$target_pwd" "$_Z_EXPIRES" "$_Z_QUOTA"
            echo "✅ Updated (expires: $_Z_EXPIRES, quota: $_Z_QUOTA)"
            ;;

        0) return ;;
        *) invalid_option ;;
    esac
}

purge_nginx() {
    local mode="$1"
    if [[ "$mode" != "silent" ]]; then
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 🔥 Purge Internal Nginx Proxy ---${C_RESET}"
        if ! command -v nginx &> /dev/null; then
            rm -f "$NGINX_PORTS_FILE"
            echo -e "\n${C_YELLOW}ℹ️ Nginx is not installed. Nothing to do.${C_RESET}"
            return
        fi
        echo -e "\n${C_YELLOW}⚠️ This removes the internal Nginx proxy on ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"
        if systemctl is-active --quiet haproxy; then
            echo -e "${C_YELLOW}⚠️ HAProxy will stay installed, but web payload routing from ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} will stop until you reinstall the stack.${C_RESET}"
        fi
        read -p "👉 Continue and purge Nginx? (y/n): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"
            return
        fi
    fi
    echo -e "\n${C_BLUE}🛑 Stopping Nginx service...${C_RESET}"
    systemctl stop nginx >/dev/null 2>&1
    systemctl disable nginx >/dev/null 2>&1
    echo -e "\n${C_BLUE}🗑️ Purging Nginx packages...${C_RESET}"
    ff_apt_purge nginx nginx-common >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "\n${C_BLUE}🗑️ Removing leftover files...${C_RESET}"
    rm -f /etc/ssl/certs/nginx-selfsigned.pem
    rm -f /etc/ssl/private/nginx-selfsigned.key
    rm -rf /etc/nginx
    rm -f "${NGINX_CONFIG_FILE}.bak"
    rm -f "${NGINX_CONFIG_FILE}.bak.certbot"
    rm -f "${NGINX_CONFIG_FILE}.bak.selfsigned"
    rm -f "${NGINX_CONFIG_FILE}.bak.novaxtunnel"
    rm -f "$NGINX_PORTS_FILE"
    if [[ "$mode" != "silent" ]]; then
        echo -e "\n${C_GREEN}✅ Internal Nginx proxy purged. Shared NOVA XTUNNEL certificates were kept.${C_RESET}"
    fi
}

install_nginx_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Reconfiguring Internal Nginx Proxy (8880/8443) ---${C_RESET}"
    echo -e "\n${C_CYAN}This keeps HAProxy on ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} and rewrites the internal Nginx proxy on ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"

    if [ ! -s "$SSL_CERT_FILE" ] || [ ! -s "$SSL_CERT_CHAIN_FILE" ] || [ ! -s "$SSL_CERT_KEY_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ No shared NOVA XTUNNEL certificate was found.${C_RESET}"
        echo -e "${C_DIM}Running the full HAProxy edge installer so the certificate and both services stay aligned.${C_RESET}"
        install_ssl_tunnel
        return
    fi

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"
    ensure_edge_stack_packages || return

    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 1

    check_and_free_ports \
        "$EDGE_PUBLIC_HTTP_PORT" \
        "$EDGE_PUBLIC_TLS_PORT" \
        "$NGINX_INTERNAL_HTTP_PORT" \
        "$NGINX_INTERNAL_TLS_PORT" \
        "$HAPROXY_INTERNAL_DECRYPT_PORT" || return

    check_and_open_firewall_port "$EDGE_PUBLIC_HTTP_PORT" tcp || return
    check_and_open_firewall_port "$EDGE_PUBLIC_TLS_PORT" tcp || return

    load_edge_cert_info
    local server_name="${EDGE_DOMAIN:-$(detect_preferred_host)}"
    [[ -z "$server_name" ]] && server_name="_"

    configure_edge_stack "$server_name" || return

    echo -e "\n${C_GREEN}✅ Internal Nginx proxy reconfigured successfully.${C_RESET}"
    echo -e "   • Public HAProxy edge: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Internal Nginx: ${C_YELLOW}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
}

request_certbot_ssl() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔒 Shared Certbot Certificate (HAProxy + Nginx) ---${C_RESET}"
    echo -e "\n${C_DIM}This will replace the shared certificate used by HAProxy on ${EDGE_PUBLIC_TLS_PORT} and internal Nginx on ${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"
    ensure_edge_stack_packages || return
    load_edge_cert_info

    local preferred_host
    local default_domain=""
    local domain_name
    local email

    preferred_host=$(detect_preferred_host)
    if [[ -n "$EDGE_DOMAIN" ]] && ! _is_valid_ipv4 "$EDGE_DOMAIN"; then
        default_domain="$EDGE_DOMAIN"
    elif [[ -n "$preferred_host" ]] && ! _is_valid_ipv4 "$preferred_host"; then
        default_domain="$preferred_host"
    fi

    if [[ -n "$default_domain" ]]; then
        read -p "👉 Enter your domain name [$default_domain]: " domain_name
        domain_name=${domain_name:-$default_domain}
    else
        read -p "👉 Enter your domain name (e.g. vpn.example.com): " domain_name
    fi
    if [[ -z "$domain_name" ]]; then
        echo -e "\n${C_RED}❌ Domain name cannot be empty.${C_RESET}"
        return
    fi
    if _is_valid_ipv4 "$domain_name"; then
        echo -e "\n${C_RED}❌ Certbot requires a real domain name, not a raw IP address.${C_RESET}"
        return
    fi

    read -p "👉 Enter your email for Let's Encrypt [${EDGE_EMAIL}]: " email
    email=${email:-$EDGE_EMAIL}
    if [[ -z "$email" ]]; then
        echo -e "\n${C_RED}❌ Email address cannot be empty.${C_RESET}"
        return
    fi

    check_and_open_firewall_port "$EDGE_PUBLIC_HTTP_PORT" tcp || return
    check_and_open_firewall_port "$EDGE_PUBLIC_TLS_PORT" tcp || return

    obtain_certbot_edge_cert "$domain_name" "$email" || return
    configure_edge_stack "$domain_name" || return

    echo -e "\n${C_GREEN}✅ Shared Certbot certificate applied successfully.${C_RESET}"
    echo -e "   • Domain: ${C_YELLOW}${domain_name}${C_RESET}"
    echo -e "   • Public edge: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
}

nginx_proxy_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Internal Nginx Proxy Management ---${C_RESET}"

    local nginx_status="${C_STATUS_I}Inactive${C_RESET}"
    local haproxy_status="${C_STATUS_I}Inactive${C_RESET}"
    if systemctl is-active --quiet nginx; then
        nginx_status="${C_STATUS_A}Active${C_RESET}"
    fi
    if systemctl is-active --quiet haproxy; then
        haproxy_status="${C_STATUS_A}Active${C_RESET}"
    fi

    load_edge_cert_info
    local cert_info="${EDGE_CERT_MODE:-Not configured}"
    if [[ -n "$EDGE_DOMAIN" ]]; then
        cert_info="${cert_info} - ${EDGE_DOMAIN}"
    fi

    echo -e "\n${C_WHITE}Nginx:${C_RESET} ${nginx_status}"
    echo -e "${C_WHITE}HAProxy:${C_RESET} ${haproxy_status}"
    echo -e "${C_DIM}Public Edge: ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} | Internal Nginx: ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "${C_DIM}Shared Certificate: ${cert_info}${C_RESET}"

    echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
    
    if systemctl is-active --quiet nginx; then
         printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🛑 Stop Nginx Service"
         printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "🔄 Restart HAProxy + Nginx Stack"
         printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "⚙️ Re-install/Re-configure Edge Stack"
         printf "  ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "🔒 Switch/Renew Shared SSL (Certbot)"
         printf "  ${C_CHOICE}[ 5]${C_RESET} %-40s\n" "🔥 Uninstall/Purge Nginx"
    else
         printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "▶️ Start Nginx Service"
         printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "⚙️ Install/Configure Edge Stack"
         printf "  ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "🔒 Switch/Renew Shared SSL (Certbot)"
         printf "  ${C_CHOICE}[ 5]${C_RESET} %-40s\n" "🔥 Uninstall/Purge Nginx"
    fi

    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return to previous menu"
    echo
    read -p "👉 Enter your choice: " choice
    
    case $choice in
        1) 
            if systemctl is-active --quiet nginx; then
                echo -e "\n${C_BLUE}🛑 Stopping Nginx...${C_RESET}"
                systemctl stop nginx
                echo -e "${C_GREEN}✅ Nginx stopped.${C_RESET}"
                if systemctl is-active --quiet haproxy; then
                    echo -e "${C_YELLOW}⚠️ HAProxy is still running, but web traffic that depends on internal Nginx will not work until Nginx starts again.${C_RESET}"
                fi
            else
                echo -e "\n${C_BLUE}▶️ Starting Nginx...${C_RESET}"
                systemctl start nginx
                if systemctl is-active --quiet nginx; then
                    echo -e "${C_GREEN}✅ Nginx started.${C_RESET}"
                else
                    echo -e "${C_RED}❌ Failed to start Nginx.${C_RESET}"
                fi
            fi
            press_enter
            ;;
        2)
            echo -e "\n${C_BLUE}🔄 Restarting Nginx and HAProxy...${C_RESET}"
            local restart_ok=true
            systemctl restart nginx || restart_ok=false
            if command -v haproxy &> /dev/null; then
                systemctl restart haproxy || restart_ok=false
            else
                restart_ok=false
            fi
            if $restart_ok && systemctl is-active --quiet nginx && systemctl is-active --quiet haproxy; then
                echo -e "${C_GREEN}✅ HAProxy + Nginx stack restarted.${C_RESET}"
            else
                echo -e "${C_RED}❌ One or more services failed to restart.${C_RESET}"
            fi
            press_enter
            ;;
        3) 
             install_nginx_proxy; press_enter
             ;;
        4)
             request_certbot_ssl; press_enter
             ;;
        5)
             purge_nginx; press_enter
             ;;
        0) return ;;
        *) invalid_option ;;
    esac
}

install_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Install X-UI Panel ---${C_RESET}"
    echo -e "\nThis will download and run the official installation script for X-UI."
    echo -e "Choose an installation option:\n"
    echo -e "Choose an installation option:\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} %-40s\n" "Install the latest version of X-UI"
    printf "  ${C_GREEN}[ 2]${C_RESET} %-40s\n" "Install a specific version of X-UI"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ❌ Cancel Installation"
    echo
    read -p "👉 Select an option: " choice
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚙️ Installing the latest version...${C_RESET}"
            bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
            ;;
        2)
            read -p "👉 Enter the version to install (e.g., 1.8.0): " version
            if [[ -z "$version" ]]; then
                echo -e "\n${C_RED}❌ Version number cannot be empty.${C_RESET}"
                return
            fi
            echo -e "\n${C_BLUE}⚙️ Installing version ${C_YELLOW}$version...${C_RESET}"
            VERSION=$version bash <(curl -Ls "https://raw.githubusercontent.com/alireza0/x-ui/$version/install.sh") "$version"
            ;;
        0)
            echo -e "\n${C_YELLOW}❌ Installation cancelled.${C_RESET}"
            ;;
        *)
            echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"
            ;;
    esac
}

uninstall_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Uninstall X-UI Panel ---${C_RESET}"
    if ! command -v x-ui &> /dev/null; then
        echo -e "\n${C_YELLOW}ℹ️ X-UI does not appear to be installed.${C_RESET}"
        return
    fi
    read -p "👉 Are you sure you want to thoroughly uninstall X-UI? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        echo -e "\n${C_BLUE}⚙️ Running the default X-UI uninstaller first...${C_RESET}"
        x-ui uninstall >/dev/null 2>&1
        echo -e "\n${C_BLUE}🧹 Performing a full cleanup to ensure complete removal...${C_RESET}"
        echo " - Stopping and disabling x-ui service..."
        systemctl stop x-ui >/dev/null 2>&1
        systemctl disable x-ui >/dev/null 2>&1
        echo " - Removing x-ui files and directories..."
        rm -f /etc/systemd/system/x-ui.service
        rm -f /usr/local/bin/x-ui
        rm -rf /usr/local/x-ui/
        rm -rf /etc/x-ui/
        echo " - Reloading systemd daemon..."
        systemctl daemon-reload
        echo -e "\n${C_GREEN}✅ X-UI has been thoroughly uninstalled.${C_RESET}"
    else
        echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"
    fi
}

refresh_ssh_session_cache() {
    local now db_mtime
    now=$(date +%s)
    db_mtime=$(stat -c %Y "$DB_FILE" 2>/dev/null || echo 0)

    if (( SSH_SESSION_CACHE_TS > 0 && now - SSH_SESSION_CACHE_TS < SSH_SESSION_CACHE_TTL && db_mtime == SSH_SESSION_CACHE_DB_MTIME )); then
        return
    fi

    SSH_SESSION_COUNTS=()
    SSH_SESSION_PIDS=()
    SSH_SESSION_TOTAL=0
    SSH_SESSION_CACHE_DB_MTIME=$db_mtime

    if [[ ! -s "$DB_FILE" ]]; then
        SSH_SESSION_CACHE_TS=$now
        return
    fi

    local -A managed_user_lookup=()
    local -A uid_user_lookup=()
    local -A seen_sessions=()
    local -A monitor_ppids=()
    local managed_user system_user system_uid ssh_pid ssh_ppid ssh_owner candidate_user login_uid

    while IFS=: read -r managed_user _rest; do
        [[ -n "$managed_user" && "$managed_user" != \#* ]] && managed_user_lookup["$managed_user"]=1
    done < "$DB_FILE"

    while IFS=: read -r system_user _ system_uid _rest; do
        [[ -n "$system_user" && "$system_uid" =~ ^[0-9]+$ ]] && uid_user_lookup["$system_uid"]="$system_user"
    done < /etc/passwd

    # Resolve each live sshd process to the remote peer IP it's actually talking to, so that
    # several processes/channels belonging to the SAME physical connection (common with some
    # tunneling clients - e.g. one process per forwarded port) collapse into a single online
    # session below, instead of being counted separately.
    #
    # REMOVED: this server relays the tunneled client's own internet traffic (SSH dynamic
    # port forwarding), so a single login's sshd process legitimately holds many established
    # TCP connections - one per website/app the tunneled device is using right now. Grouping
    # by peer IP was counting those destination servers as if they were separate clients. A
    # login = one sshd process; SSH_SESSION_PIDS below already gives the correct count.

    # Pass 1: processes directly owned by a managed user - the privilege-dropped session
    # child created by OpenSSH's privilege separation. Record each one's PPID so pass 2 can
    # skip its root-owned monitor (otherwise one real login gets counted as two sessions).
    while read -r ssh_pid ssh_ppid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" && -n "${managed_user_lookup[$ssh_owner]+x}" ]]; then
            [[ -z "${seen_sessions[$ssh_owner:$ssh_pid]+x}" ]] || continue
            seen_sessions["$ssh_owner:$ssh_pid"]=1
            SSH_SESSION_PIDS["$ssh_owner"]+="$ssh_pid "
            monitor_ppids["$ssh_ppid"]=1
        fi
    done < <(ps -C sshd -o pid=,ppid=,user= 2>/dev/null)

    # Pass 2: remaining root/sshd-owned processes - resolve via loginuid (covers the rare
    # case where privsep didn't produce a directly-owned child at all), but skip any pid
    # that is the privsep monitor of a session already counted in pass 1 - same login.
    while read -r ssh_pid ssh_ppid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue
        [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" && -n "${managed_user_lookup[$ssh_owner]+x}" ]] && continue
        [[ -n "${monitor_ppids[$ssh_pid]+x}" ]] && continue

        candidate_user=""
        if [[ -r "/proc/$ssh_pid/loginuid" ]]; then
            login_uid=""
            read -r login_uid < "/proc/$ssh_pid/loginuid" || login_uid=""
            if [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]]; then
                candidate_user="${uid_user_lookup[$login_uid]}"
            fi
        fi

        [[ -n "$candidate_user" && -n "${managed_user_lookup[$candidate_user]+x}" ]] || continue
        [[ -z "${seen_sessions[$candidate_user:$ssh_pid]+x}" ]] || continue

        seen_sessions["$candidate_user:$ssh_pid"]=1
        SSH_SESSION_PIDS["$candidate_user"]+="$ssh_pid "
    done < <(ps -C sshd -o pid=,ppid=,user= 2>/dev/null)

    # Count DISTINCT SSHD SESSION PROCESSES per user - each pid in SSH_SESSION_PIDS is one
    # real login. This is the actual number of open connections, independent of how many
    # outbound destinations that session's tunneled traffic happens to be touching right now.
    local user pid
    for user in "${!SSH_SESSION_PIDS[@]}"; do
        local count=0
        for pid in ${SSH_SESSION_PIDS[$user]}; do
            (( count++ ))
        done
        SSH_SESSION_COUNTS["$user"]=$count
        (( SSH_SESSION_TOTAL += count ))
    done

    SSH_SESSION_CACHE_TS=$now
}

count_managed_online_sessions() {
    refresh_ssh_session_cache
    echo "$SSH_SESSION_TOTAL"
}

invalidate_banner_cache() {
    BANNER_CACHE_TS=0
    SSH_SESSION_CACHE_TS=0
}


_visual_width() {
    local s="$1" width=0 i char cp
    for (( i=0; i<${#s}; i++ )); do
        char="${s:i:1}"
        cp=$(printf '%d' "'$char" 2>/dev/null) || cp=0
        [[ -z "$cp" ]] && cp=0
        if (( cp == 0xFE0F || cp == 0xFE0E || cp == 0x200D )); then
            continue # variation selector / ZWJ - zero width
        elif (( (cp >= 0x1100 && cp <= 0x115F) || (cp >= 0x2300 && cp <= 0x23FF) || \
                (cp >= 0x2600 && cp <= 0x27BF) || (cp >= 0x2B00 && cp <= 0x2BFF) || \
                (cp >= 0x1F000 && cp <= 0x1FFFF) || (cp >= 0x3000 && cp <= 0xA4CF) || \
                (cp >= 0xAC00 && cp <= 0xD7A3) || (cp >= 0xF900 && cp <= 0xFAFF) || \
                (cp >= 0xFF00 && cp <= 0xFF60) )); then
            width=$((width + 2)) # emoji / CJK / symbol ranges - double-width
        else
            width=$((width + 1))
        fi
    done
    echo "$width"
}


_pad_visual() {
    local s="$1" target="$2" vw
    vw=$(_visual_width "$s")
    if (( vw >= target )); then
        printf '%s' "$s"
    else
        printf '%s%*s' "$s" $((target - vw)) ""
    fi
}

refresh_banner_cache() {
    local now
    now=$(date +%s)
    if (( BANNER_CACHE_TS > 0 && now - BANNER_CACHE_TS < BANNER_CACHE_TTL )); then
        return
    fi

    if [[ -z "$BANNER_CACHE_OS_NAME" ]]; then
        BANNER_CACHE_OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux")
    fi
    if [[ -z "$BANNER_CACHE_SERVER_IP" ]]; then
        BANNER_CACHE_SERVER_IP=$(curl -s -4 --max-time 3 icanhazip.com 2>/dev/null | tr -d '[:space:]')
        if [[ -z "$BANNER_CACHE_SERVER_IP" ]]; then
            BANNER_CACHE_SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
        fi
        [[ -z "$BANNER_CACHE_SERVER_IP" ]] && BANNER_CACHE_SERVER_IP="indisponible"
    fi
    BANNER_CACHE_UP_TIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    BANNER_CACHE_RAM_USAGE=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0.00"}}')
    BANNER_CACHE_CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    if [[ -s "$DB_FILE" ]]; then
        BANNER_CACHE_TOTAL_USERS=$(grep -c . "$DB_FILE")
    else
        BANNER_CACHE_TOTAL_USERS=0
    fi
    BANNER_CACHE_ONLINE_USERS=$(count_managed_online_sessions)
    BANNER_CACHE_TS=$now
}

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear

    echo
    echo -e "${C_TITLE}${C_BOLD}"

    cat << 'EOF'
███╗   ██╗ ██████╗ ███████╗████████╗██████╗  █████╗
████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗
██╔██╗ ██║██║   ██║███████╗   ██║   ██████╔╝███████║
██║╚██╗██║██║   ██║╚════██║   ██║   ██╔══██╗██╔══██║
██║ ╚████║╚██████╔╝███████║   ██║   ██║  ██║██║  ██║
╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝
EOF

    echo -e "${C_RESET}"

    echo -e "${C_BOLD}${C_TITLE}          NOVA-XTUNNEL MANAGER ${C_DIM}v2.0.0${C_RESET}"
    echo -e "${C_DIM}                by ${C_RESET}${C_BOLD}NOSTRA${C_RESET}"
    echo -e "${C_CYAN}              📢 t.me/labokingfreesurf${C_RESET}"
    echo

    local BOX_W=56
    local TOP="╭$(printf '─%.0s' $(seq 1 $BOX_W))╮"
    local MID="├$(printf '─%.0s' $(seq 1 $BOX_W))┤"
    local BOTTOM="╰$(printf '─%.0s' $(seq 1 $BOX_W))╯"

    echo -e "${C_GRAY}${TOP}${C_RESET}"
    printf "${C_GRAY}│${C_RESET} 🖥️  ${C_GRAY}%-13s${C_RESET} ${C_WHITE}%s${C_RESET}\n" "System" "${BANNER_CACHE_OS_NAME}"
    printf "${C_GRAY}│${C_RESET} 🌐 ${C_GRAY}%-13s${C_RESET} ${C_WHITE}%s${C_RESET}\n" "VPS IP" "${BANNER_CACHE_SERVER_IP}"
    printf "${C_GRAY}│${C_RESET} ⏱️  ${C_GRAY}%-13s${C_RESET} ${C_WHITE}%s${C_RESET}\n" "Uptime" "${BANNER_CACHE_UP_TIME}"
    echo -e "${C_GRAY}${MID}${C_RESET}"
    printf "${C_GRAY}│${C_RESET} 💾 ${C_GRAY}%-13s${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% used"
    printf "${C_GRAY}│${C_RESET} ⚙️  ${C_GRAY}%-13s${C_RESET} ${C_GREEN}%s${C_RESET}\n" "CPU Load" "${BANNER_CACHE_CPU_LOAD}"
    printf "${C_GRAY}│${C_RESET} 👥 ${C_GRAY}%-13s${C_RESET} ${C_WHITE}%s${C_RESET} accounts ${C_GRAY}•${C_RESET} Online: ${C_WHITE}%s${C_RESET}\n" \
        "Accounts" "${BANNER_CACHE_TOTAL_USERS}" "${BANNER_CACHE_ONLINE_USERS}"
    echo -e "${C_GRAY}${BOTTOM}${C_RESET}"
}


protocol_menu() {
    while true; do
        show_banner
        local badvpn_status; if systemctl is-active --quiet badvpn; then badvpn_status="${C_STATUS_A}(Active)${C_RESET}"; else badvpn_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        local udp_custom_status; if systemctl is-active --quiet udp-custom; then udp_custom_status="${C_STATUS_A}(Active)${C_RESET}"; else udp_custom_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        local zivpn_status; if systemctl is-active --quiet zivpn.service; then zivpn_status="${C_STATUS_A}(Active)${C_RESET}"; else zivpn_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        
        local ssl_tunnel_text="HAProxy Edge Stack (80/443)"
        local ssl_tunnel_status="${C_STATUS_I}(Inactive)${C_RESET}"
        if systemctl is-active --quiet haproxy; then
            ssl_tunnel_status="${C_STATUS_A}(Active)${C_RESET}"
        fi
        
        local dnstt_status; if systemctl is-active --quiet dnstt.service; then dnstt_status="${C_STATUS_A}(Active)${C_RESET}"; else dnstt_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        
        local falconproxy_status="${C_STATUS_I}(Inactive)${C_RESET}"
        local falconproxy_ports=""
        if systemctl is-active --quiet falconproxy; then
            if [ -f "$FALCONPROXY_CONFIG_FILE" ]; then source "$FALCONPROXY_CONFIG_FILE"; fi
            falconproxy_ports=" ($PORTS)"
            falconproxy_status="${C_STATUS_A}(Active - ${INSTALLED_VERSION:-latest})${C_RESET}"
        fi

        local nginx_status; if systemctl is-active --quiet nginx; then nginx_status="${C_STATUS_A}(Active)${C_RESET}"; else nginx_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        local xui_status; if command -v x-ui &> /dev/null; then xui_status="${C_STATUS_A}(Installed)${C_RESET}"; else xui_status="${C_STATUS_I}(Not Installed)${C_RESET}"; fi
        local pyproxy_status; if systemctl is-active --quiet pyproxy-socks.service || systemctl is-active --quiet pyproxy-ws.service; then pyproxy_status="${C_STATUS_A}(Active)${C_RESET}"; else pyproxy_status="${C_STATUS_I}(Inactive)${C_RESET}"; fi
        
        echo -e "\n ${C_TITLE}══════════════[ ${C_BOLD}🔌 PROTOCOL & PANEL MANAGEMENT ${C_RESET}${C_TITLE}]══════════════${C_RESET}"
        echo -e "   ${C_ACCENT}--- TUNNELLING PROTOCOLS---${C_RESET}"
        printf "   ${C_CHOICE}[ 1]${C_RESET} %-45s %s\n" "🚀 Install badvpn (UDP 7300)" "$badvpn_status"
        printf "   ${C_CHOICE}[ 2]${C_RESET} %-45s\n" "🗑️ Uninstall badvpn"
        printf "   ${C_CHOICE}[ 3]${C_RESET} %-45s %s\n" "🚀 Install udp-custom" "$udp_custom_status"
        printf "   ${C_CHOICE}[ 4]${C_RESET} %-45s\n" "🗑️ Uninstall udp-custom"
        printf "   ${C_CHOICE}[ 5]${C_RESET} %-45s %s\n" "🔒 Install ${ssl_tunnel_text}" "$ssl_tunnel_status"
        printf "   ${C_CHOICE}[ 6]${C_RESET} %-45s\n" "🗑️ Uninstall HAProxy Edge Stack"
        printf "   ${C_CHOICE}[ 7]${C_RESET} %-45s %s\n" "📡 Install/View DNSTT (Port 53)" "$dnstt_status"
        printf "   ${C_CHOICE}[ 8]${C_RESET} %-45s\n" "🗑️ Uninstall DNSTT"
        printf "   ${C_CHOICE}[ 9]${C_RESET} %-45s %s\n" "🦅 Install Falcon Proxy (Select Version)" "$falconproxy_status"
        printf "   ${C_CHOICE}[10]${C_RESET} %-45s\n" "🗑️ Uninstall Falcon Proxy"
        printf "   ${C_CHOICE}[11]${C_RESET} %-45s %s\n" "🛡️ Install ZiVPN (UDP 5667)" "$zivpn_status"
        printf "   ${C_CHOICE}[12]${C_RESET} %-45s\n" "🗑️ Uninstall ZiVPN"
        printf "   ${C_CHOICE}[13]${C_RESET} %-45s %s\n" "🌐 Install/Manage Internal Nginx (8880/8443)" "$nginx_status"
        printf "   ${C_CHOICE}[14]${C_RESET} %-45s %s\n" "🐍 Install PY SOCKS/WS Proxy (legacy)" "$pyproxy_status"
        printf "   ${C_CHOICE}[15]${C_RESET} %-45s\n" "🗑️ Uninstall PY SOCKS/WS Proxy"

        echo -e "   ${C_ACCENT}--- 💻 MANAGEMENT PANELS ---${C_RESET}"
        printf "   ${C_CHOICE}[16]${C_RESET} %-45s %s\n" "💻 Install X-UI Panel" "$xui_status"
        printf "   ${C_CHOICE}[17]${C_RESET} %-45s\n" "🗑️ Uninstall X-UI Panel"

        echo -e "  ${C_DIM}══════════════════════════════════════════════════════${C_RESET}"
        echo -e "    ${C_WARN}[ 0]${C_RESET} ↩️ Return to Main Menu"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1) install_badvpn; press_enter ;; 2) uninstall_badvpn; press_enter ;;
            3) install_udp_custom; press_enter ;; 4) uninstall_udp_custom; press_enter ;;
            5) install_ssl_tunnel; press_enter ;; 6) uninstall_ssl_tunnel; press_enter ;;
            7) install_dnstt; press_enter ;; 8) uninstall_dnstt; press_enter ;;
            9) install_falcon_proxy; press_enter ;; 10) uninstall_falcon_proxy; press_enter ;;
            11) install_zivpn; press_enter ;; 12) uninstall_zivpn; press_enter ;;
            13) nginx_proxy_menu ;;
            14) install_pyproxy; press_enter ;; 15) uninstall_pyproxy; press_enter ;;
            16) install_xui_panel; press_enter ;; 17) uninstall_xui_panel; press_enter ;;
            0) return ;;
            *) invalid_option ;;
        esac
    done
}

uninstall_script() {
    clear; show_banner
    echo -e "${C_RED}=====================================================${C_RESET}"
    echo -e "${C_RED}       🔥 DANGER: UNINSTALL SCRIPT & ALL DATA 🔥      ${C_RESET}"
    echo -e "${C_RED}=====================================================${C_RESET}"
    echo -e "${C_YELLOW}This will PERMANENTLY remove this script and all its components, including:"
    echo -e " - The main command ($(command -v menu))"
    echo -e " - All configuration and user data ($DB_DIR)"
    echo -e " - The active limiter service ($LIMITER_SERVICE)"
    echo -e " - All installed services (badvpn, udp-custom, HAProxy Edge Stack, Nginx, DNSTT)"
    echo -e "\n${C_RED}This action is irreversible.${C_RESET}"
    echo ""
    read -p "👉 Type 'yes' to confirm and proceed with uninstallation: " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "\n${C_GREEN}✅ Uninstallation cancelled.${C_RESET}"
        return
    fi
    local -a removable_users=()
    local remove_users_confirm
    local remove_users_on_uninstall=false
    mapfile -t removable_users < <(get_novaxtunnel_known_users)
    if [[ ${#removable_users[@]} -gt 0 ]]; then
        echo -e "\n${C_YELLOW}NOVA XTUNNEL SSH users detected on this VPS:${C_RESET} ${removable_users[*]}"
        read -p "👉 Do you also want to permanently delete these SSH users before uninstalling? (y/n): " remove_users_confirm
        if [[ "$remove_users_confirm" == "y" || "$remove_users_confirm" == "Y" ]]; then
            remove_users_on_uninstall=true
        fi
    fi
    export UNINSTALL_MODE="silent"
    echo -e "\n${C_BLUE}--- 💥 Starting Uninstallation 💥 ---${C_RESET}"
    
    if [[ "$remove_users_on_uninstall" == "true" ]]; then
        echo -e "\n${C_BLUE}🗑️ Removing NOVA XTUNNEL SSH users before uninstall...${C_RESET}"
        delete_novaxtunnel_user_accounts "${removable_users[@]}"
    fi
    
    echo -e "\n${C_BLUE}🗑️ Removing active limiter service...${C_RESET}"
    systemctl stop novaxtunnel-limiter &>/dev/null
    systemctl disable novaxtunnel-limiter &>/dev/null
    rm -f "$LIMITER_SERVICE"
    rm -f "$LIMITER_SCRIPT"
    
    echo -e "\n${C_BLUE}🗑️ Removing bandwidth monitoring service...${C_RESET}"
    systemctl stop novaxtunnel-bandwidth &>/dev/null
    systemctl disable novaxtunnel-bandwidth &>/dev/null
    rm -f "$BANDWIDTH_SERVICE"
    rm -f "$BANDWIDTH_SCRIPT"
    rm -rf "$LEGACY_BANDWIDTH_DIR"
    rm -f "$TRIAL_CLEANUP_SCRIPT"
    
    echo -e "\n${C_BLUE}\ud83d\uddd1\ufe0f Removing SSH login banner...${C_RESET}"
    rm -f "$LOGIN_INFO_SCRIPT"
    rm -f "$SSHD_FF_CONFIG"
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    
    chattr -i /etc/resolv.conf &>/dev/null

    purge_nginx "silent"
    uninstall_dnstt
    uninstall_badvpn
    uninstall_udp_custom
    uninstall_ssl_tunnel
    uninstall_falcon_proxy
    uninstall_pyproxy
    uninstall_zivpn
    delete_dns_record
    
    echo -e "\n${C_BLUE}🔄 Reloading systemd daemon...${C_RESET}"
    systemctl daemon-reload
    
    echo -e "\n${C_BLUE}🗑️ Removing script and configuration files...${C_RESET}"
    rm -rf "$BADVPN_BUILD_DIR"
    rm -rf "$UDP_CUSTOM_DIR"
    rm -rf "$DB_DIR"
    rm -f "$(command -v menu)"
    
    echo -e "\n${C_GREEN}=============================================${C_RESET}"
    echo -e "${C_GREEN}      Script has been successfully uninstalled.     ${C_RESET}"
    echo -e "${C_GREEN}=============================================${C_RESET}"
    echo -e "\nAll associated files and services have been removed."
    echo "The 'menu' command will no longer work."
    exit 0
}

# --- NEW FEATURES ---

create_trial_account() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⏱️ Create Trial/Test Account ---${C_RESET}"
    
    # Ensure 'at' daemon is available
    if ! command -v at &>/dev/null; then
        echo -e "${C_YELLOW}⚠️ 'at' command not found. Installing...${C_RESET}"
        ff_apt_install at >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to install 'at'. Cannot schedule auto-expiry.${C_RESET}"
            return
        }
        systemctl enable atd &>/dev/null
        systemctl start atd &>/dev/null
    fi
    
    # Ensure atd is running
    if ! systemctl is-active --quiet atd; then
        systemctl start atd &>/dev/null
    fi
    
    echo -e "\n${C_CYAN}Select trial duration:${C_RESET}\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} ⏱️  1 Hour\n"
    printf "  ${C_GREEN}[ 2]${C_RESET} ⏱️  2 Hours\n"
    printf "  ${C_GREEN}[ 3]${C_RESET} ⏱️  3 Hours\n"
    printf "  ${C_GREEN}[ 4]${C_RESET} ⏱️  6 Hours\n"
    printf "  ${C_GREEN}[ 5]${C_RESET} ⏱️  12 Hours\n"
    printf "  ${C_GREEN}[ 6]${C_RESET} 📅  1 Day\n"
    printf "  ${C_GREEN}[ 7]${C_RESET} 📅  3 Days\n"
    printf "  ${C_GREEN}[ 8]${C_RESET} ⚙️  Custom (enter hours)\n"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ↩️ Cancel"
    echo
    read -p "👉 Select duration: " dur_choice
    
    local duration_hours=0
    local duration_label=""
    case $dur_choice in
        1) duration_hours=1;   duration_label="1 Hour" ;;
        2) duration_hours=2;   duration_label="2 Hours" ;;
        3) duration_hours=3;   duration_label="3 Hours" ;;
        4) duration_hours=6;   duration_label="6 Hours" ;;
        5) duration_hours=12;  duration_label="12 Hours" ;;
        6) duration_hours=24;  duration_label="1 Day" ;;
        7) duration_hours=72;  duration_label="3 Days" ;;
        8) read -p "👉 Enter custom duration in hours: " custom_hours
           if ! [[ "$custom_hours" =~ ^[0-9]+$ ]] || [[ "$custom_hours" -lt 1 ]]; then
               echo -e "\n${C_RED}❌ Invalid number of hours.${C_RESET}"; return
           fi
           duration_hours=$custom_hours
           duration_label="$custom_hours Hours"
           ;;
        0) echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; return ;;
        *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"; return ;;
    esac
    
    # Username
    local rand_suffix=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 5)
    local default_username="trial_${rand_suffix}"
    read -p "👤 Username [${default_username}]: " username
    username=${username:-$default_username}
    
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Error: User '$username' already exists.${C_RESET}"; return
    fi
    
    # Password
    local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
    read -p "🔑 Password [${password}]: " custom_pass
    password=${custom_pass:-$password}
    
    # Connection limit
    read -p "📶 Connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    # Bandwidth limit
    read -p "📦 Bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    # Calculate expiry
    local expire_date
    if [[ "$duration_hours" -ge 24 ]]; then
        local days=$((duration_hours / 24))
        expire_date=$(date -d "+$days days" +%Y-%m-%d)
    else
        # For sub-day durations, set expiry to tomorrow to be safe (at job does the real cleanup)
        expire_date=$(date -d "+1 day" +%Y-%m-%d)
    fi
    local expiry_timestamp
    expiry_timestamp=$(date -d "+${duration_hours} hours" '+%Y-%m-%d %H:%M:%S')
    
    # Create the system user
    ensure_novaxtunnel_system_group
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
    
    # Schedule auto-cleanup via 'at'
    echo "$TRIAL_CLEANUP_SCRIPT $username" | at now + ${duration_hours} hours 2>/dev/null
    
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    
    clear; show_banner
    echo -e "${C_GREEN}✅ Trial account created successfully!${C_RESET}\n"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  ⏱️  ${C_BOLD}TRIAL ACCOUNT${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - ⏱️ Duration:          ${C_CYAN}$duration_label${C_RESET}"
    echo -e "  - 🕐 Auto-expires at:   ${C_RED}$expiry_timestamp${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Bandwidth Limit:   ${C_YELLOW}$bw_display${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "\n${C_DIM}The account will be automatically deleted when the trial expires.${C_RESET}"
    
    # Auto-ask for config generation
    echo
    read -p "👉 Generate client config for this trial user? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

view_user_bandwidth() {
    _select_user_interface "--- 📊 View User Bandwidth ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📊 Bandwidth Details: ${C_YELLOW}$u${C_PURPLE} ---${C_RESET}\n"
    
    local line; line=$(grep "^$u:" "$DB_FILE")
    local bandwidth_gb; bandwidth_gb=$(echo "$line" | cut -d: -f5)
    [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
    
    local used_bytes=0
    if [[ -f "$BANDWIDTH_DIR/${u}.usage" ]]; then
        used_bytes=$(cat "$BANDWIDTH_DIR/${u}.usage" 2>/dev/null)
        [[ -z "$used_bytes" ]] && used_bytes=0
    fi
    
    local used_mb; used_mb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1048576}")
    local used_gb; used_gb=$(awk "BEGIN {printf \"%.3f\", $used_bytes / 1073741824}")
    
    echo -e "  ${C_CYAN}Data Used:${C_RESET}        ${C_WHITE}${used_gb} GB${C_RESET} (${used_mb} MB)"
    
    if [[ "$bandwidth_gb" == "0" ]]; then
        echo -e "  ${C_CYAN}Bandwidth Limit:${C_RESET}  ${C_GREEN}Unlimited${C_RESET}"
        echo -e "  ${C_CYAN}Status:${C_RESET}           ${C_GREEN}No quota restrictions${C_RESET}"
    else
        local quota_bytes; quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        local percentage; percentage=$(awk "BEGIN {printf \"%.1f\", ($used_bytes / $quota_bytes) * 100}")
        local remaining_bytes; remaining_bytes=$((quota_bytes - used_bytes))
        if [[ "$remaining_bytes" -lt 0 ]]; then remaining_bytes=0; fi
        local remaining_gb; remaining_gb=$(awk "BEGIN {printf \"%.3f\", $remaining_bytes / 1073741824}")
        
        echo -e "  ${C_CYAN}Bandwidth Limit:${C_RESET}  ${C_YELLOW}${bandwidth_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Remaining:${C_RESET}        ${C_WHITE}${remaining_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Usage:${C_RESET}            ${C_WHITE}${percentage}%${C_RESET}"
        
        # Progress bar
        local bar_width=30
        local filled; filled=$(awk "BEGIN {printf \"%.0f\", ($percentage / 100) * $bar_width}")
        if [[ "$filled" -gt "$bar_width" ]]; then filled=$bar_width; fi
        local empty=$((bar_width - filled))
        local bar_color="$C_GREEN"
        if (( $(awk "BEGIN {print ($percentage > 80)}" ) )); then bar_color="$C_RED"
        elif (( $(awk "BEGIN {print ($percentage > 50)}" ) )); then bar_color="$C_YELLOW"
        fi
        printf "  ${C_CYAN}Progress:${C_RESET}         ${bar_color}["
        for ((i=0; i<filled; i++)); do printf "█"; done
        for ((i=0; i<empty; i++)); do printf "░"; done
        printf "]${C_RESET} ${percentage}%%\n"
        
        if [[ "$used_bytes" -ge "$quota_bytes" ]]; then
            echo -e "\n  ${C_RED}⚠️ USER HAS EXCEEDED BANDWIDTH QUOTA — ACCOUNT LOCKED${C_RESET}"
        fi
    fi
}

bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Bulk Create Users ---${C_RESET}"
    
    read -p "👉 Enter username prefix (e.g., 'user'): " prefix
    if [[ -z "$prefix" ]]; then echo -e "\n${C_RED}❌ Prefix cannot be empty.${C_RESET}"; return; fi
    
    read -p "🔢 How many users to create? " count
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]]; then
        echo -e "\n${C_RED}❌ Invalid count (1-100).${C_RESET}"; return
    fi
    
    read -p "🗓️ Account duration (in days) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📶 Connection limit per user [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📦 Bandwidth limit in GB per user (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    local expire_date
    expire_date=$(date -d "+$days days" +%Y-%m-%d)
    local bw_display="Unlimited"; [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    ensure_novaxtunnel_system_group
    
    echo -e "\n${C_BLUE}⚙️ Creating $count users with prefix '${prefix}'...${C_RESET}\n"
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-20s | %-15s | %-12s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRES"
    echo -e "${C_YELLOW}----------------------------------------------------------------${C_RESET}"
    
    local created=0
    for ((i=1; i<=count; i++)); do
        local username="${prefix}${i}"
        if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
            echo -e "${C_RED}  ⚠️ Skipping '$username' — already exists${C_RESET}"
            continue
        fi
        local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
        useradd -m -s /usr/sbin/nologin "$username"
        usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
        echo "$username:$password" | chpasswd
        chage -E "$expire_date" "$username"
        echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        created=$((created + 1))
    done
    
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    echo -e "\n${C_GREEN}✅ Created $created users. Conn Limit: ${limit} | BW: ${bw_display}${C_RESET}"
    
    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

generate_client_config() {
    local user=$1
    local pass=$2
    
    local host_ip=$(curl -s -4 icanhazip.com)
    local host_domain
    host_domain=$(detect_preferred_host)
    [[ -z "$host_domain" ]] && host_domain="$host_ip"

    echo -e "\n${C_BOLD}${C_PURPLE}--- 📱 Client Connection Configuration ---${C_RESET}"
    echo -e "${C_CYAN}Copy the details below to your clipboard:${C_RESET}\n"

    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "👤 ${C_BOLD}User Details${C_RESET}"
    echo -e "   • Username: ${C_WHITE}$user${C_RESET}"
    echo -e "   • Password: ${C_WHITE}$pass${C_RESET}"
    echo -e "   • Host/IP : ${C_WHITE}$host_domain${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    
    # 1. SSH Direct
    echo -e "\n🔹 ${C_BOLD}SSH Direct${C_RESET}:"
    echo -e "   • Host: $host_domain"
    echo -e "   • Port: 22"
    echo -e "   • payload: 8080,8888,444(Standard SSH)"

    # 2. HAProxy edge stack
    if systemctl is-active --quiet haproxy; then
        echo -e "\n🔹 ${C_BOLD}HAProxy Edge Stack${C_RESET}:"
        echo -e "   • Host: $host_domain"
        echo -e "   • Port 80: HTTP payloads / raw SSH"
        echo -e "   • Port 443: TLS / SNI / SSL payloads"
        echo -e "   • Internal handoff: Nginx ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}"
        echo -e "   • SNI (BugHost): $host_domain (or your preferred SNI)"
    elif systemctl is-active --quiet nginx; then
        echo -e "\n🔹 ${C_BOLD}Internal Nginx Proxy${C_RESET}:"
        echo -e "   • Internal only: ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}"
        echo -e "   • Public clients should connect through HAProxy on ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}"
    fi

    # 3. UDP Custom
    if systemctl is-active --quiet udp-custom; then
        echo -e "\n🔹 ${C_BOLD}UDP Custom${C_RESET}:"
        echo -e "   • IP: $host_ip (Must use numeric IP)"
        echo -e "   • Port: ${UDP_CUSTOM_RANGE_START}-${UDP_CUSTOM_RANGE_END} (Forwarded to internal ${UDP_CUSTOM_LISTEN_PORT})"
        echo -e "   • Obfs: (None/Plain)"
    fi

    # 4. DNSTT
    if systemctl is-active --quiet dnstt; then
        if [ -f "$DNSTT_CONFIG_FILE" ]; then
            source "$DNSTT_CONFIG_FILE"
            echo -e "\n🔹 ${C_BOLD}DNSTT (SlowDNS)${C_RESET}:"
            echo -e "   • Nameserver: $TUNNEL_DOMAIN"
            echo -e "   • PubKey: $PUBLIC_KEY"
            echo -e "   • DNS IP: 1.1.1.1 / 8.8.8.8"
        fi
    fi
    
    # 5. ZiVPN
    if systemctl is-active --quiet zivpn; then
        echo -e "\n🔹 ${C_BOLD}ZiVPN${C_RESET}:"
        echo -e "   • UDP Port: ${ZIVPN_LISTEN_PORT}"
        echo -e "   • Forwarded Ports: ${ZIVPN_RANGE_START}-${ZIVPN_RANGE_END}"
    fi

    # 6. PY SOCKS/WS Proxy
    if [ -f "$PYPROXY_CONFIG_FILE" ] && (systemctl is-active --quiet pyproxy-socks || systemctl is-active --quiet pyproxy-ws); then
        source "$PYPROXY_CONFIG_FILE"
        echo -e "\n🔹 ${C_BOLD}PY SOCKS/WS Proxy${C_RESET}:"
        systemctl is-active --quiet pyproxy-socks && echo -e "   • SOCKS Port: ${SOCKS_PORT} (HTTP 200)"
        systemctl is-active --quiet pyproxy-ws && echo -e "   • WebSocket Port: ${WS_PORT} (HTTP 101)"
    fi
    
    echo -e "${C_YELLOW}========================================${C_RESET}"
    press_enter
}

client_config_menu() {
    _select_user_interface "--- 📱 Generate Client Config ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    # We need to find the password. It's in the DB.
    local pass=$(grep "^$u:" "$DB_FILE" | cut -d: -f2)
    generate_client_config "$u" "$pass"
}

format_rate_from_kbps() {
    local kbps=${1:-0}
    if (( kbps >= 1024 )); then
        printf "%d.%02d MB/s" $((kbps / 1024)) $((((kbps % 1024) * 100) / 1024))
    else
        printf "%d KB/s" "$kbps"
    fi
}

# Lightweight Bash Monitor (No vnStat required)
simple_live_monitor() {
    local iface=$1
    local rx_file="/sys/class/net/$iface/statistics/rx_bytes"
    local tx_file="/sys/class/net/$iface/statistics/tx_bytes"
    local interval=2
    local stop_monitor=0
    local rx1 tx1 rx2 tx2 rx_diff tx_diff rx_kbs tx_kbs rx_fmt tx_fmt

    if [[ -z "$iface" || ! -r "$rx_file" || ! -r "$tx_file" ]]; then
        echo -e "\n${C_RED}❌ Could not read interface statistics for '${iface:-unknown}'.${C_RESET}"
        return
    fi

    echo -e "\n${C_BLUE}⚡ Starting Lightweight Traffic Monitor for $iface...${C_RESET}"
    echo -e "${C_DIM}Press [Ctrl+C] to stop.${C_RESET}\n"

    read -r rx1 < "$rx_file"
    read -r tx1 < "$tx_file"

    printf "%-15s | %-15s\n" "⬇️ Download" "⬆️ Upload"
    echo "-----------------------------------"

    trap 'stop_monitor=1' INT TERM
    while (( ! stop_monitor )); do
        sleep "$interval"
        read -r rx2 < "$rx_file" || break
        read -r tx2 < "$tx_file" || break

        rx_diff=$((rx2 - rx1))
        tx_diff=$((tx2 - tx1))
        (( rx_diff < 0 )) && rx_diff=0
        (( tx_diff < 0 )) && tx_diff=0

        rx_kbs=$((rx_diff / 1024 / interval))
        tx_kbs=$((tx_diff / 1024 / interval))
        rx_fmt=$(format_rate_from_kbps "$rx_kbs")
        tx_fmt=$(format_rate_from_kbps "$tx_kbs")

        printf "\r%-15s | %-15s" "$rx_fmt" "$tx_fmt"

        rx1=$rx2
        tx1=$tx2
    done
    trap - INT TERM
    echo
}

traffic_monitor_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📈 Network Traffic Monitor ---${C_RESET}"
    
    # Find active interface
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    echo -e "\nInterface: ${C_CYAN}${iface}${C_RESET}"
    
    echo -e "\n${C_BOLD}Select a monitoring option:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "⚡ Live Monitor ${C_DIM}(Lightweight, No Install)${C_RESET}"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "📊 View Total Traffic Since Boot"
    printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "📅 Daily/Monthly Logs ${C_DIM}(Requires vnStat)${C_RESET}"
    
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
    echo
    read -p "👉 Enter choice: " t_choice
    case $t_choice in
        1) 
           simple_live_monitor "$iface"
           ;;
        2)
            local rx_total=$(cat /sys/class/net/$iface/statistics/rx_bytes)
            local tx_total=$(cat /sys/class/net/$iface/statistics/tx_bytes)
            local rx_mb=$((rx_total / 1024 / 1024))
            local tx_mb=$((tx_total / 1024 / 1024))
            echo -e "\n${C_BLUE}📊 Total Traffic (Since Boot):${C_RESET}"
            echo -e "   ⬇️ Download: ${C_WHITE}${rx_mb} MB${C_RESET}"
            echo -e "   ⬆️ Upload:   ${C_WHITE}${tx_mb} MB${C_RESET}"
            press_enter
            ;;
        3) 
           # vnStat Logic
           if ! command -v vnstat &> /dev/null; then
               echo -e "\n${C_YELLOW}⚠️ vnStat is not installed.${C_RESET}"
               echo -e "   This tool provides persistent history (Daily/Monthly reports)."
               echo -e "   It is lightweight but requires installation."
               read -p "👉 Install vnStat now? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                     echo -e "\n${C_BLUE}📦 Installing vnStat...${C_RESET}"
                     ff_apt_install vnstat >/dev/null 2>&1 || {
                         echo -e "${C_RED}❌ Failed to install vnStat.${C_RESET}"
                         sleep 1
                         return
                     }
                     systemctl enable vnstat >/dev/null 2>&1
                     systemctl restart vnstat >/dev/null 2>&1
                    local default_iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
                    vnstat --add -i "$default_iface" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ Installed.${C_RESET}"
                    sleep 1
               else
                    return
               fi
           fi
           echo
           vnstat -i "$iface"
           echo -e "\n${C_DIM}Run 'vnstat -d' or 'vnstat -m' manually for specific views.${C_RESET}"
           press_enter
           ;;
        *) return ;;
    esac
}

torrent_block_is_enabled() {
    if iptables -L FORWARD | grep -q "ipp2p"; then return 0; fi
    if iptables -L OUTPUT | grep -q "BitTorrent"; then return 0; fi
    return 1
}

# Non-interactive versions of the enable/disable actions inside torrent_block_menu below -
# used by both the interactive menu (no behavior change there) and the web panel bridge
# (via `menu --exec torrent_block_enable` / `torrent_block_disable`), which cannot answer
# an interactive read -p prompt.
torrent_block_enable() {
    echo -e "\n${C_BLUE}🛡️ Applying Anti-Torrent rules...${C_RESET}"
    _flush_torrent_rules
    iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP
    iptables -A FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP
    iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP
    iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP
    iptables -A FORWARD -m string --string "announce.php?passkey=" --algo bm -j DROP
    iptables -A FORWARD -m string --string "torrent" --algo bm -j DROP
    iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP
    iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
    iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "BitTorrent" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "peer_id=" --algo bm -j DROP
    iptables -A OUTPUT -m string --string ".torrent" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "announce.php?passkey=" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "torrent" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "info_hash" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "get_peers" --algo bm -j DROP
    iptables -A OUTPUT -m string --string "find_node" --algo bm -j DROP
    if dpkg -s iptables-persistent &>/dev/null; then
        netfilter-persistent save &>/dev/null
    fi
    echo -e "${C_GREEN}✅ Torrent Blocking Enabled.${C_RESET}"
}

torrent_block_disable() {
    echo -e "\n${C_BLUE}🔓 Removing Anti-Torrent rules...${C_RESET}"
    _flush_torrent_rules
    if dpkg -s iptables-persistent &>/dev/null; then
        netfilter-persistent save &>/dev/null
    fi
    echo -e "${C_GREEN}✅ Torrent Blocking Disabled.${C_RESET}"
}

torrent_block_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚫 Torrent Blocking (Anti-Torrent) ---${C_RESET}"
    
    # Check status
    local torrent_status="${C_STATUS_I}Disabled${C_RESET}"
    if torrent_block_is_enabled; then
         torrent_status="${C_STATUS_A}Enabled${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Current Status: ${torrent_status}${C_RESET}"
    echo -e "${C_DIM}This feature uses iptables string matching to block common torrent keywords.${C_RESET}"
    
    echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🔒 Enable Torrent Blocking"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "🔓 Disable Torrent Blocking"
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
    echo
    read -p "👉 Enter choice: " b_choice
    
    case $b_choice in
        1)
            torrent_block_enable
            press_enter
            ;;
        2)
            torrent_block_disable
            press_enter
            ;;
        *) return ;;
    esac
}


_flush_torrent_rules() {
    # Helper to remove rules containing specific strings
    # This is a bit brute-force but effective for this script's scope
    iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "announce.php?passkey=" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "torrent" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
    iptables -D FORWARD -m string --string "find_node" --algo bm -j DROP 2>/dev/null

    iptables -D OUTPUT -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "announce.php?passkey=" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "torrent" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
    iptables -D OUTPUT -m string --string "find_node" --algo bm -j DROP 2>/dev/null
}

ssh_banner_menu() {
    while true; do
        show_banner
        local banner_mode
        local banner_status
        banner_mode=$(get_ssh_banner_mode)
        case "$banner_mode" in
            dynamic) banner_status="${C_STATUS_A}Dynamic${C_RESET}" ;;
            static) banner_status="${C_STATUS_A}Static${C_RESET}" ;;
            *) banner_status="${C_STATUS_I}Disabled${C_RESET}" ;;
        esac

        echo -e "\n  ${C_TITLE}═════════════════[ ${C_BOLD}🎨 SSH BANNER MODE: ${banner_status} ${C_RESET}${C_TITLE}]═════════════════${C_RESET}"
        echo -e "${C_DIM}Static mode uses 'Banner $SSH_BANNER_FILE'. Dynamic mode shows per-user account info.${C_RESET}"
        printf "    ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "✨ Enable Dynamic Account Banner"
        printf "    ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "📋 Paste or Replace Static Banner"
        printf "    ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "👁️ View Current Static Banner"
        printf "    ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "📝 Preview Dynamic Banner"
        printf "    ${C_DANGER}[ 5]${C_RESET} %-40s\n" "🗑️ Disable All SSH Banners"
        echo -e "   ${C_DIM}═════════════════════════════════════════════════════${C_RESET}"
        echo -e "     ${C_WARN}[ 0]${C_RESET} ↩️ Return to Main Menu"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            return
        fi
        case $choice in
            1)
                if setup_ssh_login_info; then
                    echo -e "\n${C_GREEN}✅ Dynamic account banner enabled.${C_RESET}"
                    echo -e "${C_DIM}Users will now see their account info banner instead of the static banner.${C_RESET}"
                fi
                press_enter
                ;;
            2) set_ssh_banner_paste ;;
            3) view_ssh_banner ;;
            4) preview_dynamic_ssh_banner ;;
            5) remove_ssh_banner ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" && sleep 1 ;;
        esac
    done
}

auto_reboot_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔄 Auto-Reboot Management ---${C_RESET}"
    
    # Check status
    local cron_check=$(crontab -l 2>/dev/null | grep "systemctl reboot")
    local status="${C_STATUS_I}Disabled${C_RESET}"
    if [[ -n "$cron_check" ]]; then
        status="${C_STATUS_A}Active (Midnight)${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Current Status: ${status}${C_RESET}"
    
    echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
    printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🕐 Enable Daily Reboot (00:00 midnight)"
    printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "❌ Disable Auto-Reboot"
    echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
    echo
    read -p "👉 Enter choice: " r_choice
    
    case $r_choice in
        1)
            # Remove existing to prevent duplicates
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab -
            # Add new job
            (crontab -l 2>/dev/null; echo "0 0 * * * systemctl reboot") | crontab -
            echo -e "\n${C_GREEN}✅ Auto-reboot scheduled for every day at 00:00.${C_RESET}"
            press_enter
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab -
            echo -e "\n${C_GREEN}✅ Auto-reboot disabled.${C_RESET}"
            press_enter
            ;;
        *) return ;;
    esac
}


press_enter() {
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return to the menu..." && read -r || true
}
invalid_option() {
    echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" && sleep 1
}

main_menu() {
    while true; do
        export UNINSTALL_MODE="interactive"
        show_banner
        
        echo
        echo -e " ${C_TITLE}═══════════════════[ ${C_BOLD}👤 USER MANAGEMENT ${C_RESET}${C_TITLE}]═══════════════════${C_RESET}"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "1" "$(_pad_visual "✨ Create New User" 28)"     "2" "$(_pad_visual "🗑️ Delete user" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "3" "$(_pad_visual "🔄 Renew User Account" 28)"    "4" "$(_pad_visual "🔒 Lock User Account" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "5" "$(_pad_visual "🔓 Unlock User Account" 28)"   "6" "$(_pad_visual "✏️ Edit User Details" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "7" "$(_pad_visual "📋 List Managed Users" 28)"    "8" "$(_pad_visual "📱 Generate Client Config" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "9" "$(_pad_visual "⏱️ Create Trial Account" 28)"   "10" "$(_pad_visual "📊 View User Bandwidth" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "11" "$(_pad_visual "👥 Bulk Create Users" 28)"    "12" "$(_pad_visual "🚀 zivpn password" 28)"
        
        echo
        echo -e " ${C_TITLE}═══════════════════[ ${C_BOLD}🌐 VPN & PROTOCOLS ${C_RESET}${C_TITLE}]═══════════════════${C_RESET}"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "13" "$(_pad_visual "🔌 Protocol Manager" 28)" "14" "$(_pad_visual "📈 Traffic Monitor (Lite)" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %-28s\n" "15" "🚫 Block Torrent (Anti-P2P)"

        echo
        echo -e " ${C_TITLE}═══════════════════[ ${C_BOLD}⚙️ SYSTEM SETTINGS ${C_RESET}${C_TITLE}]═══════════════════${C_RESET}"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "16" "$(_pad_visual "☁️ CloudFlare Free Domain" 28)" "17" "$(_pad_visual "🎨 SSH Banner Config" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "18" "$(_pad_visual "🔄 Auto-Reboot Task" 28)" "19" "$(_pad_visual "💾 Backup User Data" 28)"
        printf "   ${C_CHOICE}[%2s]${C_RESET} %s ${C_CHOICE}[%2s]${C_RESET} %s\n" "20" "$(_pad_visual "📥 Restore User Data" 28)" "21" "$(_pad_visual "🧹 Cleanup Expired Users" 28)"

        echo
        echo -e " ${C_DANGER}═══════════════════[ ${C_BOLD}🔥 DANGER ZONE ${C_RESET}${C_DANGER}]═══════════════════${C_RESET}"
        echo -e "   ${C_DANGER}[99]${C_RESET} Uninstall Script             ${C_WARN}[ 0]${C_RESET} Exit"
        echo
        if ! read -r -p "$(echo -e ${C_PROMPT}"👉 Select an option: "${C_RESET})" choice; then
            echo
            exit 0
        fi
        case $choice in
            1) create_user; press_enter ;;
            2) delete_user; press_enter ;;
            3) renew_user; press_enter ;;
            4) lock_user; press_enter ;;
            5) unlock_user; press_enter ;;
            6) edit_user; press_enter ;;
            7) list_users; press_enter ;;
            8) client_config_menu; press_enter ;;
            9) create_trial_account; press_enter ;;
            10) view_user_bandwidth; press_enter ;;
            11) bulk_create_users; press_enter ;;
            12) zivpn_manage_passwords; press_enter ;;

            13) protocol_menu ;;
            14) traffic_monitor_menu ;;
            15) torrent_block_menu ;;
            
            16) dns_menu; press_enter ;;
            17) ssh_banner_menu ;;
            18) auto_reboot_menu ;;
            19) backup_user_data; press_enter ;;
            20) restore_user_data; press_enter ;;
            21) cleanup_expired; press_enter ;;
            
            99) uninstall_script ;;
            0) exit 0 ;;
            *) invalid_option ;;
        esac
    done
}

if [[ "$1" == "--install-setup" ]]; then
    initial_setup
    exit 0
fi


if [[ "$1" == "--exec" ]]; then
    shift
    action="$1"
    case "$action" in
        install_badvpn|uninstall_badvpn|\
        install_udp_custom|uninstall_udp_custom|\
        install_ssl_tunnel|uninstall_ssl_tunnel|\
        install_zivpn|uninstall_zivpn|\
        torrent_block_enable|torrent_block_disable)
            "$action" </dev/null
            exit $?
            ;;
        *)
            echo "Action non autorisée: $action" >&2
            exit 2
            ;;
    esac
fi

require_interactive_terminal
sync_runtime_components_if_needed
main_menu
