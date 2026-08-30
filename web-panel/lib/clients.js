const db = require('../db/database');
const system = require('./system');
const zivpn = require('./zivpn');
const quota = require('./quota');
const audit = require('./audit');

const SYSTEM_ACTOR = { type: 'system', name: 'system' };

function getReseller(resellerId) {
  const r = db.prepare('SELECT * FROM resellers WHERE id = ?').get(resellerId);
  if (!r) throw new Error('Reseller introuvable.');
  return r;
}

function createClient(resellerId, input, actor) {
  actor = actor || SYSTEM_ACTOR;
  const reseller = getReseller(resellerId);
  const type = input.type;
  const quotaGb = input.quotaGb === '' || input.quotaGb == null ? null : parseFloat(input.quotaGb);
  const protocols = [].concat(input.protocols || []);

  quota.assertCanCreateClient(reseller, {
    quotaGb: quotaGb,
    protocols: protocols,
    type: type,
    maxConnections: type === 'ssh' ? (parseInt(input.maxConnections, 10) || 1) : null
  });

  let identifier;
  let generatedPassword = null;

  if (type === 'ssh') {
    identifier = input.username;
    const result = system.createSshUser({
      username: input.username,
      password: input.password,
      expiryDate: input.expiryDate || null,
      maxConnections: parseInt(input.maxConnections, 10) || 1,
      quotaGb: quotaGb == null ? 0 : quotaGb
    });
    generatedPassword = result.password;
  } else if (type === 'zivpn') {
    // Same defense-in-depth as system.js's createSshUser: the SSH and ZiVPN password
    // inputs share the "password" field name (hidden via CSS when not selected), so if
    // client-side JS ever fails to disable the inactive one before submit, Express would
    // hand us an ARRAY here instead of a string - take the first non-empty value rather
    // than stringifying the whole array (which would join it with a stray comma).
    const rawZivpnPwd = Array.isArray(input.password) ? (input.password.find((v) => v != null && String(v).trim() !== '') ?? '') : input.password;
    // Same rule as SSH: an explicitly-entered password must be used (or rejected with a
    // clear error) rather than silently replaced by a random one when it's just a bit short.
    const trimmedZivpnPwd = rawZivpnPwd == null ? '' : String(rawZivpnPwd).trim();
    if (trimmedZivpnPwd !== '') {
      if (trimmedZivpnPwd.length < 3) throw new Error('Mot de passe ZiVPN trop court (min. 3 caractères).');
      identifier = trimmedZivpnPwd;
    } else {
      identifier = system.randomPassword(12);
    }
    zivpn.addPassword(identifier, { expires: input.expiryDate || 'never', quotaGb: quotaGb });
    generatedPassword = identifier;
  } else {
    throw new Error('Type de client invalide.');
  }

  const stmt = db.prepare(
    "INSERT INTO clients (reseller_id, type, identifier, protocols, max_connections, quota_gb, expiry_date, status) VALUES (?, ?, ?, ?, ?, ?, ?, 'active')"
  );
  const info = stmt.run(
    resellerId,
    type,
    identifier,
    JSON.stringify(protocols),
    type === 'ssh' ? (parseInt(input.maxConnections, 10) || 1) : null,
    quotaGb,
    input.expiryDate || null
  );

  audit.log(actor.type, actor.name, 'client_create',
    'Creation du compte ' + type.toUpperCase() + ' "' + identifier + '" (reseller #' + resellerId + ')', resellerId);

  return { id: info.lastInsertRowid, identifier: identifier, password: generatedPassword };
}

