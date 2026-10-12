const { verifyToken } = require('../utils/jwt');
const { Staff } = require('../models/index');

/**
 * Verifies the JWT in the Authorization header (format: "Bearer <token>").
 * On success, attaches the decoded payload to req.user and calls next().
 * The payload includes { id, type: 'customer' | 'staff', role (staff only) }.
 *
 * For staff tokens the staff row is re-checked on every request, so a
 * deactivated account or a changed role takes effect immediately instead of
 * waiting for the token to expire. req.user.role always reflects the database.
 */
async function requireAuth(req, res, next) {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'No token provided' });
    }

    let decoded;
    try {
        decoded = verifyToken(authHeader.split(' ')[1]);
    } catch (err) {
        return res.status(401).json({ error: 'Invalid or expired token' });
    }

    try {
        if (decoded.type === 'staff') {
            const staff = await Staff.findByPk(decoded.id, { attributes: ['id', 'role', 'status'] });
            if (!staff || staff.status !== 'Active') {
                return res.status(401).json({ error: 'Staff account is inactive' });
            }
            decoded.role = staff.role;
        }
        req.user = decoded;
        next();
    } catch (err) {
        next(err);
    }
}

/** Only allows requests where req.user.type === 'customer' */
function requireCustomer(req, res, next) {
    if (!req.user || req.user.type !== 'customer') {
        return res.status(403).json({ error: 'Customer access required' });
    }
    next();
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

module.exports = { requireAuth, requireCustomer, requireStaff, requireRole };