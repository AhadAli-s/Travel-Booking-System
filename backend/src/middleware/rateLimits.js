const rateLimit = require('express-rate-limit');

const json429 = (message) => ({ error: message });

/** Login, register, forgot and reset password: slows down password guessing. */
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 100,
    standardHeaders: true,
    legacyHeaders: false,
    message: json429('Too many attempts. Please try again in 15 minutes.'),
});

/** Public booking lookup (reference + email): slows down reference guessing. */
const lookupLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: 20,
    standardHeaders: true,
    legacyHeaders: false,
    message: json429('Too many lookups. Please try again in 15 minutes.'),
});

module.exports = { authLimiter, lookupLimiter };