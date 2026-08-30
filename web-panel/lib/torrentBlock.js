// Torrent blocking is just a handful of iptables string-match rules (see menu.sh's
// torrent_block_enable/disable) - unlike the protocol installs, this finishes in
// milliseconds, so it's run synchronously via the same --exec bridge rather than through
// protocolManager's background job tracking.
const { execFileSync } = require('child_process');
const config = require('../config');

function isEnabled() {
  try {
    const forward = execFileSync('iptables', ['-L', 'FORWARD']).toString();
    if (forward.includes('ipp2p')) return true;
  } catch { /* iptables unavailable or not permitted - fall through */ }
  try {
    const output = execFileSync('iptables', ['-L', 'OUTPUT']).toString();
    if (output.includes('BitTorrent')) return true;
  } catch { /* ignore */ }
  return false;
}

function setEnabled(enabled) {
  const action = enabled ? 'torrent_block_enable' : 'torrent_block_disable';
  execFileSync(config.MENU_SCRIPT_PATH, ['--exec', action], { timeout: 15000 });
  return isEnabled();
}

module.exports = { isEnabled, setEnabled };
