const session = require('express-session');
const Database = require('better-sqlite3');

// A minimal, dependency-free session store using the SAME better-sqlite3 driver already
// used everywhere else in this app. connect-sqlite3 was tried first but pulls in the
// separate native "sqlite3" package, whose prebuilt bindings failed to load in some
// environments (crash at boot) - one more native dependency is one more way for the
// panel to fail to start on a given VPS/Node combination. This store has none of that risk.
class SqliteSessionStore extends session.Store {
  constructor({ dbPath }) {
    super();
    this.db = new Database(dbPath);
    this.db.pragma('journal_mode = WAL');
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS sessions (
        sid TEXT PRIMARY KEY,
        expires INTEGER NOT NULL,
        data TEXT NOT NULL
      )
    `);
    // Best-effort periodic cleanup of expired rows so the table never grows unbounded.
    this._gc();
    this._gcInterval = setInterval(() => this._gc(), 15 * 60 * 1000);
    this._gcInterval.unref();
  }

  _gc() {
    try { this.db.prepare('DELETE FROM sessions WHERE expires < ?').run(Date.now()); } catch { /* ignore */ }
  }

  get(sid, cb) {
    try {
      const row = this.db.prepare('SELECT data, expires FROM sessions WHERE sid = ?').get(sid);
      if (!row || row.expires < Date.now()) return cb(null, null);
      cb(null, JSON.parse(row.data));
    } catch (e) { cb(e); }
  }

  set(sid, sess, cb) {
    try {
      const maxAge = sess.cookie && sess.cookie.maxAge ? sess.cookie.maxAge : 12 * 60 * 60 * 1000;
      const expires = Date.now() + maxAge;
      this.db.prepare(
        'INSERT INTO sessions (sid, expires, data) VALUES (?, ?, ?) ON CONFLICT(sid) DO UPDATE SET expires = excluded.expires, data = excluded.data'
      ).run(sid, expires, JSON.stringify(sess));
      cb && cb(null);
    } catch (e) { cb && cb(e); }
  }

  destroy(sid, cb) {
    try {
      this.db.prepare('DELETE FROM sessions WHERE sid = ?').run(sid);
      cb && cb(null);
    } catch (e) { cb && cb(e); }
  }

  touch(sid, sess, cb) {
    this.set(sid, sess, cb);
  }
}

module.exports = SqliteSessionStore;
