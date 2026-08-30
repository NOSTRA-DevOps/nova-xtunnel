const fs = require('fs');
const { execFileSync } = require('child_process');
const config = require('../config');

// Accepts upper AND lower case letters (Linux itself is case-sensitive on usernames;
// only login.defs/useradd's default POSIX check rejected uppercase, which is worked
// around below with --badname).
const USERNAME_RE = /^[a-zA-Z][a-zA-Z0-9_-]{2,31}$/;

function validateUsername(username) {
  if (!USERNAME_RE.test(username)) {
    throw new Error('Nom d\'utilisateur invalide (lettres, chiffres, -, _ ; 3-32 caractères, doit commencer par une lettre).');
  }
}

function randomPassword(len = 10) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
  let out = '';
  for (let i = 0; i < len; i++) out += chars[Math.floor(Math.random() * chars.length)];
  return out;
}

function ensureDirs() {
  fs.mkdirSync(config.DB_DIR, { recursive: true });
  fs.mkdirSync(config.BANDWIDTH_DIR, { recursive: true });
  if (!fs.existsSync(config.SSH_USERS_DB)) fs.writeFileSync(config.SSH_USERS_DB, '');
}

function ensureGroup() {
  try {
    execFileSync('getent', ['group', config.FF_USERS_GROUP]);
  } catch {
    try { execFileSync('groupadd', [config.FF_USERS_GROUP]); } catch { /* ignore races */ }
  }
}

// ---- users.db (colon-separated: username:password:expire_date:conn_limit:bandwidth_gb) ----

function readUsersDb() {
  ensureDirs();
  const raw = fs.readFileSync(config.SSH_USERS_DB, 'utf8');
  return raw.split('\n').filter(Boolean).map((line) => {
    const [username, password, expireDate, connLimit, bandwidthGb] = line.split(':');
    return { username, password, expireDate, connLimit, bandwidthGb };
  });
}

function writeUsersDbLine(entry) {
  ensureDirs();
  const lines = readUsersDb().filter((e) => e.username !== entry.username);
  lines.push(entry);
  const content = lines
    .map((e) => `${e.username}:${e.password}:${e.expireDate}:${e.connLimit}:${e.bandwidthGb}`)
    .join('\n') + (lines.length ? '\n' : '');
  fs.writeFileSync(config.SSH_USERS_DB, content);
}

function removeUsersDbLine(username) {
  const lines = readUsersDb().filter((e) => e.username !== username);
  const content = lines
    .map((e) => `${e.username}:${e.password}:${e.expireDate}:${e.connLimit}:${e.bandwidthGb}`)
    .join('\n') + (lines.length ? '\n' : '');
  fs.writeFileSync(config.SSH_USERS_DB, content);
}

