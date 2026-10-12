const { Op } = require('sequelize');
const { Customer, Booking, Payment, SupportTicket, ContactNote, Staff } = require('../models/index');
const { sendError } = require('../utils/sendError');

const CHANNELS = ['Phone', 'Email', 'InApp', 'InPerson', 'Other'];
const CUSTOMER_FIELDS = ['id', 'fullName', 'email', 'phone', 'createdAt'];

/** Staff: list customers. Query: ?search=text&limit=50&offset=0 */
async function listCustomers(req, res) {
    try {
        const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 200);
        const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);
        const search = typeof req.query.search === 'string' ? req.query.search.trim().slice(0, 100) : '';

        const where = {};
        if (search) {
            const term = `%${search.replace(/[%_\\]/g, '\\$&')}%`;
            where[Op.or] = [
                { fullName: { [Op.iLike]: term } },
                { email: { [Op.iLike]: term } },
                { phone: { [Op.iLike]: term } },
            ];
        }

        const { rows, count } = await Customer.findAndCountAll({
            where,
            attributes: CUSTOMER_FIELDS,
            include: [{ model: Booking, attributes: ['id', 'status'] }],
            order: [['createdAt', 'DESC']],
            limit,
            offset,
            distinct: true,
        });

        res.json({
            total: count,
            customers: rows.map((c) => ({
                id: c.id,
                fullName: c.fullName,
                email: c.email,
                phone: c.phone,
                createdAt: c.createdAt,
                totalBookings: c.Bookings.length,
                activeBookings: c.Bookings.filter(
                    (b) => !['Cancelled', 'Closed', 'TravelCompleted'].includes(b.status)
                ).length,
            })),
        });
    } catch (err) {
        sendError(res, err);
    }
}

/** Staff: one customer with bookings, tickets and contact history */
async function getCustomer(req, res) {
    try {
        const customer = await Customer.findByPk(req.params.id, { attributes: CUSTOMER_FIELDS });
        if (!customer) return res.status(404).json({ error: 'Customer not found' });

        const [bookings, tickets, notes] = await Promise.all([
            Booking.findAll({
                where: { customerId: customer.id },
                include: [{ model: Payment }],
                order: [['travelDate', 'DESC']],
            }),
            SupportTicket.findAll({
                where: { customerId: customer.id },
                order: [['updatedAt', 'DESC']],
            }),
            ContactNote.findAll({
                where: { customerId: customer.id },
                include: [{ model: Staff, as: 'author', attributes: ['id', 'fullName', 'role'] }],
                order: [['createdAt', 'DESC']],
            }),
        ]);

        res.json({ customer, bookings, tickets, contactHistory: notes });
    } catch (err) {
        sendError(res, err);
    }
}

/** Staff: add a contact history note. Body: { note, channel?, bookingId? } */
async function addContactNote(req, res) {
    try {
        const customer = await Customer.findByPk(req.params.id, { attributes: ['id'] });
        if (!customer) return res.status(404).json({ error: 'Customer not found' });

        const note = typeof req.body.note === 'string' ? req.body.note.trim() : '';
        if (!note || note.length > 2000) {
            return res.status(400).json({ error: 'note is required (max 2000 characters)' });
        }
        const channel = req.body.channel || 'Phone';
        if (!CHANNELS.includes(channel)) {
            return res.status(400).json({ error: `channel must be one of: ${CHANNELS.join(', ')}` });
        }

        let bookingId = null;
        if (req.body.bookingId) {
            const booking = await Booking.findByPk(req.body.bookingId, { attributes: ['id', 'customerId'] });
            if (!booking || booking.customerId !== customer.id) {
                return res.status(400).json({ error: 'bookingId does not belong to this customer' });
            }
            bookingId = booking.id;
        }

        const created = await ContactNote.create({
            customerId: customer.id,
            staffId: req.user.id,
            bookingId,
            channel,
            note,
        });
        res.status(201).json(created);
    } catch (err) {
        sendError(res, err);
    }
}

module.exports = { listCustomers, getCustomer, addContactNote };