const { verifyToken } = require('../utils/jwt');

/**
 * Verifies the JWT in the Authorization header (format: "Bearer <token>").
 * On success, attaches the decoded payload to req.user and calls next().
 * The payload includes { id, type: 'customer' | 'staff', role (staff only) }.
 */
function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'No token provided' });
    }

    const token = authHeader.split(' ')[1];
    try {
        const decoded = verifyToken(token);
        req.user = decoded;
        next();
    } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired token' });
    }
}

/** Only allows requests where req.user.type === 'staff' */
function requireStaff(req, res, next) {
    if (!req.user || req.user.type !== 'staff') {
        return res.status(403).json({ error: 'Staff access required' });
    }
    next();
}

/** Only allows staff whose role is in the given list, e.g. requireRole('Administrator') */
function requireRole(...allowedRoles) {
    return (req, res, next) => {
        if (!req.user || req.user.type !== 'staff' || !allowedRoles.includes(req.user.role)) {
            return res.status(403).json({ error: 'Insufficient permissions' });
        }
        next();
    };
}

module.exports = { requireAuth, requireStaff, requireRole };