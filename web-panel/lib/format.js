// NOVA XTUNNEL - dynamic data-size formatting (auto-scales Ko -> Mo -> Go -> To, etc.
// instead of always showing "Go", which made small/zero usage look wrong, e.g. "0.0 Go").

const UNITS = {
  fr: ['octets', 'Ko', 'Mo', 'Go', 'To', 'Po'],
  en: ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB']
};

// gb is a plain number of gigabytes (the unit stored everywhere in the DB). Returns a
// ready-to-display string like "512 Mo", "3.4 Go", "0 octets", or null if gb is not a
// usable number (so callers can keep handling "unlimited"/null separately).
function formatDataSize(gb, lang) {
  if (gb == null || !Number.isFinite(gb)) return null;
  const units = UNITS[lang] || UNITS.fr;

  const sign = gb < 0 ? '-' : '';
  let bytes = Math.abs(gb) * Math.pow(1024, 3);

  let idx = 0;
  while (bytes >= 1024 && idx < units.length - 1) {
    bytes /= 1024;
    idx += 1;
  }

  const rounded = idx === 0 ? Math.round(bytes) : parseFloat(bytes.toFixed(bytes < 10 ? 2 : 1));
  return `${sign}${rounded} ${units[idx]}`;
}

module.exports = { formatDataSize };
