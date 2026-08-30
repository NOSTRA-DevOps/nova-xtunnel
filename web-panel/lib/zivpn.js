const fs = require('fs');
const { execFileSync } = require('child_process');
const config = require('../config');

function ensureFiles() {
  fs.mkdirSync(config.ZIVPN_DIR, { recursive: true });
  if (!fs.existsSync(config.ZIVPN_META_FILE)) {
    fs.writeFileSync(config.ZIVPN_META_FILE, '{}');
  }
}

function readConfig() {
  if (!fs.existsSync(config.ZIVPN_CONFIG_FILE)) {
    throw new Error('ZiVPN ne semble pas installé sur ce serveur (config.json introuvable). Installez-le depuis le panel terminal d\'abord.');
  }
  return JSON.parse(fs.readFileSync(config.ZIVPN_CONFIG_FILE, 'utf8'));
}

function writeConfig(cfg) {
  fs.writeFileSync(config.ZIVPN_CONFIG_FILE, JSON.stringify(cfg, null, 2));
}

function readMeta() {
  ensureFiles();
  return JSON.parse(fs.readFileSync(config.ZIVPN_META_FILE, 'utf8'));
}

function writeMeta(meta) {
  ensureFiles();
  fs.writeFileSync(config.ZIVPN_META_FILE, JSON.stringify(meta, null, 2));
}

function restartService() {
  try { execFileSync('systemctl', ['restart', 'zivpn']); } catch { /* service may be managed differently */ }
}

function addPassword(password, { expires, quotaGb } = {}) {
  if (!password || password.length < 3) throw new Error('Mot de passe ZiVPN trop court.');
  const cfg = readConfig();
  cfg.auth = cfg.auth || { mode: 'passwords', config: [] };
  cfg.auth.config = cfg.auth.config || [];
  if (cfg.auth.config.includes(password)) {
    throw new Error('Ce mot de passe ZiVPN existe déjà.');
  }
  cfg.auth.config.push(password);
  writeConfig(cfg);

  const meta = readMeta();
  meta[password] = {
    expires: expires || 'never',
    quota_gb: quotaGb == null ? 'unlimited' : String(quotaGb),
    created: new Date().toISOString().slice(0, 10)
  };
  writeMeta(meta);
  restartService();
}

function removePassword(password) {
  const cfg = readConfig();
  cfg.auth.config = (cfg.auth.config || []).filter((p) => p !== password);
  writeConfig(cfg);
  const meta = readMeta();
  delete meta[password];
  writeMeta(meta);
  restartService();
}

// Removes the password from the active auth list but keeps its metadata, so it can be restored later.
function lockPassword(password) {
  const cfg = readConfig();
  cfg.auth.config = (cfg.auth.config || []).filter((p) => p !== password);
  writeConfig(cfg);
  restartService();
}

function unlockPassword(password) {
  const cfg = readConfig();
  cfg.auth.config = cfg.auth.config || [];
  if (!cfg.auth.config.includes(password)) {
    cfg.auth.config.push(password);
    writeConfig(cfg);
    restartService();
  }
}

function editMeta(password, { expires, quotaGb }) {
  const meta = readMeta();
  if (!meta[password]) meta[password] = { created: new Date().toISOString().slice(0, 10) };
  if (expires !== undefined) meta[password].expires = expires || 'never';
  if (quotaGb !== undefined) meta[password].quota_gb = quotaGb == null ? 'unlimited' : String(quotaGb);
  writeMeta(meta);
}

// ZiVPN has no separate "username" - the password itself is the identifier, so "changing
// the password" means swapping the key in both the active auth list and the metadata file.
function renamePassword(oldPassword, newPassword) {
  if (!newPassword || newPassword.length < 3) throw new Error('Mot de passe ZiVPN trop court.');
  const cfg = readConfig();
  cfg.auth = cfg.auth || { mode: 'passwords', config: [] };
  cfg.auth.config = cfg.auth.config || [];
  if (cfg.auth.config.includes(newPassword)) {
    throw new Error('Ce mot de passe ZiVPN existe déjà.');
  }
  const wasActive = cfg.auth.config.includes(oldPassword);
  cfg.auth.config = cfg.auth.config.filter((p) => p !== oldPassword);
  if (wasActive) cfg.auth.config.push(newPassword);
  writeConfig(cfg);

  const meta = readMeta();
  meta[newPassword] = meta[oldPassword] || { created: new Date().toISOString().slice(0, 10) };
  delete meta[oldPassword];
  writeMeta(meta);
  restartService();
}

function isActive(password) {
  try {
    const cfg = readConfig();
    return (cfg.auth.config || []).includes(password);
  } catch {
    return false;
  }
}

module.exports = { addPassword, removePassword, lockPassword, unlockPassword, editMeta, renamePassword, isActive, readMeta };
