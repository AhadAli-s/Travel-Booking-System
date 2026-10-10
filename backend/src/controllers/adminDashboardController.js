const { Op } = require('sequelize');
const { Booking, Payment, SupportTicket } = require('../models/index');

function isoDate(offsetDays) {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() + offsetDays);
    return d.toISOString().slice(0, 10);
}

/** Agency home metrics from the spec: bookings, payments, tickets, travellers soon. */
async function getAdminDashboard(req, res) {
    try {
        const today = isoDate(0);
        const inFourteenDays = isoDate(14);

        const [
            totalBookings,
            pendingBookings,
            confirmedBookings,
            cancelledBookings,
            travellingSoon,
            outstandingPayments,
            openSupportTickets,
        ] = await Promise.all([
            Booking.count(),
            Booking.count({ where: { status: { [Op.in]: ['Pending', 'Processing', 'AwaitingPayment'] } } }),
            Booking.count({ where: { status: 'Confirmed' } }),
            Booking.count({ where: { status: 'Cancelled' } }),
            Booking.count({
                where: {
                    travelDate: { [Op.between]: [today, inFourteenDays] },
                    status: { [Op.notIn]: ['Cancelled', 'Closed', 'TravelCompleted'] },
                },
            }),
            Payment.count({ where: { paymentStatus: { [Op.in]: ['Unpaid', 'PartiallyPaid'] } } }),
            SupportTicket.count({
                where: { status: { [Op.in]: ['Open', 'InProgress', 'WaitingForCustomer'] } },
            }),
        ]);

        res.json({
            totalBookings,
            pendingBookings,
            confirmedBookings,
            cancelledBookings,
            travellingSoon,
            outstandingPayments,
            openSupportTickets,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = { getAdminDashboard };
