#!/bin/bash
# Installed by NOVA X Tunnel deploy script.
# Certbot runs every script in /etc/letsencrypt/renewal-hooks/pre/ before attempting renewal.
systemctl is-active --quiet haproxy && systemctl stop haproxy
exit 0
