const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');
const config = require('../config');

const db = new Database(config.PANEL_DB_FILE);
db.pragma('journal_mode = WAL');

db.exec(`
CREATE TABLE IF NOT EXISTS admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS resellers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  data_quota_gb REAL,               -- NULL = unlimited
  max_users INTEGER NOT NULL DEFAULT 10,
  protocols TEXT NOT NULL DEFAULT '[]', -- JSON array of allowed protocol keys
  expiry_date TEXT,                 -- NULL = never expires
  status TEXT NOT NULL DEFAULT 'active', -- active | locked_manual | locked_expired
  consumed_quota_gb REAL NOT NULL DEFAULT 0, -- permanently-counted quota from deleted clients
  created_at TEXT DEFAULT (datetime('now')),
  notes TEXT
);

CREATE TABLE IF NOT EXISTS clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reseller_id INTEGER NOT NULL REFERENCES resellers(id) ON DELETE CASCADE,
  type TEXT NOT NULL,               -- 'ssh' | 'zivpn'
  identifier TEXT NOT NULL,         -- username for ssh, password for zivpn
  protocols TEXT NOT NULL DEFAULT '[]', -- JSON array subset of reseller.protocols (which tunnel types this client may use)
  max_connections INTEGER DEFAULT 1,
  quota_gb REAL,                    -- NULL = unlimited
  expiry_date TEXT,                 -- NULL = never
  status TEXT NOT NULL DEFAULT 'active', -- active | locked_manual | locked_expired | locked_reseller
  deleted INTEGER NOT NULL DEFAULT 0,
  created_at TEXT DEFAULT (datetime('now')),
  deleted_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_clients_reseller ON clients(reseller_id);
`);

// Migration: older databases were created before this column existed. SQLite has no
// "ADD COLUMN IF NOT EXISTS", so we just try and ignore the error when it's already there.
try {
  db.exec('ALTER TABLE clients ADD COLUMN usage_at_deletion_gb REAL');
} catch (e) {
  if (!/duplicate column/i.test(e.message)) throw e;
}

// quota_reset_offset_gb lets an admin "reset the reseller's displayed consumed total to 0"
// as a pure display action (like zeroing an odometer trip counter) WITHOUT touching any
// client's own live usage or the historical consumed_quota_gb banked from deleted/reset
// clients. See lib/quota.js getResellerStats() for how it's subtracted back out.
try {
  db.exec('ALTER TABLE resellers ADD COLUMN quota_reset_offset_gb REAL DEFAULT 0');
} catch (e) {
  if (!/duplicate column/i.test(e.message)) throw e;
}

db.exec(`

CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  actor_type TEXT NOT NULL,     -- 'admin' | 'reseller' | 'system'
  actor_name TEXT NOT NULL,
  action TEXT NOT NULL,         -- short machine-friendly code
  message TEXT NOT NULL,        -- human-readable description
  reseller_id INTEGER,          -- for scoping "my activity" views, NULL for admin-only actions
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_audit_reseller ON audit_log(reseller_id);
`);

// Bootstrap a default admin account on first run only.
const adminCount = db.prepare('SELECT COUNT(*) AS c FROM admins').get().c;
if (adminCount === 0) {
  const defaultUser = process.env.DEFAULT_ADMIN_USER || 'admin';
  const defaultPass = process.env.DEFAULT_ADMIN_PASS || 'ChangeMe123!';
  const hash = bcrypt.hashSync(defaultPass, 10);
  db.prepare('INSERT INTO admins (username, password_hash) VALUES (?, ?)').run(defaultUser, hash);
  console.log('======================================================');
  console.log(' NOVA XTUNNEL - default admin account created:');
  console.log('   username:', defaultUser);
  console.log('   password:', defaultPass);
  console.log(' CHANGE THIS PASSWORD IMMEDIATELY AFTER FIRST LOGIN.');
  console.log('======================================================');
}

module.exports = db;
