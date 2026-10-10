const { Customer } = require('../models/index');

const PROFILE_ATTRIBUTES = ['id', 'fullName', 'email', 'phone', 'createdAt'];

async function getProfile(req, res) {
    try {
        const customer = await Customer.findByPk(req.user.id, {
            attributes: PROFILE_ATTRIBUTES,
        });
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }
        res.json(customer);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function updateProfile(req, res) {
    try {
        const customer = await Customer.findByPk(req.user.id);
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        const updates = {};
        if (req.body.fullName !== undefined) {
            const fullName = typeof req.body.fullName === 'string' ? req.body.fullName.trim() : '';
            if (fullName.length < 2) {
                return res.status(400).json({ error: 'fullName is required (at least 2 characters)' });
            }
            updates.fullName = fullName;
        }
        if (req.body.phone !== undefined) {
            updates.phone = req.body.phone === null || req.body.phone === ''
                ? null
                : String(req.body.phone).trim();
        }

        if (Object.keys(updates).length === 0) {
            return res.status(400).json({ error: 'Provide fullName and/or phone to update' });
        }

        await customer.update(updates);
        res.json({
            id: customer.id,
            fullName: customer.fullName,
            email: customer.email,
            phone: customer.phone,
            createdAt: customer.createdAt,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = { getProfile, updateProfile };