function deleteClient(clientId, actor) {
  actor = actor || SYSTEM_ACTOR;
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(clientId);
  if (!client) throw new Error('Client introuvable.');

  // Capture the ACTUAL data consumed before touching the system account below (deleting
  // the ssh user also deletes its .usage file). This is what gets permanently banked into
  // the reseller's consumed total - using the client's allocated quota instead (the old
  // behaviour) overcounted every client that didn't use their full quota before deletion.
  const usageGb = clientUsageGb(client) || 0;

  if (client.type === 'ssh') {
    system.deleteSshUser(client.identifier);
  } else if (client.type === 'zivpn') {
    zivpn.removePassword(client.identifier);
  }

  if (usageGb > 0) {
    db.prepare('UPDATE resellers SET consumed_quota_gb = consumed_quota_gb + ? WHERE id = ?')
      .run(usageGb, client.reseller_id);
  }

  db.prepare(
    "UPDATE clients SET deleted = 1, deleted_at = datetime('now'), status = 'deleted', usage_at_deletion_gb = ? WHERE id = ?"
  ).run(usageGb, clientId);

  audit.log(actor.type, actor.name, 'client_delete',
    'Suppression du compte ' + client.type.toUpperCase() + ' "' + client.identifier + '"' +
    (usageGb > 0 ? ' (' + usageGb.toFixed(3) + ' Go consommes conserves dans le total du reseller)' : ''),
    client.reseller_id);
}

// Resets an SSH client's live usage counter back to 0 (a reseller convenience action).
// The amount consumed so far is banked into the reseller's permanent consumed_quota_gb
// total first - exactly like a deletion - so a reseller can't dodge their overall data
// quota simply by resetting a client's counter over and over.
function resetClientUsage(clientId, actor) {
  actor = actor || SYSTEM_ACTOR;
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(clientId);
  if (!client) throw new Error('Client introuvable.');
  if (client.type !== 'ssh') {
    throw new Error('La réinitialisation de la consommation n\'est disponible que pour les comptes SSH.');
  }

  const usageGb = clientUsageGb(client) || 0;

  if (usageGb > 0) {
    db.prepare('UPDATE resellers SET consumed_quota_gb = consumed_quota_gb + ? WHERE id = ?')
      .run(usageGb, client.reseller_id);
  }

  system.resetSshUsage(client.identifier);

  audit.log(actor.type, actor.name, 'client_reset_usage',
    'Reinitialisation de la consommation du compte SSH "' + client.identifier + '"' +
    (usageGb > 0 ? ' (' + usageGb.toFixed(3) + ' Go consommes conserves dans le total du reseller)' : ''),
    client.reseller_id);
}

function editClient(clientId, input, actor) {
  actor = actor || SYSTEM_ACTOR;
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(clientId);
  if (!client) throw new Error('Client introuvable.');

  const newQuotaGb = input.quotaGb === '' || input.quotaGb == null ? null : parseFloat(input.quotaGb);
  const newExpiry = input.expiryDate || null;
  const newMaxConn = input.maxConnections != null ? parseInt(input.maxConnections, 10) : client.max_connections;

  if (client.type === 'ssh' && newMaxConn > client.max_connections) {
    // Only re-check the reseller-wide connections cap when the limit is going UP - lowering
    // it (or leaving it unchanged) can never push the reseller over their own ceiling.
    const reseller = getReseller(client.reseller_id);
    quota.assertConnectionsWithinLimit(reseller, newMaxConn, client.id);
  }

  if (client.type === 'ssh') {
    system.renewSshUser(client.identifier, newExpiry, newMaxConn, newQuotaGb == null ? 0 : newQuotaGb);
  } else if (client.type === 'zivpn') {
    zivpn.editMeta(client.identifier, { expires: newExpiry || 'never', quotaGb: newQuotaGb });
  }

  const today = new Date().toISOString().slice(0, 10);
  const stillExpiredByDate = newExpiry && newExpiry < today;
  // The client's consumed usage doesn't change from this edit itself (only the quota
  // ceiling / expiry date do), so re-check it against the NEW quota to decide whether a
  // client that had been auto-locked for hitting its data quota is still over it after
  // this renewal - otherwise raising the quota (or setting it back to unlimited) would
  // silently leave the account locked with no obvious reason on the dashboard.
  const usageGb = clientUsageGb(client);
  const stillOverQuota = newQuotaGb != null && usageGb != null && usageGb >= newQuotaGb;
  const stillExpired = stillExpiredByDate || stillOverQuota;
  let newStatus = client.status;
  let reactivated = false;

  if (client.status === 'locked_expired' && !stillExpired) {
    if (client.type === 'ssh') system.unlockSshUser(client.identifier);
    else if (client.type === 'zivpn') zivpn.unlockPassword(client.identifier);
    newStatus = 'active';
    reactivated = true;
  }

  db.prepare('UPDATE clients SET quota_gb = ?, expiry_date = ?, max_connections = ?, status = ? WHERE id = ?')
    .run(newQuotaGb, newExpiry, newMaxConn, newStatus, clientId);

  audit.log(actor.type, actor.name, 'client_edit',
    'Modification du compte ' + client.type.toUpperCase() + ' "' + client.identifier + '"' +
    (reactivated ? ' (reactive apres renouvellement)' : ''),
    client.reseller_id);
}

