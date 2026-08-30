#!/bin/bash
# Installed by NOVA X Tunnel deploy script.
# Certbot runs every script in /etc/letsencrypt/renewal-hooks/post/ after renewal (success or failure).
systemctl start haproxy
systemctl reload nginx
exit 0
