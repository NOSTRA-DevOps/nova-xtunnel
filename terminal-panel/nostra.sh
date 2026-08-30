#!/bin/bash

cat << 'EOF' > /tmp/new_motd
#!/bin/bash
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
RESET='\033[0m'

echo -e "${CYAN}███╗   ██╗ ██████╗ ███████╗████████╗██████╗  █████╗ ${RESET}"
echo -e "${CYAN}████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗${RESET}"
echo -e "${CYAN}██╔██╗ ██║██║   ██║███████╗   ██║   ██████╔╝███████║${RESET}"
echo -e "${CYAN}██║╚██╗██║██║   ██║╚════██║   ██║   ██╔══██╗██╔══██║${RESET}"
echo -e "${CYAN}██║ ╚████║╚██████╔╝███████║   ██║   ██║  ██║██║  ██║${RESET}"
echo -e "${CYAN}╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝${RESET}"
echo -e ""
echo -e "${WHITE}=======================================================${RESET}"
echo -e "${YELLOW}                 NOVA-XTUNNEL MANAGER                  ${RESET}"
echo -e "${WHITE}=======================================================${RESET}"
echo -e "     Welcome to NOSTRA VPN Server Management Panel"
echo -e "${WHITE}=======================================================${RESET}"
echo -e " • Tg: t.me/LaboKingfreesurf • YT:youtube.com/Labokingfreesurf"
echo -e " • WA: +237 676 250 509      • TK: @labokingfreesurf"
echo -e " • Mail: contact.nostra237@gmail.com"
echo -e "${WHITE}=======================================================${RESET}"
echo -e "          Type ${YELLOW}'menu'${RESET} to open the panel."
echo -e "${WHITE}=======================================================${RESET}"
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