function sshUserExistsOnSystem(username) {
  try {
    execFileSync('id', [username], { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

function createSshUser({ username, password, expiryDate, maxConnections, quotaGb }) {
  validateUsername(username);
  if (sshUserExistsOnSystem(username)) {
    throw new Error(`L'utilisateur système '${username}' existe déjà.`);
  }
  ensureDirs();
  ensureGroup();

  // Defense in depth: the create-client form has SSH and ZiVPN password inputs sharing the
  // same "password" field name (so either type posts to the same server field), hidden via
  // CSS when not selected. If client-side JS ever fails to disable the hidden one before
  // submit, Express receives password as an ARRAY (e.g. ['Merli2341', '']), and naively
  // stringifying that joins it with a comma - silently appending "," to the real password.
  // Always take the first non-empty value instead of trusting a plain string coercion.
  const rawPassword = Array.isArray(password) ? (password.find((v) => v != null && String(v).trim() !== '') ?? '') : password;

  // If the reseller typed a password, we must use it (or reject it with a clear error) -
  // never silently swap it out for a random one, or they'll think their chosen password
  // was applied when it wasn't. Only an actually-empty field triggers auto-generation.
  const trimmedPassword = rawPassword == null ? '' : String(rawPassword).trim();
  let finalPassword;
  if (trimmedPassword !== '') {
    if (trimmedPassword.length < 4) {
      throw new Error('Mot de passe trop court (minimum 4 caractères).');
    }
    finalPassword = trimmedPassword;
  } else {
    finalPassword = randomPassword();
  }
  const expire = expiryDate || null;

  // --badname bypasses useradd's default POSIX username check, which otherwise rejects
  // uppercase letters even though Linux itself has no problem with them.
  execFileSync('useradd', ['-m', '-s', '/usr/sbin/nologin', '--badname', username]);
  execFileSync('usermod', ['-aG', config.FF_USERS_GROUP, username]);
  execFileSync('chpasswd', { input: `${username}:${finalPassword}\n` });
  if (expire) {
    execFileSync('chage', ['-E', expire, username]);
  }

  writeUsersDbLine({
    username,
    password: finalPassword,
    expireDate: expire || '',
    connLimit: maxConnections || 1,
    bandwidthGb: quotaGb == null ? 0 : quotaGb // 0 = unlimited, matches menu.sh convention
  });

  return { username, password: finalPassword, expiryDate: expire, maxConnections, quotaGb };
}

function deleteSshUser(username) {
  validateUsername(username);
  if (sshUserExistsOnSystem(username)) {
    try { execFileSync('killall', ['-u', username, '-9']); } catch { /* no active sessions */ }
    execFileSync('userdel', ['-r', username]);
  }
  removeUsersDbLine(username);
  const usageFile = `${config.BANDWIDTH_DIR}/${username}.usage`;
  if (fs.existsSync(usageFile)) fs.unlinkSync(usageFile);
}

function lockSshUser(username) {
  validateUsername(username);
  if (!sshUserExistsOnSystem(username)) return;
  execFileSync('usermod', ['-L', username]);
  try { execFileSync('killall', ['-u', username, '-9']); } catch { /* no active sessions */ }
}

function unlockSshUser(username) {
  validateUsername(username);
  if (!sshUserExistsOnSystem(username)) return;
  execFileSync('usermod', ['-U', username]);
}

function renewSshUser(username, newExpiryDate, newMaxConnections, newQuotaGb) {
  validateUsername(username);
  if (sshUserExistsOnSystem(username)) {
    // A falsy newExpiryDate here always means "clear the expiry / never expires" - it is
    // NEVER used to mean "leave unchanged" (the only caller, editClient, always passes an
    // explicit value, since the edit form always submits the expiry field). `chage -E -1`
    // is the standard way to remove an account expiration date entirely.
    execFileSync('chage', ['-E', newExpiryDate || '-1', username]);
  }
  const entries = readUsersDb();
  const existing = entries.find((e) => e.username === username);
  if (existing) {
    writeUsersDbLine({
      username,
      password: existing.password,
      // Previously fell back to existing.expireDate when clearing, leaving a stale date in
      // users.db (and therefore in the terminal panel's "Expired" detection) even though
      // both the OS and this panel's own database had already been told "never expires".
      expireDate: newExpiryDate || '',
      connLimit: newMaxConnections != null ? newMaxConnections : existing.connLimit,
      bandwidthGb: newQuotaGb != null ? newQuotaGb : existing.bandwidthGb
    });
  }
}

function getSshPassword(username) {
  const existing = readUsersDb().find((e) => e.username === username);
  return existing ? existing.password : null;
}

function changeSshPassword(username, newPassword) {
  validateUsername(username);
  const trimmed = newPassword == null ? '' : String(newPassword).trim();
  let finalPassword;
  if (trimmed !== '') {
    if (trimmed.length < 4) throw new Error('Mot de passe trop court (minimum 4 caractères).');
    finalPassword = trimmed;
  } else {
    finalPassword = randomPassword();
  }
  if (sshUserExistsOnSystem(username)) {
    execFileSync('chpasswd', { input: `${username}:${finalPassword}\n` });
  }
  const existing = readUsersDb().find((e) => e.username === username);
  if (existing) {
    writeUsersDbLine({ ...existing, password: finalPassword });
  }
  return finalPassword;
}

// Resolves every live sshd SESSION process (one per actual login) to the managed username
// it belongs to. Returns a Map<pid, username> with EXACTLY ONE entry per real login.
//
// NOTE 1: this deliberately does NOT look at `ss`/established TCP connections at all. This
// tunnel setup uses SSH's own dynamic port forwarding (the client's device browses the
// internet "through" the SSH session), which means a single logged-in session's sshd
// process opens MANY outbound TCP connections - one per website/app the tunneled device
// happens to be using right now (Google, a CDN, WhatsApp, ads, ...). Those destination
// IPs used to get miscounted as if they were distinct connecting clients, which is why
// one real session could show as "9 online", "15 online", etc., changing every refresh
// as the phone's own traffic changed.
//
// NOTE 2: OpenSSH privilege separation means EVERY login is actually TWO processes: a
// root-owned "[priv]" monitor, and the child it forks after auth that drops privileges to
// run as the real user (this is what shows up owned by the user in `ps`). Counting BOTH
// (the child directly, the monitor via its /proc/<pid>/loginuid) counts one real login as
// two sessions - which is exactly what made a 1-person account show "2/2" and then get
// hit by the connection-limit lock the moment that one person's app opened one more real
// connection. So: count the user-owned child when it exists, and explicitly SKIP its
// parent monitor (identified by PPID) so it's never counted a second time via loginuid.
function mapSshdPidsToUsers(managedUsers) {
  const pidToUser = new Map();

  let psOut;
  try {
    psOut = execFileSync('ps', ['-C', 'sshd', '-o', 'pid=,ppid=,user=']).toString();
  } catch {
    return pidToUser; // no sshd processes running (or 'ps' unavailable)
  }

  const rows = [];
  psOut.split('\n').forEach((line) => {
    const trimmed = line.trim();
    if (!trimmed) return;
    const parts = trimmed.split(/\s+/);
    if (parts.length < 3) return;
    const [pid, ppid, owner] = parts;
    if (!/^\d+$/.test(pid)) return;
    rows.push({ pid, ppid, owner });
  });

  // Pass 1: processes directly owned by a managed user - the privilege-dropped session
  // child. This is the normal, reliable case and needs no /proc lookups at all.
  const monitorPidsAlreadyCounted = new Set(); // PPIDs whose child we just counted above
  rows.forEach(({ pid, ppid, owner }) => {
    if (owner && owner !== 'root' && owner !== 'sshd' && managedUsers.has(owner)) {
      pidToUser.set(pid, owner);
      monitorPidsAlreadyCounted.add(ppid);
    }
  });

  // Pass 2: remaining root/sshd-owned processes - resolve via loginuid (covers the rare
  // case where privsep didn't produce a directly-owned child at all), but SKIP any pid
  // that is the privsep monitor of a session already counted in pass 1 - that's the same
  // login, not a second one.
  let uidToUser = null; // built lazily, only if actually needed
  rows.forEach(({ pid, owner }) => {
    if (pidToUser.has(pid)) return;
    if (monitorPidsAlreadyCounted.has(pid)) return;
    try {
      const loginuid = fs.readFileSync(`/proc/${pid}/loginuid`, 'utf8').trim();
      if (loginuid && loginuid !== '4294967295') {
        if (!uidToUser) {
          uidToUser = new Map();
          fs.readFileSync('/etc/passwd', 'utf8').split('\n').forEach((pline) => {
            const p = pline.split(':');
            if (p[0] && /^\d+$/.test(p[2])) uidToUser.set(p[2], p[0]);
          });
        }
        const u = uidToUser.get(loginuid);
        if (u && managedUsers.has(u)) pidToUser.set(pid, u);
      }
    } catch { /* process already gone, or /proc unavailable (non-Linux) */ }
  });

  return pidToUser;
}

// Counts online SESSIONS per managed SSH username by counting distinct sshd session
// processes (see mapSshdPidsToUsers above for why this - not peer IPs, not raw TCP
// connection count - is the right unit: one login = one sshd process here, regardless
// of how many destinations that session's traffic is being forwarded to).
function getOnlineSshCounts() {
  const counts = new Map();

  let managedUsers;
  try {
    managedUsers = new Set(readUsersDb().map((e) => e.username));
  } catch {
    managedUsers = new Set();
  }
  if (managedUsers.size === 0) return counts;

  const pidToUser = mapSshdPidsToUsers(managedUsers);
  pidToUser.forEach((user) => counts.set(user, (counts.get(user) || 0) + 1));
  return counts;
}

function readSshUsageBytes(username) {
  const usageFile = `${config.BANDWIDTH_DIR}/${username}.usage`;
  if (!fs.existsSync(usageFile)) return 0;
  const raw = fs.readFileSync(usageFile, 'utf8').trim();
  const n = parseInt(raw, 10);
  return Number.isFinite(n) ? n : 0;
}

// Zeroes out a client's usage counter (used by the reseller/admin "reset" action). The
// caller is responsible for banking the pre-reset amount into the reseller's permanent
// consumed total first, exactly like a deletion does - otherwise a reseller could dodge
// their overall quota just by resetting a client repeatedly.
function resetSshUsage(username) {
  validateUsername(username);
  ensureDirs();
  const usageFile = `${config.BANDWIDTH_DIR}/${username}.usage`;
  fs.writeFileSync(usageFile, '0');
}

module.exports = {
  validateUsername,
  randomPassword,
  sshUserExistsOnSystem,
  createSshUser,
  deleteSshUser,
  lockSshUser,
  unlockSshUser,
  renewSshUser,
  getSshPassword,
  changeSshPassword,
  getOnlineSshCounts,
  readSshUsageBytes,
  resetSshUsage
};
