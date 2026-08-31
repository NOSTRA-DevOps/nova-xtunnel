// OS name / public IP / uptime for the admin System page - the same three facts the
// terminal panel's banner shows. Public IP is cached in-process (fetched once per server
// start) since it practically never changes and re-fetching on every page load would add
// needless external-network latency to opening this page.
const fs = require('fs');
const os = require('os');
const { execFileSync } = require('child_process');

let cachedServerIp = null;

function getOsName() {
  try {
    const raw = fs.readFileSync('/etc/os-release', 'utf8');
    const match = raw.match(/^PRETTY_NAME="(.+)"$/m);
    if (match) return match[1];
  } catch { /* not on Linux, or file missing */ }
  return `${os.type()} ${os.release()}`;
}

function getServerIp() {
  if (cachedServerIp) return cachedServerIp;
  try {
    cachedServerIp = execFileSync('curl', ['-s', '-4', '--max-time', '3', 'icanhazip.com'])
      .toString().trim();
  } catch { /* offline, or curl unavailable */ }
  if (!cachedServerIp) {
    const nets = os.networkInterfaces();
    for (const iface of Object.values(nets)) {
      for (const addr of iface || []) {
        if (addr.family === 'IPv4' && !addr.internal) { cachedServerIp = addr.address; break; }
      }
      if (cachedServerIp) break;
    }
  }
  if (!cachedServerIp) cachedServerIp = 'unavailable';
  return cachedServerIp;
}

// Formats os.uptime() (seconds) the same way as the terminal panel's `uptime -p` (e.g.
// "3 days, 4 hours, 12 minutes") so both panels read consistently.
function getUptime() {
  let totalSeconds = Math.floor(os.uptime());
  const days = Math.floor(totalSeconds / 86400); totalSeconds -= days * 86400;
  const hours = Math.floor(totalSeconds / 3600); totalSeconds -= hours * 3600;
  const minutes = Math.floor(totalSeconds / 60);

  const parts = [];
  if (days > 0) parts.push(`${days} day${days !== 1 ? 's' : ''}`);
  if (hours > 0) parts.push(`${hours} hour${hours !== 1 ? 's' : ''}`);
  if (minutes > 0 || parts.length === 0) parts.push(`${minutes} minute${minutes !== 1 ? 's' : ''}`);
  return parts.join(', ');
}

module.exports = { getOsName, getServerIp, getUptime };
