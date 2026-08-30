const express = require('express');
const db = require('../db/database');
const quota = require('../lib/quota');
const clientsLib = require('../lib/clients');
const audit = require('../lib/audit');
const connectionInfo = require('../lib/connectionInfo');
const config = require('../config');
const { requireReseller } = require('../middleware/auth');

const router = express.Router();
router.use(requireReseller);

function loadSelf(req) {
  return db.prepare('SELECT * FROM resellers WHERE id = ?').get(req.session.userId);
}

function actorFrom(req) {
  return { type: 'reseller', name: req.session.username };
}

router.get('/', (req, res) => {
  const reseller = loadSelf(req);
  if (!reseller) return res.redirect('/login');
  const stats = quota.getResellerStats(reseller);
  const clients = stats.clients.map((c) => ({
    ...c,
    usageGb: clientsLib.clientUsageGb(c),
    connectionInfo: connectionInfo.buildConnectionInfo(c),
    password: clientsLib.getClientPassword(c),
    onlineCount: c._online
  }));
  const deletedClients = clientsLib.getDeletedClients(reseller.id);
  const activity = audit.recentByActor(reseller.id, 'reseller', 10);
  const allowedProtocols = config.PROTOCOLS.filter((p) => JSON.parse(reseller.protocols || '[]').includes(p.key));

  res.render('reseller/dashboard', {
    reseller, stats, clients, deletedClients, activity, allowedProtocols,
    error: req.query.error, success: req.query.success
  });
});

router.get('/activity', (req, res) => {
  const reseller = loadSelf(req);
  if (!reseller) return res.redirect('/login');
  const activity = audit.recentByActor(reseller.id, 'reseller', 300);
  res.render('activity', { activity, backUrl: '/reseller' });
});

router.post('/clients', (req, res) => {
  const reseller = loadSelf(req);
  try {
    const result = clientsLib.createClient(reseller.id, req.body, actorFrom(req));
    let msg = 'Compte client créé.';
    if (result.password) msg += ` Identifiants — ${req.body.type === 'ssh' ? 'utilisateur' : 'mot de passe'}: ${result.identifier}${req.body.type === 'ssh' ? ' / mdp: ' + result.password : ''}`;
    res.redirect('/reseller?success=' + encodeURIComponent(msg));
  } catch (e) {
    res.redirect('/reseller?error=' + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/edit', (req, res) => {
  const reseller = loadSelf(req);
  const client = db.prepare('SELECT * FROM clients WHERE id = ? AND reseller_id = ?').get(req.params.clientId, reseller.id);
  if (!client) return res.redirect('/reseller?error=Client introuvable');
  try {
    clientsLib.editClient(client.id, req.body, actorFrom(req));
    res.redirect('/reseller?success=' + encodeURIComponent('Client mis à jour.'));
  } catch (e) {
    res.redirect('/reseller?error=' + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/delete', (req, res) => {
  const reseller = loadSelf(req);
  const client = db.prepare('SELECT * FROM clients WHERE id = ? AND reseller_id = ?').get(req.params.clientId, reseller.id);
  if (!client) return res.redirect('/reseller?error=Client introuvable');
  try {
    clientsLib.deleteClient(client.id, actorFrom(req));
    res.redirect('/reseller?success=' + encodeURIComponent('Client supprimé.'));
  } catch (e) {
    res.redirect('/reseller?error=' + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/reset-usage', (req, res) => {
  const reseller = loadSelf(req);
  const client = db.prepare('SELECT * FROM clients WHERE id = ? AND reseller_id = ?').get(req.params.clientId, reseller.id);
  if (!client) return res.redirect('/reseller?error=Client introuvable');
  try {
    clientsLib.resetClientUsage(client.id, actorFrom(req));
    res.redirect('/reseller?success=' + encodeURIComponent('Consommation du client réinitialisée.'));
  } catch (e) {
    res.redirect('/reseller?error=' + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/toggle-lock', (req, res) => {
  const reseller = loadSelf(req);
  const client = db.prepare('SELECT * FROM clients WHERE id = ? AND reseller_id = ?').get(req.params.clientId, reseller.id);
  if (!client) return res.redirect('/reseller?error=Client introuvable');
  try {
    if (client.status === 'locked_manual') clientsLib.unlockClient(client.id, actorFrom(req));
    else clientsLib.lockClient(client.id, actorFrom(req));
    res.redirect('/reseller?success=' + encodeURIComponent('Statut mis à jour.'));
  } catch (e) {
    res.redirect('/reseller?error=' + encodeURIComponent(e.message));
  }
});

router.post('/clients/:clientId/password', (req, res) => {
  const reseller = loadSelf(req);
  const client = db.prepare('SELECT * FROM clients WHERE id = ? AND reseller_id = ?').get(req.params.clientId, reseller.id);
  if (!client) return res.redirect('/reseller?error=Client introuvable');
  try {
    const newPass = clientsLib.changeClientPassword(client.id, req.body.new_password, actorFrom(req));
    res.redirect('/reseller?success=' + encodeURIComponent('Mot de passe mis à jour : ' + newPass));
  } catch (e) {
    res.redirect('/reseller?error=' + encodeURIComponent(e.message));
  }
});

router.post('/change-password', (req, res) => {
  const reseller = loadSelf(req);
  try {
    const { new_password } = req.body;
    if (!new_password || new_password.length < 6) throw new Error('Le mot de passe doit contenir au moins 6 caractères.');
    const bcrypt = require('bcryptjs');
    const hash = bcrypt.hashSync(new_password, 10);
    db.prepare('UPDATE resellers SET password_hash = ? WHERE id = ?').run(hash, reseller.id);
    audit.log('reseller', req.session.username, 'reseller_change_password', 'Mot de passe changé', reseller.id);
    res.redirect('/reseller?success=' + encodeURIComponent('Mot de passe mis à jour.'));
  } catch (e) {
    res.redirect('/reseller?error=' + encodeURIComponent(e.message));
  }
});

module.exports = router;
