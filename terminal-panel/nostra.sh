#!/bin/bash

cat << 'EOF' > /tmp/new_motd
#!/bin/bash

LOGO_TOP='\033[1;35m'  # Magenta / Violet électrique (haut du logo)
LOGO_BOT='\033[1;36m'  # Cyan néon (bas du logo)
SEP='\033[1;33m'       # Jaune Or brillant (séparateurs très visibles)
TITLE='\033[1;37m'     # Blanc Pur Éclatant (titre principal)
LABEL='\033[1;32m'     # Vert Émeraude (balises réseaux: Tg, WA...)
TEXT='\033[0;37m'      # Blanc Standard (liens et texte de bienvenue)
ACTION='\033[1;31m'    # Rouge Flash (mot 'menu')
RESET='\033[0m'        # Reset

# Logo avec dégradé Néon (Magenta vers Cyan)
echo -e "${LOGO_TOP}███╗   ██╗ ██████╗ ███████╗████████╗██████╗  █████╗ ${RESET}"
echo -e "${LOGO_TOP}████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗${RESET}"
echo -e "${LOGO_BOT}██╔██╗ ██║██║   ██║███████╗   ██║   ██████╔╝███████║${RESET}"
echo -e "${LOGO_BOT}██║╚██╗██║██║   ██║╚════██║   ██║   ██╔══██╗██╔══██║${RESET}"
echo -e "${LOGO_BOT}██║ ╚████║╚██████╔╝███████║   ██║   ██║  ██║██║  ██║${RESET}"
echo -e "${LOGO_BOT}╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝${RESET}"
echo -e ""
echo -e "${SEP}═══════════════════════════════════════════════════════${RESET}"
echo -e "${TITLE}                 NOVA-XTUNNEL MANAGER                  ${RESET}"
echo -e "${SEP}═══════════════════════════════════════════════════════${RESET}"
echo -e "•${LABEL}Tg:${RESET}${TEXT}t.me/LaboKingfreesurf${RESET} •${LABEL}YT:${RESET}${TEXT}youtube.com/labokingfreesurf{RESET}"
echo -e "•${LABEL}WA:${RESET}${TEXT} +237 676 250 509     ${RESET}•${LABEL}TK:${RESET}${TEXT}@labokingfreesurf${RESET}"
echo -e "•${LABEL}Mail:${RESET}${TEXT} contact.nostra237@gmail.com${RESET}"
echo -e "${SEP}═══════════════════════════════════════════════════════${RESET}"
echo -e "${TEXT}        Welcome to NOSTRA VPN Server Manager.${RESET}"
echo -e "${TEXT}           Type ${ACTION}'menu'${RESET}${TEXT} to open the panel.${RESET}"
echo -e "${SEP}═══════════════════════════════════════════════════════${RESET}"
EOF

# 2. Déploiement dans le répertoire système
sudo mkdir -p /etc/update-motd.d
sudo cp /tmp/new_motd /etc/update-motd.d/99-nostra-banner
sudo chmod +x /etc/update-motd.d/99-nostra-banner

# 3. Suppression des résidus et scripts tiers 
sudo find /etc/update-motd.d/ -type f ! -name '99-nostra-banner' -exec chmod -x {} + 2>/dev/null

# 4. Nettoyage des fichiers textes fixes
echo "" | sudo tee /etc/motd > /dev/null
echo "" | sudo tee /etc/issue > /dev/null
rm /tmp/new_motd
