function requireAdmin(req, res, next) {
  if (req.session && req.session.role === 'admin') return next();
  return res.redirect('/login');
}

function requireReseller(req, res, next) {
  if (req.session && req.session.role === 'reseller') return next();
  return res.redirect('/login');
}

function requireAny(req, res, next) {
  if (req.session && (req.session.role === 'admin' || req.session.role === 'reseller')) return next();
  return res.redirect('/login');
}

module.exports = { requireAdmin, requireReseller, requireAny };
