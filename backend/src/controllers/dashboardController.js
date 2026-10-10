const { Op } = require('sequelize');
const { Booking, Payment, Document, SupportTicket } = require('../models/index');

function daysUntil(dateValue) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const target = new Date(dateValue);
    target.setHours(0, 0, 0, 0);
    return Math.ceil((target - today) / (1000 * 60 * 60 * 24));
}

/** Customer home cards: upcoming trip, payment, documents, open support. */
async function getCustomerDashboard(req, res) {
    try {
        const customerId = req.user.id;
        const now = new Date();
        now.setHours(0, 0, 0, 0);

        const upcomingBooking = await Booking.findOne({
            where: {
                customerId,
                travelDate: { [Op.gte]: now.toISOString().slice(0, 10) },
                status: { [Op.notIn]: ['Cancelled', 'Closed', 'TravelCompleted'] },
            },
            include: [{ model: Payment }],
            order: [['travelDate', 'ASC']],
        });

        let upcomingTrip = null;
        let paymentCard = null;

        if (upcomingBooking) {
            upcomingTrip = {
                bookingId: upcomingBooking.id,
                bookingReference: upcomingBooking.bookingReference,
                destination: upcomingBooking.destination,
                departureCity: upcomingBooking.departureCity,
                travelDate: upcomingBooking.travelDate,
                returnDate: upcomingBooking.returnDate,
                status: upcomingBooking.status,
                daysUntilTravel: daysUntil(upcomingBooking.travelDate),
            };

            const payment = upcomingBooking.Payment;
            if (payment) {
                const total = Number(payment.totalPackagePrice);
                const paid = Number(payment.amountPaid);
                paymentCard = {
                    totalPackagePrice: total,
                    amountPaid: paid,
                    remainingBalance: Math.max(total - paid, 0),
                    paymentDueDate: payment.paymentDueDate,
                    paymentStatus: payment.paymentStatus,
                };
            }
        }

        const documentCount = upcomingBooking
            ? await Document.count({ where: { bookingId: upcomingBooking.id } })
            : 0;

        const activeTickets = await SupportTicket.count({
            where: {
                customerId,
                status: { [Op.in]: ['Open', 'InProgress', 'WaitingForCustomer'] },
            },
        });

        res.json({
            upcomingTrip,
            payment: paymentCard,
            documents: { available: documentCount },
            support: { activeTickets },
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = { getCustomerDashboard };
