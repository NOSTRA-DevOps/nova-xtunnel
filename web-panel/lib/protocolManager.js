// Bridges the admin "Protocol Manager" page to the SAME install/uninstall bash functions
// the terminal panel (menu.sh) already uses - rather than re-implementing (and having to
// keep in sync) things like "compile badvpn from source" or "set up the HAProxy edge
// stack" a second time in JS. See menu.sh's `--exec` dispatcher for the whitelist this
// mirrors; this file's ACTIONS list must only ever reference names present in BOTH places.
const fs = require('fs');
const path = require('path');
const { spawn, execFileSync } = require('child_process');
const config = require('../config');

// action -> { label, installFn, uninstallFn, statusCheck }
// statusCheck returns 'active' | 'inactive' | 'installed' | 'not_installed'
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
  { key: 'badvpn', label: 'badvpn (UDP 7300)', installFn: 'install_badvpn', uninstallFn: 'uninstall_badvpn', status: () => systemdActive('badvpn'), actionable: true },
  { key: 'udp_custom', label: 'udp-custom', installFn: 'install_udp_custom', uninstallFn: 'uninstall_udp_custom', status: () => systemdActive('udp-custom'), actionable: true },
  { key: 'ssl_tunnel', label: 'HAProxy Edge Stack (80/443)', installFn: 'install_ssl_tunnel', uninstallFn: 'uninstall_ssl_tunnel', status: () => systemdActive('haproxy'), actionable: true },
  { key: 'zivpn', label: 'ZiVPN (UDP 5667)', installFn: 'install_zivpn', uninstallFn: 'uninstall_zivpn', status: () => systemdActive('zivpn.service'), actionable: true },
  // These three ask for input during install (DNSTT: your domain; PY Proxy: port numbers;
  // X-UI: version to install) that can't be safely guessed or defaulted from the web -
  // getting it wrong silently would leave a broken/misconfigured service. So they're
  // status-only here (Running / Not running); actually installing or uninstalling them
  // still goes through the terminal panel, which can ask the real questions.
  { key: 'dnstt', label: 'DNSTT (Port 53)', installFn: 'install_dnstt', uninstallFn: 'uninstall_dnstt', status: () => systemdActive('dnstt.service'), actionable: false },
  { key: 'pyproxy', label: 'PY SOCKS/WS Proxy (legacy)', installFn: 'install_pyproxy', uninstallFn: 'uninstall_pyproxy', status: () => systemdActive('pyproxy-socks.service') || systemdActive('pyproxy-ws.service'), actionable: false },
  { key: 'xui', label: 'X-UI Panel', installFn: 'install_xui_panel', uninstallFn: 'uninstall_xui_panel', status: () => commandExists('x-ui'), installedLabel: true, actionable: false }
];

const ALLOWED_FUNCTIONS = new Set(PROTOCOLS.filter((p) => p.actionable).flatMap((p) => [p.installFn, p.uninstallFn]));

function ensureJobsDir() {
  fs.mkdirSync(config.PROTOCOL_JOBS_DIR, { recursive: true });
}

function jobFile(action) {
  return path.join(config.PROTOCOL_JOBS_DIR, `${action}.json`);
}
function logFile(action) {
  return path.join(config.PROTOCOL_JOBS_DIR, `${action}.log`);
}

function getProtocolsWithStatus() {
  return PROTOCOLS.map((p) => {
    const installJob = getJobStatus(p.installFn);
    const uninstallJob = getJobStatus(p.uninstallFn);
    const job = (installJob && installJob.state === 'running') ? { ...installJob, action: p.installFn }
      : (uninstallJob && uninstallJob.state === 'running') ? { ...uninstallJob, action: p.uninstallFn }
      : (installJob || uninstallJob || null);
    return { ...p, active: p.status(), job };
  });
}

function getJobStatus(action) {
  if (!action) return null;
  try {
    const raw = fs.readFileSync(jobFile(action), 'utf8');
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function getJobLog(action) {
  try {
    return fs.readFileSync(logFile(action), 'utf8');
  } catch {
    return '';
  }
}

function findSiblingAction(action) {
  const entry = PROTOCOLS.find((p) => p.installFn === action || p.uninstallFn === action);
  if (!entry) return null;
  return entry.installFn === action ? entry.uninstallFn : entry.installFn;
}

// Runs one whitelisted menu.sh function in the background (installs can take minutes -
// e.g. compiling badvpn from source - so this must never block an HTTP request). Output
// is logged to a file the admin UI polls, along with a small JSON status file so a page
// refresh mid-install still shows "running" instead of losing track of it.
function runAction(action, actor) {
  if (!ALLOWED_FUNCTIONS.has(action)) {
    throw new Error(`Action de protocole inconnue : ${action}`);
  }
  const existing = getJobStatus(action);
  const sibling = getJobStatus(findSiblingAction(action));
  if ((existing && existing.state === 'running') || (sibling && sibling.state === 'running')) {
    throw new Error('Une opération est déjà en cours pour ce protocole. Patientez.');
  }

  ensureJobsDir();
  const startedAt = new Date().toISOString();
  fs.writeFileSync(jobFile(action), JSON.stringify({ state: 'running', startedAt, actor: actor.name }));

  const out = fs.openSync(logFile(action), 'w');
  const child = spawn(config.MENU_SCRIPT_PATH, ['--exec', action], {
    stdio: ['ignore', out, out],
    detached: true
  });
  child.unref();

  child.on('exit', (code) => {
    fs.closeSync(out);
    fs.writeFileSync(jobFile(action), JSON.stringify({
      state: code === 0 ? 'success' : 'failed',
      startedAt,
      finishedAt: new Date().toISOString(),
      exitCode: code,
      actor: actor.name
    }));
  });

  return { started: true };
}

module.exports = { PROTOCOLS, getProtocolsWithStatus, getJobStatus, getJobLog, runAction, ALLOWED_FUNCTIONS };
