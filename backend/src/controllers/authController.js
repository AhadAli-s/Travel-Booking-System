const bcrypt = require('bcrypt');
const crypto = require('crypto');
const { Customer, Staff } = require('../models/index');
const { generateToken } = require('../utils/jwt');
const {
    normalizeEmail,
    validateRegistrationBody,
    validateLoginBody,
    validateResetPasswordBody,
} = require('../utils/authValidation');

const SALT_ROUNDS = 10;

function handleAuthError(res, err) {
    if (err.name === 'SequelizeValidationError' || err.name === 'SequelizeUniqueConstraintError') {
        const message = err.errors?.map((e) => e.message).join(', ') || err.message;
        return res.status(400).json({ error: message });
    }
    return res.status(500).json({ error: err.message });
}

async function register(req, res) {
    try {
        const validated = validateRegistrationBody(req.body);
        if (validated.error) {
            return res.status(400).json({ error: validated.error });
        }

        const { fullName, email, password, phone } = validated;

        const existing = await Customer.findOne({ where: { email } });
        if (existing) {
            return res.status(409).json({ error: 'An account with this email already exists' });
        }

        const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
        const customer = await Customer.create({ fullName, email, passwordHash, phone });

        const token = generateToken({ id: customer.id, type: 'customer' });

        res.status(201).json({
            token,
            customer: { id: customer.id, fullName: customer.fullName, email: customer.email },
        });
    } catch (err) {
        handleAuthError(res, err);
    }
}

async function login(req, res) {
    try {
        const validated = validateLoginBody(req.body);
        if (validated.error) {
            return res.status(400).json({ error: validated.error });
        }

        const { email, password } = validated;

        const customer = await Customer.findOne({ where: { email } });
        if (!customer) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const match = await bcrypt.compare(password, customer.passwordHash);
        if (!match) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const token = generateToken({ id: customer.id, type: 'customer' });

        res.json({
            token,
            customer: { id: customer.id, fullName: customer.fullName, email: customer.email },
        });
    } catch (err) {
        handleAuthError(res, err);
    }
}

/**
 * Logout is handled client-side for a JWT-based API (the client simply
 * discards the token). This endpoint exists so the client has a clear,
 * explicit action to call — useful for future server-side token
 * blacklisting if that's ever added.
 */
async function logout(req, res) {
    res.json({ message: 'Logged out successfully' });
}

async function requestPasswordReset(req, res) {
    try {
        const email = normalizeEmail(req.body.email);
        if (!email) {
            return res.status(400).json({ error: 'email is required' });
        }

        const customer = await Customer.findOne({ where: { email } });
        // Always return the same response whether or not the email exists,
        // so this endpoint can't be used to discover registered emails.
        if (!customer) {
            return res.json({ message: 'If that email is registered, a reset link has been sent.' });
        }

        const resetToken = crypto.randomBytes(32).toString('hex');
        const resetTokenExpiry = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

        customer.resetToken = resetToken;
        customer.resetTokenExpiry = resetTokenExpiry;
        await customer.save();

        // In production this would be emailed, not returned in the response.
        // Returned here for development/testing purposes only.
        res.json({
            message: 'If that email is registered, a reset link has been sent.',
            devResetToken: resetToken,
        });
    } catch (err) {
        handleAuthError(res, err);
    }
}

async function resetPassword(req, res) {
    try {
        const validated = validateResetPasswordBody(req.body);
        if (validated.error) {
            return res.status(400).json({ error: validated.error });
        }

        const { resetToken, newPassword } = validated;

        const customer = await Customer.findOne({ where: { resetToken } });
        if (!customer || customer.resetTokenExpiry < new Date()) {
            return res.status(400).json({ error: 'Invalid or expired reset token' });
        }

        customer.passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
        customer.resetToken = null;
        customer.resetTokenExpiry = null;
        await customer.save();

        res.json({ message: 'Password reset successfully' });
    } catch (err) {
        handleAuthError(res, err);
    }
}

async function staffLogin(req, res) {
    try {
        const validated = validateLoginBody(req.body);
        if (validated.error) {
            return res.status(400).json({ error: validated.error });
        }

        const { email, password } = validated;

        const staff = await Staff.findOne({ where: { email } });
        if (!staff || staff.status !== 'Active') {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const match = await bcrypt.compare(password, staff.passwordHash);
        if (!match) {
            return res.status(401).json({ error: 'Invalid email or password' });
        }

        const token = generateToken({ id: staff.id, type: 'staff', role: staff.role }, '12h');

        res.json({
            token,
            staff: { id: staff.id, fullName: staff.fullName, email: staff.email, role: staff.role },
        });
    } catch (err) {
        handleAuthError(res, err);
    }
}

module.exports = { register, login, logout, requestPasswordReset, resetPassword, staffLogin };
