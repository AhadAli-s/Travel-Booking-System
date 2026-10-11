const crypto = require('crypto');

/**
 * Protects machine-to-machine endpoints (the travel agency website pushing
 * bookings). The website sends the shared secret in the "x-api-key" header.
 */
function requireApiKey(req, res, next) {
    const expected = process.env.WEBSITE_API_KEY;
    const provided = req.headers['x-api-key'];
    if (!expected || typeof provided !== 'string') {
        return res.status(401).json({ error: 'Valid API key required' });
    }
    const a = crypto.createHash('sha256').update(provided).digest();
    const b = crypto.createHash('sha256').update(expected).digest();
    if (!crypto.timingSafeEqual(a, b)) {
        return res.status(401).json({ error: 'Valid API key required' });
    }
    next();
}

module.exports = { requireApiKey };