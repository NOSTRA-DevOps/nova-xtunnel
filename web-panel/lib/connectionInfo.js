const fs = require('fs');
const { execFileSync } = require('child_process');
const config = require('../config');

function serviceActive(name) {
  try {
    execFileSync('systemctl', ['is-active', '--quiet', name]);
    return true;
  } catch {
    return false;
  }
}

function readShellVars(filePath) {
  if (!fs.existsSync(filePath)) return {};
  const out = {};
  const raw = fs.readFileSync(filePath, 'utf8');
  raw.split('\n').forEach((line) => {
    const m = line.match(/^([A-Z_]+)="?([^"\n]*)"?$/);
    if (m) out[m[1]] = m[2];
  });
  return out;
}

let cachedIp = null;
let cachedIpAt = 0;
const IP_CACHE_MS = 60 * 60 * 1000; // 1h — a VPS's public IP essentially never changes mid-session

// The panel's own DOMAIN (config.DOMAIN) is only the address used to reach THIS admin
// panel — it has nothing to do with the tunnel server a client actually connects to.
// Clients must be given the VPS's public IP instead.
function getHost() {
  const now = Date.now();
  if (cachedIp && (now - cachedIpAt) < IP_CACHE_MS) return cachedIp;

  const candidates = [
    () => execFileSync('curl', ['-s', '-4', '--max-time', '3', 'https://api.ipify.org']).toString().trim(),
    () => execFileSync('curl', ['-s', '-4', '--max-time', '3', 'https://ifconfig.me']).toString().trim(),
    () => execFileSync('hostname', ['-I']).toString().trim().split(/\s+/)[0]
  ];
  for (const get of candidates) {
    try {
      const ip = get();
      if (/^\d{1,3}(\.\d{1,3}){3}$/.test(ip)) {
        cachedIp = ip;
        cachedIpAt = now;
        return ip;
      }
    } catch { /* try next method */ }
  }
  return '<ip-du-vps-indisponible>';
}

// The SNI/"BugHost" domain for HAProxy/Nginx TLS payloads is a SEPARATE thing from both
// the panel's own domain and the VPS IP: it's whatever domain was pointed at this server
// and issued a cert via the terminal panel's CloudFlare/Let's Encrypt edge stack setup.
function getEdgeDomain() {
  const vars = readShellVars(config.EDGE_CERT_INFO_FILE);
  return vars.EDGE_DOMAIN && vars.EDGE_DOMAIN.trim() ? vars.EDGE_DOMAIN.trim() : null;
}

function getZivpnPort() {
  try {
    const cfg = JSON.parse(fs.readFileSync(config.ZIVPN_CONFIG_FILE, 'utf8'));
    return (cfg.listen || ':5667').replace(':', '') || '5667';
  } catch {
    return '5667';
  }
}

// Returns an array of { title, lines[] } sections, only for services actually active
// on this server AND protocols enabled for this specific client.
function buildConnectionInfo(client) {
  const host = getHost();
  const protocols = JSON.parse(client.protocols || '[]');
  const sections = [];

  sections.push({
    title: 'Identifiants',
    lines: [
      `${client.type === 'ssh' ? 'Utilisateur' : 'Mot de passe ZiVPN'}: ${client.identifier}`,
      `Hôte: ${host}`
    ]
  });

  if (client.type === 'ssh') {
    sections.push({ title: 'SSH direct', lines: ['Port: 22', 'Payload: SSH standard'] });

    if (protocols.some((p) => ['ssh_ws', 'ssh_tls'].includes(p)) && (serviceActive('haproxy') || serviceActive('nginx'))) {
      const sniHost = getEdgeDomain() || host;
      sections.push({
        title: 'HAProxy / Nginx (WS & TLS)',
        lines: [
          `Port ${config.EDGE_PUBLIC_HTTP_PORT}: payloads HTTP / SSH brut`,
          `Port ${config.EDGE_PUBLIC_TLS_PORT}: TLS / SNI / payloads SSL`,
          `SNI (BugHost): ${sniHost}`
        ]
      });
    }

    if (protocols.includes('ssh_udp') && serviceActive('udp-custom')) {
      sections.push({
        title: 'UDP Custom',
        lines: [`IP VPS: ${host}`, 'Port: 1-65535 (hors 53, 5300)', 'Obfs: aucun/plain']
      });
    }

    if (protocols.includes('slowdns') && serviceActive('dnstt')) {
      const dnstt = readShellVars(config.DNSTT_CONFIG_FILE);
      sections.push({
        title: 'SSH SlowDNS (DNSTT)',
        lines: [
          `Nameserver: ${dnstt.TUNNEL_DOMAIN || '(non configuré)'}`,
          `PubKey: ${dnstt.PUBLIC_KEY || '(non configuré)'}`,
          'DNS IP: 1.1.1.1 / 8.8.8.8'
        ]
      });
    }
  }

  if (client.type === 'zivpn') {
    sections.push({
      title: 'ZiVPN',
      lines: [`Port UDP: ${getZivpnPort()}`, 'Ports redirigés: 6000-19999']
    });
  }

  return sections;
}

module.exports = { buildConnectionInfo };
