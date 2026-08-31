const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../db/database');
const quota = require('../lib/quota');
const clientsLib = require('../lib/clients');
const audit = require('../lib/audit');
const connectionInfo = require('../lib/connectionInfo');
const config = require('../config');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();
router.use(requireAdmin);

function actorFrom(req) {
  return { type: 'admin', name: req.session.username };
}

router.get('/', (req, res) => {
  const resellers = db.prepare('SELECT * FROM resellers ORDER BY created_at DESC').all();
  const enriched = resellers.map((r) => ({ ...r, stats: quota.getResellerStats(r) }));
  const activity = audit.recent(null, 10);
  res.render('admin/dashboard', {
    resellers: enriched, protocols: config.PROTOCOLS, activity,
    error: req.query.error, success: req.query.success
  });
});

router.get('/activity', (req, res) => {
  const activity = audit.recent(null, 300);
  res.render('activity', { activity, backUrl: '/admin' });
});

router.post('/resellers', (req, res) => {
  try {
    const { username, password, max_users, data_quota_gb, expiry_date, notes } = req.body;
    const protocols = [].concat(req.body.protocols || []);
    if (!username || !password) throw new Error('Nom d\'utilisateur et mot de passe requis.');

    const hash = bcrypt.hashSync(password, 10);
    const info = db.prepare(`
      INSERT INTO resellers (username, password_hash, data_quota_gb, max_users, protocols, expiry_date, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(
      username,
      hash,
      data_quota_gb === '' ? null : parseFloat(data_quota_gb),
      parseInt(max_users, 10) || 10,
      JSON.stringify(protocols),
      expiry_date || null,
      notes || ''
    );

    audit.log('admin', req.session.username, 'reseller_create', `Création du reseller "${username}"`, info.lastInsertRowid);
    res.redirect('/admin?success=' + encodeURIComponent('Reseller créé avec succès.'));
  } catch (e) {
    res.redirect('/admin?error=' + encodeURIComponent(e.message));
  }
});

router.get('/resellers/:id', (req, res) => {
  const reseller = db.prepare('SELECT * FROM resellers WHERE id = ?').get(req.params.id);
  if (!reseller) return res.redirect('/admin?error=Reseller introuvable');
  const stats = quota.getResellerStats(reseller);
  const clientsWithUsage = stats.clients.map((c) => ({
    ...c,
    usageGb: clientsLib.clientUsageGb(c),
    connectionInfo: connectionInfo.buildConnectionInfo(c),
    password: clientsLib.getClientPassword(c),
    onlineCount: c._online
  }));
  const deletedClients = clientsLib.getDeletedClients(reseller.id);
  const activity = audit.recent(reseller.id, 10);

  res.render('admin/reseller_detail', {
    reseller, stats, clients: clientsWithUsage, deletedClients, activity, protocols: config.PROTOCOLS,
    error: req.query.error, success: req.query.success
  });
});

router.post('/resellers/:id/edit', (req, res) => {
  const id = req.params.id;
  try {
    const { max_users, data_quota_gb, expiry_date, notes, new_password } = req.body;
    const protocols = [].concat(req.body.protocols || []);

    db.prepare(`
      UPDATE resellers SET max_users = ?, data_quota_gb = ?, protocols = ?, expiry_date = ?, notes = ?
      WHERE id = ?
    `).run(
      parseInt(max_users, 10) || 10,
      data_quota_gb === '' ? null : parseFloat(data_quota_gb),
      JSON.stringify(protocols),
      expiry_date || null,
      notes || '',
      id
    );

    if (new_password) {
      const hash = bcrypt.hashSync(new_password, 10);
      db.prepare('UPDATE resellers SET password_hash = ? WHERE id = ?').run(hash, id);
    }

    audit.log('admin', req.session.username, 'reseller_edit', 'Paramètres du reseller mis à jour' + (new_password ? ' (mot de passe changé)' : ''), id);
    res.redirect(`/admin/resellers/${id}?success=` + encodeURIComponent('Reseller mis à jour.'));
  } catch (e) {
    res.redirect(`/admin/resellers/${id}?error=` + encodeURIComponent(e.message));
  }
});

router.post('/resellers/:id/toggle-lock', (req, res) => {
  const reseller = db.prepare('SELECT * FROM resellers WHERE id = ?').get(req.params.id);
  const newStatus = reseller.status === 'active' ? 'locked_manual' : 'active';
  db.prepare('UPDATE resellers SET status = ? WHERE id = ?').run(newStatus, reseller.id);
  audit.log('admin', req.session.username, 'reseller_toggle_lock',
    `Reseller "${reseller.username}" ${newStatus === 'active' ? 'déverrouillé' : 'verrouillé'} manuellement`, reseller.id);

  const activeClients = db.prepare('SELECT * FROM clients WHERE reseller_id = ? AND deleted = 0').all(reseller.id);
  for (const c of activeClients) {
    try {
      if (newStatus === 'locked_manual') clientsLib.lockClient(c.id, actorFrom(req));
      else if (c.status !== 'locked_manual') clientsLib.unlockClient(c.id, actorFrom(req));
    } catch { /* keep going even if one account fails */ }
  }
  res.redirect(`/admin/resellers/${reseller.id}?success=` + encodeURIComponent('Statut du reseller mis à jour.'));
});

router.post('/resellers/:id/delete', (req, res) => {
  const id = req.params.id;
  try {
    const reseller = db.prepare('SELECT * FROM resellers WHERE id = ?').get(id);
    const activeClients = db.prepare('SELECT * FROM clients WHERE reseller_id = ? AND deleted = 0').all(id);
    for (const c of activeClients) {
      try { clientsLib.deleteClient(c.id, actorFrom(req)); } catch { /* continue cleanup */ }
    }
    db.prepare('DELETE FROM resellers WHERE id = ?').run(id);
    audit.log('admin', req.session.username, 'reseller_delete', `Suppression du reseller "${reseller ? reseller.username : id}" et de tous ses comptes`, null);
    res.redirect('/admin?success=' + encodeURIComponent('Reseller et ses comptes supprimés.'));
  } catch (e) {
    res.redirect('/admin?error=' + encodeURIComponent(e.message));
  }
});

router.post('/change-password', (req, res) => {
  try {
    const { new_password } = req.body;
    if (!new_password || new_password.length < 6) throw new Error('Le mot de passe doit contenir au moins 6 caractères.');
    const hash = bcrypt.hashSync(new_password, 10);
    db.prepare('UPDATE admins SET password_hash = ? WHERE id = ?').run(hash, req.session.userId);
    audit.log('admin', req.session.username, 'admin_change_password', 'Mot de passe admin changé', null);
    res.redirect('/admin?success=' + encodeURIComponent('Mot de passe admin mis à jour.'));
  } catch (e) {
    res.redirect('/admin?error=' + encodeURIComponent(e.message));
  }
});

router.post('/resellers/:id/clients', (req, res) => {
  const resellerId = req.params.id;
  try {
    clientsLib.createClient(resellerId, req.body, actorFrom(req));
    res.redirect(`/admin/resellers/${resellerId}?success=` + encodeURIComponent('Compte client créé.'));
  } catch (e) {
    res.redirect(`/admin/resellers/${resellerId}?error=` + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/edit', (req, res) => {
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.clientId);
  try {
    clientsLib.editClient(req.params.clientId, req.body, actorFrom(req));
    res.redirect(`/admin/resellers/${client.reseller_id}?success=` + encodeURIComponent('Client mis à jour.'));
  } catch (e) {
    res.redirect(`/admin/resellers/${client.reseller_id}?error=` + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/delete', (req, res) => {
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.clientId);
  try {
    clientsLib.deleteClient(req.params.clientId, actorFrom(req));
    res.redirect(`/admin/resellers/${client.reseller_id}?success=` + encodeURIComponent('Client supprimé.'));
  } catch (e) {
    res.redirect(`/admin/resellers/${client.reseller_id}?error=` + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/reset-usage', (req, res) => {
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.clientId);
  try {
    clientsLib.resetClientUsage(req.params.clientId, actorFrom(req));
    res.redirect(`/admin/resellers/${client.reseller_id}?success=` + encodeURIComponent('Consommation du client réinitialisée.'));
  } catch (e) {
    res.redirect(`/admin/resellers/${client.reseller_id}?error=` + encodeURIComponent(e.message));
  }
});

router.post('/resellers/:id/reset-quota', (req, res) => {
  const id = req.params.id;
  try {
    const reseller = db.prepare('SELECT * FROM resellers WHERE id = ?').get(id);
    if (!reseller) throw new Error('Reseller introuvable.');

    // Purely a *display* reset: clients and their live usage are left completely untouched,
    // and the historical "consommé par comptes supprimés" figure is untouched too. We just
    // capture the reseller's current raw total (live usage + everything banked so far) into
    // quota_reset_offset_gb, which getResellerStats() subtracts back out - so the displayed
    // consumed total drops to 0 right now, then grows again only from what's consumed from
    // this point forward, like zeroing an odometer trip counter.
    const statsBefore = quota.getResellerStats(reseller);
    const rawTotalGb = statsBefore.consumedTotalGb + (reseller.quota_reset_offset_gb || 0);
    db.prepare('UPDATE resellers SET quota_reset_offset_gb = ? WHERE id = ?').run(rawTotalGb, id);
    audit.log('admin', req.session.username, 'reseller_reset_quota',
      `Quota consommé total remis à zéro (affichage) pour "${reseller.username}" — clients non affectés`, id);
    res.redirect(`/admin/resellers/${id}?success=` + encodeURIComponent('Quota consommé du reseller réinitialisé.'));
  } catch (e) {
    res.redirect(`/admin/resellers/${id}?error=` + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/toggle-lock', (req, res) => {
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.clientId);
  try {
    if (client.status === 'locked_manual') clientsLib.unlockClient(req.params.clientId, actorFrom(req));
    else clientsLib.lockClient(req.params.clientId, actorFrom(req));
    res.redirect(`/admin/resellers/${client.reseller_id}?success=` + encodeURIComponent('Statut mis à jour.'));
  } catch (e) {
    res.redirect(`/admin/resellers/${client.reseller_id}?error=` + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/password', (req, res) => {
  const client = db.prepare('SELECT * FROM clients WHERE id = ?').get(req.params.clientId);
  try {
    const newPass = clientsLib.changeClientPassword(req.params.clientId, req.body.new_password, actorFrom(req));
    res.redirect(`/admin/resellers/${client.reseller_id}?success=` + encodeURIComponent('Mot de passe mis à jour : ' + newPass));
  } catch (e) {
    res.redirect(`/admin/resellers/${client.reseller_id}?error=` + encodeURIComponent(e.message));
  }
});

// ---- System management: Protocol Manager / Traffic Monitor / Block Torrent ----
// Mirrors the terminal panel (menu.sh)'s equivalent menu items - admin-only, since these
// are server-wide infrastructure changes, not per-reseller/per-client account management.
// Protocol status is READ-ONLY here (see lib/protocolManager.js) - installing/uninstalling
// stays in the terminal panel, which can ask the domain/port/version questions some of
// them need.
const protocolManager = require('../lib/protocolManager');
const trafficMonitor = require('../lib/trafficMonitor');
const torrentBlock = require('../lib/torrentBlock');
const systemInfo = require('../lib/systemInfo');

router.get('/system', (req, res) => {
  const iface = trafficMonitor.getDefaultInterface();
  res.render('admin/system', {
    protocols: protocolManager.getProtocolsWithStatus(),
    iface,
    totals: iface ? trafficMonitor.getTotalsSinceBoot(iface) : { rx: null, tx: null },
    vnstatInstalled: trafficMonitor.vnstatAvailable(),
    torrentBlockEnabled: torrentBlock.isEnabled(),
    osName: systemInfo.getOsName(),
    serverIp: systemInfo.getServerIp(),
    uptime: systemInfo.getUptime(),
    error: req.query.error, success: req.query.success
  });
});

router.get('/system/traffic', async (req, res) => {
  const iface = trafficMonitor.getDefaultInterface();
  if (!iface) return res.json({ error: 'no_interface' });
  const rate = await trafficMonitor.getLiveRate(iface);
  const totals = trafficMonitor.getTotalsSinceBoot(iface);
  res.json({ iface, rate, totals });
});

router.post('/system/torrent-block', (req, res) => {
  try {
    const enabled = torrentBlock.setEnabled(req.body.enabled === '1');
    audit.log('admin', req.session.username, 'torrent_block_toggle', `Torrent blocking ${enabled ? 'enabled' : 'disabled'}`, null);
    res.redirect('/admin/system?success=' + encodeURIComponent(enabled ? 'Torrent blocking enabled.' : 'Torrent blocking disabled.'));
  } catch (e) {
    res.redirect('/admin/system?error=' + encodeURIComponent(e.message));
  }
});

module.exports = router;
