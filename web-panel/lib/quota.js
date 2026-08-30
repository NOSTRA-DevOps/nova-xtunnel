const db = require('../db/database');
const format = require('./format');

function getActiveClients(resellerId) {
  return db.prepare('SELECT * FROM clients WHERE reseller_id = ? AND deleted = 0').all(resellerId);
}

function getAllocatedQuotaSum(resellerId) {
  // Sum of quota_gb for active clients that have a finite quota (NULL/unlimited clients don't add a number here,
  // they are blocked separately - a reseller with a finite total quota cannot hand out an "unlimited" client).
  const row = db.prepare(
    `SELECT COALESCE(SUM(quota_gb), 0) AS total FROM clients WHERE reseller_id = ? AND deleted = 0 AND quota_gb IS NOT NULL`
  ).get(resellerId);
  return row.total;
}

// Sum of max_connections across all non-deleted SSH clients - i.e. the total simultaneous
// connection capacity the reseller has already handed out. Locked/expired clients still
// count (same convention as getAllocatedQuotaSum): they could be unlocked at any time and
// their reserved slots must not be silently double-booked to another client in the meantime.
function getAllocatedConnectionsSum(resellerId, excludeClientId) {
  const row = db.prepare(
    `SELECT COALESCE(SUM(max_connections), 0) AS total FROM clients
     WHERE reseller_id = ? AND deleted = 0 AND type = 'ssh' AND id != ?`
  ).get(resellerId, excludeClientId || -1);
  return row.total;
}

function getResellerStats(reseller) {
  const active = getActiveClients(reseller.id);
  const allocated = getAllocatedQuotaSum(reseller.id);
  const totalCommitted = allocated + (reseller.consumed_quota_gb || 0);
  const allocatedConnections = getAllocatedConnectionsSum(reseller.id);

  const clientsLib = require('./clients');
  const system = require('./system');
  const onlineCounts = system.getOnlineSshCounts();

  let consumedActiveGb = 0;
  let onlineTotal = 0;
  let lockedCount = 0;
  let expiredCount = 0;
  const clientsWithLive = active.map((c) => {
    const usageGb = clientsLib.clientUsageGb(c);
    if (usageGb != null) consumedActiveGb += usageGb;
    const online = c.type === 'ssh' ? (onlineCounts.get(c.identifier) || 0) : null;
    if (online) onlineTotal += Math.min(online, c.max_connections || online);
    if (c.status !== 'active') lockedCount += 1;
    if (c.status === 'locked_expired') expiredCount += 1;
    return { ...c, _online: online, usageGb: usageGb };
  });

  return {
    activeClientCount: active.length,
    onlineClientCount: onlineTotal,
    lockedClientCount: lockedCount,
    expiredClientCount: expiredCount,
    allocatedQuotaGb: allocated,
    consumedByDeletedGb: reseller.consumed_quota_gb || 0,
    // "Display reset" only ever moves quota_reset_offset_gb - it never touches consumed_quota_gb
    // (the historical banked total from deleted/reset clients) or any client's own live usage.
    // Subtracting it here is what makes an admin reset show 0 immediately while clients keep
    // their own counters untouched, with future consumption growing the total again from 0.
    consumedTotalGb: Math.max(0, consumedActiveGb + (reseller.consumed_quota_gb || 0) - (reseller.quota_reset_offset_gb || 0)),
    // Deliberately NOT offset-adjusted: this is the admission-control ceiling used to decide
    // whether a reseller can still be handed a new client quota, and must stay tied to real
    // commitments (allocated quotas + banked usage) - a display reset must never free up
    // room to over-allocate beyond the reseller's actual data_quota_gb.
    totalCommittedGb: totalCommitted,
    allocatedConnections: allocatedConnections,
    clients: clientsWithLive
  };
}

// Throws with a human-readable French message if the reseller cannot create/grant this
// many SSH connection slots. `max_users` is the reseller's total allowed simultaneous
// online-connections ceiling (the SUM of every SSH client's own "max simultaneous
// connections" must stay within it) - not just a count of client accounts.
// `excludeClientId` lets an edit re-check the sum without counting the client's own
// pre-edit row twice.
function assertConnectionsWithinLimit(reseller, maxConnections, excludeClientId) {
  const already = getAllocatedConnectionsSum(reseller.id, excludeClientId);
  const projected = already + (maxConnections || 0);
  if (projected > reseller.max_users) {
    const remaining = Math.max(0, reseller.max_users - already);
    throw new Error(
      `Limite de connexions simultanées atteinte : la somme des limites de connexion de vos comptes SSH ne peut pas dépasser ${reseller.max_users}. Il vous reste ${remaining} connexion(s) disponible(s) à répartir.`
    );
  }
}

// Throws with a human-readable French message if the reseller cannot create this client.
function assertCanCreateClient(reseller, { quotaGb, protocols, maxConnections, type }) {
  if (reseller.status !== 'active') {
    throw new Error('Votre compte reseller est verrouillé, vous ne pouvez pas créer de nouveaux comptes.');
  }

  const stats = getResellerStats(reseller);
  if (stats.activeClientCount >= reseller.max_users) {
    throw new Error(`Limite atteinte : votre compte permet au maximum ${reseller.max_users} utilisateur(s) actif(s).`);
  }

  const allowedProtocols = JSON.parse(reseller.protocols || '[]');
  for (const p of protocols || []) {
    if (!allowedProtocols.includes(p)) {
      throw new Error(`Protocole non autorisé pour votre compte : ${p}`);
    }
  }

  if (type === 'ssh') {
    assertConnectionsWithinLimit(reseller, maxConnections);
  }

  if (reseller.data_quota_gb == null) {
    return; // reseller has unlimited quota, no further check needed
  }

  if (quotaGb == null) {
    throw new Error('Votre compte a un quota de data limité : vous devez fixer un quota précis pour ce client (pas "illimité").');
  }

  const projected = stats.totalCommittedGb + quotaGb;
  if (projected > reseller.data_quota_gb) {
    const remaining = Math.max(0, reseller.data_quota_gb - stats.totalCommittedGb);
    throw new Error(`Quota insuffisant : il ne vous reste que ${format.formatDataSize(remaining, 'fr')} disponibles sur votre quota total.`);
  }
}

module.exports = { getActiveClients, getAllocatedQuotaSum, getAllocatedConnectionsSum, getResellerStats, assertCanCreateClient, assertConnectionsWithinLimit };
