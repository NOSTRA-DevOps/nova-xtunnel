// Mirrors menu.sh's simple_live_monitor / "View Total Traffic Since Boot": reads the same
// /sys/class/net/<iface>/statistics counters directly. No bash bridge needed for this one -
// it's pure read-only stat gathering, safe to do natively in Node.
const fs = require('fs');
const { execFileSync } = require('child_process');

function getDefaultInterface() {
  try {
    const out = execFileSync('ip', ['-4', 'route', 'ls']).toString();
    const line = out.split('\n').find((l) => l.startsWith('default'));
    if (!line) return null;
    const m = line.match(/dev (\S+)/);
    return m ? m[1] : null;
  } catch {
    return null;
  }
}

function readCounter(iface, kind) {
  try {
    return parseInt(fs.readFileSync(`/sys/class/net/${iface}/statistics/${kind}_bytes`, 'utf8').trim(), 10);
  } catch {
    return null;
  }
}

// Takes two samples ~300ms apart to compute an instantaneous rate - short enough to keep
// an HTTP request snappy, long enough to smooth out a single scheduler hiccup. The client
// polls this endpoint every couple of seconds for a live-updating view.
async function getLiveRate(iface) {
  const rx1 = readCounter(iface, 'rx');
  const tx1 = readCounter(iface, 'tx');
  if (rx1 == null || tx1 == null) return null;
  await new Promise((resolve) => setTimeout(resolve, 300));
  const rx2 = readCounter(iface, 'rx');
  const tx2 = readCounter(iface, 'tx');
  if (rx2 == null || tx2 == null) return null;

  const elapsedSec = 0.3;
  const rxBps = Math.max(0, (rx2 - rx1) / elapsedSec);
  const txBps = Math.max(0, (tx2 - tx1) / elapsedSec);
  return { rxBps, txBps, rxTotal: rx2, txTotal: tx2 };
}

function getTotalsSinceBoot(iface) {
  const rx = readCounter(iface, 'rx');
  const tx = readCounter(iface, 'tx');
  return { rx, tx };
}

function vnstatAvailable() {
  try {
    execFileSync('bash', ['-c', 'command -v vnstat']);
    return true;
  } catch {
    return false;
  }
}

function getVnstatJson(iface) {
  try {
    const out = execFileSync('vnstat', ['-i', iface, '--json']).toString();
    return JSON.parse(out);
  } catch {
    return null;
  }
}

module.exports = { getDefaultInterface, getLiveRate, getTotalsSinceBoot, vnstatAvailable, getVnstatJson };
