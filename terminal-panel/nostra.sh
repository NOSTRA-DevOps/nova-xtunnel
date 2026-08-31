#!/bin/bash

cat << 'EOF' > /tmp/new_motd
#!/bin/bash
# Palette cohérente et visible — SANS BLANC
PRIMARY='\033[1;36m'   # Cyan Éclatant (Logo et Titre principal)
BLUE='\033[38;5;46m'      # Bleu Électrique (Textes informatifs et Liens)
SEP='\033[38;5;135m'       # Violet Pur / Magenta Éclatant (Séparateurs)
LABEL='\033[38;5;196m'     # Cyan pour les étiquettes (Tg, WA...)
ACTION='\033[1;31m'    # Rouge (Mot 'menu' pour l'action)
RESET='\033[0m'        # Reset

# Logo uniforme en Cyan Éclatant
echo -e "${PRIMARY}███╗   ██╗ ██████╗ ███████╗████████╗██████╗  █████╗ ${RESET}"
echo -e "${PRIMARY}████╗  ██║██╔═══██╗██╔════╝╚══██╔══╝██╔══██╗██╔══██╗${RESET}"
echo -e "${PRIMARY}██╔██╗ ██║██║   ██║███████╗   ██║   ██████╔╝███████║${RESET}"
echo -e "${PRIMARY}██║╚██╗██║██║   ██║╚════██║   ██║   ██╔══██╗██╔══██║${RESET}"
echo -e "${PRIMARY}██║ ╚████║╚██████╔╝███████║   ██║   ██║  ██║██║  ██║${RESET}"
echo -e "${PRIMARY}╚═╝  ╚═══╝ ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝${RESET}"
echo -e ""
echo -e "${SEP}═══════════════════════════════════════════════════════${RESET}"
echo -e "${PRIMARY}                 NOVA-XTUNNEL MANAGER                  ${RESET}"
echo -e "${SEP}═══════════════════════════════════════════════════════${RESET}"
echo -e "•${LABEL}Tg:${RESET}${BLUE}t.me/LaboKingfreesurf${RESET} •${LABEL}YT:${RESET}${BLUE}youtube.com/@labokingfreesurf${RESET}"
echo -e "•${LABEL}WA:${RESET}${BLUE} +237 676 250 509     ${RESET}•${LABEL}TK:${RESET}${BLUE}@labokingfreesurf${RESET}"
echo -e "•${LABEL}Mail:${RESET}${BLUE} contact.nostra237@gmail.com${RESET}"
echo -e "${SEP}═══════════════════════════════════════════════════════${RESET}"
echo -e "${BLUE}        Welcome to NOSTRA VPN Server Manager.${RESET}"
echo -e "${BLUE}           Type ${ACTION}'menu'${RESET}${BLUE} to open the panel.${RESET}"
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
