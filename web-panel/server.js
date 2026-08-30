require('dotenv').config();
const express = require('express');
const session = require('express-session');
const SqliteSessionStore = require('./lib/sessionStore');
const helmet = require('helmet');
const path = require('path');
const fs = require('fs');
const https = require('https');
const cron = require('node-cron');

const config = require('./config');
require('./db/database'); // bootstraps schema + default admin

const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const resellerRoutes = require('./routes/reseller');
const { runEnforcement } = require('./cron/enforcement');
const i18n = require('./lib/i18n');
const format = require('./lib/format');

const app = express();

// The panel usually runs behind Nginx (TLS termination + reverse proxy). Trusting the
// proxy lets Express read the real client IP (X-Forwarded-For) for rate limiting/logging,
// and lets it know the original connection was HTTPS so "Secure" cookies work correctly.
// In TLS_MODE=node, the Node process terminates TLS itself, so there is no proxy to trust,
// but the connection is still genuinely HTTPS - cookies must still be marked Secure.
const servesHttpsDirectly = config.TLS_MODE === 'node';
if (config.BEHIND_TLS_PROXY) app.set('trust proxy', 1);
const useSecureCookies = config.BEHIND_TLS_PROXY || servesHttpsDirectly;

app.use(helmet({
  contentSecurityPolicy: false, // panel views use inline styles/scripts; CSP kept simple on purpose
}));

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use(session({
  name: 'novaxpanel.sid',
  store: new SqliteSessionStore({ dbPath: path.join(__dirname, 'db', 'sessions.sqlite3') }),
  secret: config.SESSION_SECRET,
  resave: false,
  saveUninitialized: false,
  cookie: {
    maxAge: 1000 * 60 * 60 * 12, // 12h
    httpOnly: true,
    sameSite: 'lax',
    secure: useSecureCookies
  }
}));

// Make role/username available to every EJS view without repeating it in every render() call.
app.use((req, res, next) => {
  res.locals.role = req.session ? req.session.role : null;
  res.locals.username = req.session ? req.session.username : null;
  res.locals.version = config.VERSION;
  const lang = (req.session && req.session.lang === 'en') ? 'en' : 'fr';
  res.locals.lang = lang;
  res.locals.t = (key) => i18n.t(key, lang);
  // Dynamic-unit data size formatter (Ko/Mo/Go/... instead of always "Go") for use in views.
  res.locals.fmtData = (gb) => format.formatDataSize(gb, lang);
  next();
});

// Language switcher — works pre-login too (stored in the session, defaults to French).
app.get('/lang/:code', (req, res) => {
  const code = req.params.code === 'en' ? 'en' : 'fr';
  if (req.session) req.session.lang = code;
  const back = req.get('Referer') || '/';
  res.redirect(back);
});

app.get('/', (req, res) => {
  if (req.session.role === 'admin') return res.redirect('/admin');
  if (req.session.role === 'reseller') return res.redirect('/reseller');
  res.redirect('/login');
});

// Public - no login required, just project/company info.
app.get('/about', (req, res) => res.render('about'));

app.use(authRoutes);
app.use('/admin', adminRoutes);
app.use('/reseller', resellerRoutes);

app.use((req, res) => res.status(404).send('Page introuvable.'));

// Run enforcement once at boot, then every 2 minutes.
try { runEnforcement(); } catch (e) { console.error('Enforcement error (boot):', e.message); }
cron.schedule('*/2 * * * *', () => {
  try { runEnforcement(); } catch (e) { console.error('Enforcement error:', e.message); }
});

if (servesHttpsDirectly) {
  if (!config.CERT_PATH || !config.KEY_PATH || !fs.existsSync(config.CERT_PATH) || !fs.existsSync(config.KEY_PATH)) {
    console.error('TLS_MODE=node mais CERT_PATH/KEY_PATH sont manquants ou introuvables.');
    console.error('  CERT_PATH:', config.CERT_PATH || '(vide)');
    console.error('  KEY_PATH :', config.KEY_PATH || '(vide)');
    process.exit(1);
  }
  const httpsOptions = {
    cert: fs.readFileSync(config.CERT_PATH),
    key: fs.readFileSync(config.KEY_PATH)
  };
  https.createServer(httpsOptions, app).listen(config.PORT, () => {
    console.log(`NOVA X Tunnel panel listening directly on https://0.0.0.0:${config.PORT} (TLS_MODE=node, no Nginx)`);
  });
} else {
  
  app.listen(config.PORT, '127.0.0.1', () => {
    console.log(`NOVA X Tunnel panel listening on http://127.0.0.1:${config.PORT} (local only, behind Nginx)`);
  });
}

process.on('unhandledRejection', (reason) => {
  console.error('Unhandled promise rejection (panel kept running):', reason);
});
