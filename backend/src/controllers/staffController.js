const bcrypt = require('bcrypt');
const { Op } = require('sequelize');
const { Staff } = require('../models/index');
const { sendError } = require('../utils/sendError');
const { pick } = require('../utils/pick');
const { normalizeEmail, isValidEmail, validatePassword } = require('../utils/authValidation');

const ROLES = ['Administrator', 'BookingAgent', 'AccountsStaff', 'SupportAgent'];
const STATUSES = ['Active', 'Inactive'];
const PUBLIC_FIELDS = ['id', 'fullName', 'email', 'role', 'status', 'createdAt'];

/** Administrator: list all staff accounts */
async function listStaff(req, res) {
    try {
        const staff = await Staff.findAll({ attributes: PUBLIC_FIELDS, order: [['createdAt', 'ASC']] });
        res.json(staff);
    } catch (err) {
        sendError(res, err);
    }
}

/** Administrator: create a staff account. Body: { fullName, email, password, role } */
async function createStaff(req, res) {
    try {
        const fullName = typeof req.body.fullName === 'string' ? req.body.fullName.trim() : '';
        const email = normalizeEmail(req.body.email);
        const { password, role } = req.body;

        if (fullName.length < 2) return res.status(400).json({ error: 'fullName is required' });
        if (!isValidEmail(email)) return res.status(400).json({ error: 'A valid email is required' });
        const passwordError = validatePassword(password);
        if (passwordError) return res.status(400).json({ error: passwordError });
        if (!ROLES.includes(role)) {
            return res.status(400).json({ error: `role must be one of: ${ROLES.join(', ')}` });
        }

        if (await Staff.findOne({ where: { email } })) {
            return res.status(409).json({ error: 'A staff account with this email already exists' });
        }

        const staff = await Staff.create({
            fullName,
            email,
            role,
            status: 'Active',
            passwordHash: await bcrypt.hash(password, 10),
        });
        res.status(201).json(pick(staff.toJSON(), PUBLIC_FIELDS));
    } catch (err) {
        sendError(res, err);
    }
}

/**
 * Administrator: change name, role, status or password.
 * Body: { fullName?, role?, status?, password? }
 * An administrator cannot demote or deactivate their own account, and the
 * last active administrator can never be removed.
 */
async function updateStaff(req, res) {
    try {
        const staff = await Staff.findByPk(req.params.id);
        if (!staff) return res.status(404).json({ error: 'Staff member not found' });

        const changes = {};
        if (req.body.fullName !== undefined) {
            const name = String(req.body.fullName).trim();
            if (name.length < 2) return res.status(400).json({ error: 'fullName must be at least 2 characters' });
            changes.fullName = name;
        }
        if (req.body.role !== undefined) {
            if (!ROLES.includes(req.body.role)) {
                return res.status(400).json({ error: `role must be one of: ${ROLES.join(', ')}` });
            }
            changes.role = req.body.role;
        }
        if (req.body.status !== undefined) {
            if (!STATUSES.includes(req.body.status)) {
                return res.status(400).json({ error: `status must be one of: ${STATUSES.join(', ')}` });
            }
            changes.status = req.body.status;
        }
        if (req.body.password !== undefined) {
            const passwordError = validatePassword(req.body.password);
            if (passwordError) return res.status(400).json({ error: passwordError });
            changes.passwordHash = await bcrypt.hash(req.body.password, 10);
        }

        const losesAdmin = staff.role === 'Administrator' && staff.status === 'Active'
            && ((changes.role && changes.role !== 'Administrator') || changes.status === 'Inactive');

        if (losesAdmin) {
            if (staff.id === req.user.id) {
                return res.status(400).json({ error: 'You cannot demote or deactivate your own account' });
            }
            const otherAdmins = await Staff.count({
                where: { role: 'Administrator', status: 'Active', id: { [Op.ne]: staff.id } },
            });
            if (otherAdmins < 1) {
                return res.status(400).json({ error: 'At least one active administrator is required' });
            }
        }

        await staff.update(changes);
        res.json(pick(staff.toJSON(), PUBLIC_FIELDS));
    } catch (err) {
        sendError(res, err);
    }
}

module.exports = { listStaff, createStaff, updateStaff };