function lockClient(clientId, actor) {
  actor = actor || SYSTEM_ACTOR;
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(clientId);
  if (!client) throw new Error('Client introuvable.');
  if (client.type === 'ssh') system.lockSshUser(client.identifier);
  else if (client.type === 'zivpn') zivpn.lockPassword(client.identifier);
  db.prepare("UPDATE clients SET status = 'locked_manual' WHERE id = ?").run(clientId);

  audit.log(actor.type, actor.name, 'client_lock', 'Verrouillage du compte ' + client.type.toUpperCase() + ' "' + client.identifier + '"', client.reseller_id);
}

function unlockClient(clientId, actor) {
  actor = actor || SYSTEM_ACTOR;
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(clientId);
  if (!client) throw new Error('Client introuvable.');
  if (client.type === 'ssh') system.unlockSshUser(client.identifier);
  else if (client.type === 'zivpn') zivpn.unlockPassword(client.identifier);
  db.prepare("UPDATE clients SET status = 'active' WHERE id = ?").run(clientId);

  audit.log(actor.type, actor.name, 'client_unlock', 'Deverrouillage du compte ' + client.type.toUpperCase() + ' "' + client.identifier + '"', client.reseller_id);
}

function getClientPassword(client) {
  if (client.type === 'ssh') return system.getSshPassword(client.identifier);
  if (client.type === 'zivpn') return client.identifier; // the password IS the identifier for ZiVPN
  return null;
}

function changeClientPassword(clientId, newPassword, actor) {
  actor = actor || SYSTEM_ACTOR;
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(clientId);
  if (!client) throw new Error('Client introuvable.');

  let finalPassword;
  if (client.type === 'ssh') {
    finalPassword = system.changeSshPassword(client.identifier, newPassword);
  } else if (client.type === 'zivpn') {
    if (!newPassword || newPassword.length < 3) throw new Error('Mot de passe ZiVPN trop court (min. 3 caractères).');
    zivpn.renamePassword(client.identifier, newPassword);
    db.prepare('UPDATE clients SET identifier = ? WHERE id = ?').run(newPassword, clientId);
    finalPassword = newPassword;
  } else {
    throw new Error('Type de client invalide.');
  }

  audit.log(actor.type, actor.name, 'client_password_change',
    'Mot de passe changé pour le compte ' + client.type.toUpperCase() + ' "' + client.identifier + '"', client.reseller_id);

  return finalPassword;
}

function clientUsageGb(client) {
  if (client.type === 'ssh') {
    return system.readSshUsageBytes(client.identifier) / Math.pow(1024, 3);
  }
  return null;
}

function getDeletedClients(resellerId) {
  return db.prepare('SELECT * FROM clients WHERE reseller_id = ? AND deleted = 1 ORDER BY deleted_at DESC').all(resellerId);
}

module.exports = {
  createClient: createClient,
  deleteClient: deleteClient,
  resetClientUsage: resetClientUsage,
  editClient: editClient,
  lockClient: lockClient,
  unlockClient: unlockClient,
  clientUsageGb: clientUsageGb,
  getReseller: getReseller,
  getDeletedClients: getDeletedClients,
  getClientPassword: getClientPassword,
  changeClientPassword: changeClientPassword
};
