const { SupportTicket, TicketReply, Booking, Customer, Staff } = require('../models/index');
const { notifyCustomer } = require('../utils/notify');

const VALID_CATEGORIES = [
    'Flight', 'Hotel', 'Payment', 'Transfer', 'Document',
    'PassengerDetails', 'CancellationRequest', 'GeneralSupport',
];
const VALID_STATUSES = ['Open', 'InProgress', 'WaitingForCustomer', 'Resolved', 'Closed'];

/** Loads a ticket and checks the requester may access it (customers: own only, staff: any). */
async function loadTicketWithAccess(req, res) {
    const ticket = await SupportTicket.findByPk(req.params.id);
    if (!ticket) {
        res.status(404).json({ error: 'Ticket not found' });
        return null;
    }
    if (req.user.type === 'customer' && ticket.customerId !== req.user.id) {
        res.status(403).json({ error: 'You do not have access to this ticket' });
        return null;
    }
    return ticket;
}

/** Customer: report an issue. bookingId is optional (general support has no booking). */
async function createTicket(req, res) {
    try {
        const { category, subject, description, bookingId } = req.body;

        if (!VALID_CATEGORIES.includes(category)) {
            return res.status(400).json({ error: `category must be one of: ${VALID_CATEGORIES.join(', ')}` });
        }
        if (!subject || !description) {
            return res.status(400).json({ error: 'subject and description are required' });
        }

        if (bookingId) {
            const booking = await Booking.findByPk(bookingId);
            if (!booking || booking.customerId !== req.user.id) {
                return res.status(403).json({ error: 'You can only raise tickets for your own bookings' });
            }
        }

        const ticket = await SupportTicket.create({
            customerId: req.user.id,
            bookingId: bookingId || null,
            category,
            subject,
            description,
            status: 'Open',
        });

        res.status(201).json(ticket);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Customer: list own tickets */
async function getMyTickets(req, res) {
    try {
        const tickets = await SupportTicket.findAll({
            where: { customerId: req.user.id },
            order: [['updatedAt', 'DESC']],
        });
        res.json(tickets);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: ticket dashboard, optionally filtered by status */
async function listAllTickets(req, res) {
    try {
        const where = {};
        if (req.query.status) where.status = req.query.status;

        const tickets = await SupportTicket.findAll({
            where,
            include: [
                { model: Customer, attributes: ['id', 'fullName', 'email'] },
                { model: Staff, as: 'assignedStaff', attributes: ['id', 'fullName'] },
            ],
            order: [['createdAt', 'DESC']],
        });
        res.json(tickets);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Customer (own) or staff: ticket detail with its full reply thread */
async function getTicket(req, res) {
    try {
        const ticket = await loadTicketWithAccess(req, res);
        if (!ticket) return;

        const replies = await TicketReply.findAll({
            where: { ticketId: ticket.id },
            order: [['createdAt', 'ASC']],
        });

        res.json({ ...ticket.toJSON(), replies });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Customer (own ticket) or staff: add a reply to the thread */
async function addReply(req, res) {
    try {
        const ticket = await loadTicketWithAccess(req, res);
        if (!ticket) return;

        const { message } = req.body;
        if (!message) return res.status(400).json({ error: 'message is required' });

        if (ticket.status === 'Closed') {
            return res.status(400).json({ error: 'This ticket is closed and can no longer be replied to' });
        }

        const senderType = req.user.type === 'staff' ? 'Staff' : 'Customer';
        const reply = await TicketReply.create({ ticketId: ticket.id, senderType, message });

        if (senderType === 'Staff') {
            // A staff reply puts the ball back in the customer's court
            if (ticket.status === 'Open' || ticket.status === 'InProgress') {
                ticket.status = 'WaitingForCustomer';
                await ticket.save();
            }
            await notifyCustomer(
                ticket.customerId,
                'TicketReply',
                `Support replied to your ticket: "${ticket.subject}".`
            );
        } else if (ticket.status === 'WaitingForCustomer') {
            ticket.status = 'InProgress';
            await ticket.save();
        }

        res.status(201).json(reply);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: change ticket status */
async function updateTicketStatus(req, res) {
    try {
        const { status } = req.body;
        if (!VALID_STATUSES.includes(status)) {
            return res.status(400).json({ error: `status must be one of: ${VALID_STATUSES.join(', ')}` });
        }

        const ticket = await SupportTicket.findByPk(req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

        ticket.status = status;
        await ticket.save();

        if (status === 'Resolved') {
            await notifyCustomer(
                ticket.customerId,
                'TicketResolved',
                `Your ticket "${ticket.subject}" has been marked as resolved.`
            );
        }

        res.json(ticket);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: assign a ticket to a staff member */
async function assignTicket(req, res) {
    try {
        const { staffId } = req.body;
        const ticket = await SupportTicket.findByPk(req.params.id);
        if (!ticket) return res.status(404).json({ error: 'Ticket not found' });

        if (staffId) {
            const staff = await Staff.findByPk(staffId);
            if (!staff) return res.status(404).json({ error: 'Staff member not found' });
        }

        ticket.assignedStaffId = staffId || null;
        await ticket.save();
        res.json(ticket);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = {
    createTicket,
    getMyTickets,
    listAllTickets,
    getTicket,
    addReply,
    updateTicketStatus,
    assignTicket,
};