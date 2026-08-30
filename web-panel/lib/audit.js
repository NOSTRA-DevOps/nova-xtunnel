const db = require('../db/database');

function log(actorType, actorName, action, message, resellerId = null) {
  try {
    db.prepare(`
      INSERT INTO audit_log (actor_type, actor_name, action, message, reseller_id)
      VALUES (?, ?, ?, ?, ?)
    `).run(actorType, actorName, action, message, resellerId);
  } catch (e) {
    console.error('Audit log error:', e.message);
  }
}

function recent(resellerId = null, limit = 50) {
  if (resellerId != null) {
    return db.prepare('SELECT * FROM audit_log WHERE reseller_id = ? ORDER BY id DESC LIMIT ?').all(resellerId, limit);
  }
  return db.prepare('SELECT * FROM audit_log ORDER BY id DESC LIMIT ?').all(limit);
}

// A reseller's own activity page/preview must show only what THEY did - not admin actions
// that happen to target their account (e.g. an admin locking/editing them). Filtering by
// actor_type keeps that boundary clean.
function recentByActor(resellerId, actorType, limit = 50) {
  return db.prepare(
    'SELECT * FROM audit_log WHERE reseller_id = ? AND actor_type = ? ORDER BY id DESC LIMIT ?'
  ).all(resellerId, actorType, limit);
}

module.exports = { log, recent, recentByActor };
