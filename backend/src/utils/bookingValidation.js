/** Accepts "YYYY-MM-DD" (or an ISO string starting with it). Returns the date string or null. */
function parseDate(value) {
    const s = typeof value === 'string' ? value.slice(0, 10) : '';
    if (!/^\d{4}-\d{2}-\d{2}$/.test(s)) return null;
    const d = new Date(`${s}T00:00:00Z`);
    if (Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== s) return null;
    return s;
}

function nightsBetween(travelDate, returnDate) {
    return Math.round((new Date(returnDate) - new Date(travelDate)) / (1000 * 60 * 60 * 24));
}

/** Integer 0..20. Returns fallback when value is missing, null when invalid. */
function toCount(value, fallback) {
    if (value === undefined || value === null || value === '') return fallback;
    const n = Number(value);
    return Number.isInteger(n) && n >= 0 && n <= 20 ? n : null;
}

function toPrice(value) {
    const n = Number(value);
    return Number.isFinite(n) && n > 0 && n < 10000000 ? Math.round(n * 100) / 100 : null;
}

function cleanText(value, max = 255) {
    if (value === undefined || value === null) return null;
    const s = String(value).trim();
    return s ? s.slice(0, max) : null;
}

module.exports = { parseDate, nightsBetween, toCount, toPrice, cleanText };