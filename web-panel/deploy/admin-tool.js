#!/usr/bin/env node
// NOVA XTUNNEL - admin account maintenance helper.
// Used by the `novaxpanel` bash CLI so that admin username/password changes go through
// the exact same bcrypt hashing as the web app (bcryptjs), instead of juggling SQL by hand.
//
// Usage:
//   node admin-tool.js list
//   node admin-tool.js set-username <old_username> <new_username>
//   node admin-tool.js set-password <username> <new_password>
//   node admin-tool.js create <username> <password>   (only if no admin exists yet)

const path = require('path');
const Database = require('better-sqlite3');
const bcrypt = require('bcryptjs');

const config = require(path.join(__dirname, '..', 'config'));
const db = new Database(config.PANEL_DB_FILE);

const [, , cmd, a, b] = process.argv;

function fail(msg) {
  console.error('ERREUR: ' + msg);
  process.exit(1);
}

switch (cmd) {
  case 'list': {
    const admins = db.prepare('SELECT id, username, created_at FROM admins').all();
    if (admins.length === 0) console.log('Aucun compte admin.');
    admins.forEach((a) => console.log(`#${a.id}  ${a.username}  (créé le ${a.created_at})`));
    break;
  }

  case 'set-username': {
    if (!a || !b) fail('usage: set-username <ancien_username> <nouveau_username>');
    const existing = db.prepare('SELECT * FROM admins WHERE username = ?').get(a);
    if (!existing) fail(`Aucun admin trouvé avec le nom "${a}".`);
    const clash = db.prepare('SELECT * FROM admins WHERE username = ?').get(b);
    if (clash) fail(`Le nom d'utilisateur "${b}" est déjà utilisé.`);
    db.prepare('UPDATE admins SET username = ? WHERE id = ?').run(b, existing.id);
    console.log(`OK: "${a}" renommé en "${b}".`);
    break;
  }

  case 'set-password': {
    if (!a || !b) fail('usage: set-password <username> <nouveau_mot_de_passe>');
    if (b.length < 6) fail('Le mot de passe doit contenir au moins 6 caractères.');
    const existing = db.prepare('SELECT * FROM admins WHERE username = ?').get(a);
    if (!existing) fail(`Aucun admin trouvé avec le nom "${a}".`);
    const hash = bcrypt.hashSync(b, 10);
    db.prepare('UPDATE admins SET password_hash = ? WHERE id = ?').run(hash, existing.id);
    console.log(`OK: mot de passe mis à jour pour "${a}".`);
    break;
  }

  case 'create': {
    if (!a || !b) fail('usage: create <username> <password>');
    const count = db.prepare('SELECT COUNT(*) AS c FROM admins').get().c;
    if (count > 0) fail('Un compte admin existe déjà — utilisez set-username / set-password.');
    const hash = bcrypt.hashSync(b, 10);
    db.prepare('INSERT INTO admins (username, password_hash) VALUES (?, ?)').run(a, hash);
    console.log(`OK: admin "${a}" créé.`);
    break;
  }

  default:
    console.log('Commandes: list | set-username <old> <new> | set-password <user> <pass> | create <user> <pass>');
    process.exit(cmd ? 1 : 0);
}
