// NOVA X Tunnel - shared configuration
// IMPORTANT: these paths intentionally match the ones used by menu.sh (the terminal panel)
// so the web panel and the terminal panel manage the SAME underlying SSH/ZiVPN accounts
// without conflicting or requiring any reinstall.

const path = require('path');

module.exports = {
  VERSION: '2.0.0',

  // Web server
  PORT: process.env.PORT || 3000,
  SESSION_SECRET: process.env.SESSION_SECRET || 'change-this-secret-in-.env',
  DOMAIN: process.env.DOMAIN || '',
  PUBLIC_PORT: process.env.PUBLIC_PORT || '',
  // Set to "true" in .env when the panel sits behind Nginx/TLS (the deploy script does this
  // automatically) so session cookies are marked Secure and Express trusts X-Forwarded-* headers.
  BEHIND_TLS_PROXY: String(process.env.BEHIND_TLS_PROXY || 'false').toLowerCase() === 'true',

  // TLS_MODE:
  //   "nginx" (default) - Nginx terminates TLS and reverse-proxies to the Node app on PORT.
  //   "node"             - the Node app itself terminates TLS using the domain's own certificate
  //                        (CERT_PATH/KEY_PATH) and listens directly on PUBLIC_PORT. No Nginx involved.
  TLS_MODE: (process.env.TLS_MODE || 'nginx').toLowerCase(),
  CERT_PATH: process.env.CERT_PATH || '',
  KEY_PATH: process.env.KEY_PATH || '',

  // Shared with menu.sh
  DB_DIR: '/etc/novaxtunnel',
  SSH_USERS_DB: '/etc/novaxtunnel/users.db', // format: username:password:expire_date:conn_limit:bandwidth_gb
  BANDWIDTH_DIR: '/etc/novaxtunnel/bandwidth', // <user>.usage files contain bytes used (maintained by menu.sh's bandwidth service)
  FF_USERS_GROUP: 'ffusers',

  ZIVPN_DIR: '/etc/zivpn',
  ZIVPN_CONFIG_FILE: '/etc/zivpn/config.json',
  ZIVPN_META_FILE: '/etc/zivpn/passwords_meta.json', // format matches menu.sh: { "password": {expires, quota_gb, created} }

  DNSTT_CONFIG_FILE: '/etc/novaxtunnel/dnstt_info.conf',
  EDGE_CERT_INFO_FILE: '/etc/novaxtunnel/edge_cert.conf', // written by terminal-panel menu.sh (EDGE_DOMAIN=...)
  EDGE_PUBLIC_HTTP_PORT: '80',
  EDGE_PUBLIC_TLS_PORT: '443',

  // Panel's own database (separate from the above - stores reseller/admin accounts & business rules)
  PANEL_DB_FILE: path.join(__dirname, 'db', 'panel.sqlite3'),

  PROTOCOLS: [
    { key: 'ssh_ws', label: 'SSH WS (WebSocket)' },
    { key: 'ssh_udp', label: 'SSH UDP Custom' },
    { key: 'ssh_tls', label: 'SSH TLS (Stunnel/HAProxy)' },
    { key: 'slowdns', label: 'SSH SlowDNS' },
    { key: 'zivpn', label: 'ZIVPN' }
  ],


  MENU_SCRIPT_PATH: '/usr/local/bin/menu',
  PROTOCOL_JOBS_DIR: '/etc/novaxtunnel/protocol_jobs'
};
