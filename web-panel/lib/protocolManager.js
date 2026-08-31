// Read-only protocol status for the admin "System" page. 
const { execFileSync } = require('child_process');

function systemdActive(unit) {
  try {
    execFileSync('systemctl', ['is-active', '--quiet', unit]);
    return true;
  } catch {
    return false;
  }
}

function commandExists(cmd) {
  try {
    execFileSync('bash', ['-c', `command -v ${cmd}`]);
    return true;
  } catch {
    return false;
  }
}

const PROTOCOLS = [
  { key: 'badvpn', label: 'badvpn (UDP 7300)', status: () => systemdActive('badvpn') },
  { key: 'udp_custom', label: 'udp-custom', status: () => systemdActive('udp-custom') },
  { key: 'ssl_tunnel', label: 'HAProxy Edge Stack (80/443)', status: () => systemdActive('haproxy') },
  { key: 'zivpn', label: 'ZiVPN (UDP 5667)', status: () => systemdActive('zivpn.service') },
  { key: 'dnstt', label: 'DNSTT (Port 53)', status: () => systemdActive('dnstt.service') },
  { key: 'pyproxy', label: 'PY SOCKS/WS Proxy (legacy)', status: () => systemdActive('pyproxy-socks.service') || systemdActive('pyproxy-ws.service') },
  { key: 'xui', label: 'X-UI Panel', status: () => commandExists('x-ui') }
];

function getProtocolsWithStatus() {
  return PROTOCOLS.map((p) => ({ key: p.key, label: p.label, active: p.status() }));
}

module.exports = { PROTOCOLS, getProtocolsWithStatus };
