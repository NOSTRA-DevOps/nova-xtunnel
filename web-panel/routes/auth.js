const express = require('express');
const bcrypt = require('bcryptjs');
const rateLimit = require('express-rate-limit');
const db = require('../db/database');
const i18n = require('../lib/i18n');

const router = express.Router();

function tr(req, key) {
  const lang = (req.session && req.session.lang === 'en') ? 'en' : 'fr';
  return i18n.t(key, lang);
}

// Slows down brute-force attempts: 10 tries per IP per 15 minutes on the login form.
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: (req, res) => res.status(429).render('login', {
    error: tr(req, 'login.error.rate_limited')
  })
});

router.get('/login', (req, res) => {
  if (req.session && req.session.role === 'admin') return res.redirect('/admin');
  if (req.session && req.session.role === 'reseller') return res.redirect('/reseller');
  res.render('login', { error: null });
});

router.post('/login', loginLimiter, (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.render('login', { error: tr(req, 'login.error.fields') });
  }

  function finishLogin(sessionData) {
    // Regenerate the session id on privilege change to prevent session fixation attacks.
    const lang = req.session.lang;
    req.session.regenerate((err) => {
      if (err) return res.render('login', { error: tr(req, 'login.error.server') });
      Object.assign(req.session, sessionData, { lang });
      req.session.save(() => res.redirect(sessionData.role === 'admin' ? '/admin' : '/reseller'));
    });
  }

  const admin = db.prepare('SELECT * FROM admins WHERE username = ?').get(username);
  if (admin && bcrypt.compareSync(password, admin.password_hash)) {
    return finishLogin({ role: 'admin', userId: admin.id, username: admin.username });
  }

  const reseller = db.prepare('SELECT * FROM resellers WHERE username = ?').get(username);
  if (reseller && bcrypt.compareSync(password, reseller.password_hash)) {
    if (reseller.status !== 'active') {
      return res.render('login', { error: tr(req, 'login.error.locked') });
    }
    return finishLogin({ role: 'reseller', userId: reseller.id, username: reseller.username });
  }

  return res.render('login', { error: tr(req, 'login.error.bad_creds') });
});

router.post('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/login'));
});

module.exports = router;
