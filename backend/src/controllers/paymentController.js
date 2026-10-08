const { Booking, Payment, PaymentHistory } = require('../models/index');
const { notifyCustomer } = require('../utils/notify');

/** Loads the booking and checks the requester may access it (customers: own only, staff: any). */
async function loadBookingWithAccess(req, res) {
    const booking = await Booking.findByPk(req.params.bookingId);
    if (!booking) {
        res.status(404).json({ error: 'Booking not found' });
        return null;
    }
    if (req.user.type === 'customer' && booking.customerId !== req.user.id) {
        res.status(403).json({ error: 'You do not have access to this booking' });
        return null;
    }
    return booking;
}

function buildPaymentSummary(payment, history) {
    const total = Number(payment.totalPackagePrice);
    const paid = Number(payment.amountPaid);
    return {
        totalPackagePrice: total,
        amountPaid: paid,
        remainingBalance: Math.max(total - paid, 0),
        paymentDueDate: payment.paymentDueDate,
        paymentStatus: payment.paymentStatus,
        history: history.map((h) => ({
            id: h.id,
            amount: Number(h.amount),
            paymentDate: h.paymentDate,
            method: h.method,
            note: h.note,
        })),
    };
}

/** Customer (own booking) or staff: view the payment summary and history */
async function getPayment(req, res) {
    try {
        const booking = await loadBookingWithAccess(req, res);
        if (!booking) return;

        const payment = await Payment.findOne({ where: { bookingId: booking.id } });
        if (!payment) return res.status(404).json({ error: 'No payment record for this booking' });

        const history = await PaymentHistory.findAll({
            where: { paymentId: payment.id },
            order: [['paymentDate', 'ASC']],
        });

        res.json(buildPaymentSummary(payment, history));
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: record a deposit or balance payment */
async function recordPayment(req, res) {
    try {
        const { amount, method, note } = req.body;
        const value = Number(amount);
        if (!value || value <= 0) {
            return res.status(400).json({ error: 'amount must be a positive number' });
        }

        const booking = await Booking.findByPk(req.params.bookingId);
        if (!booking) return res.status(404).json({ error: 'Booking not found' });

        const payment = await Payment.findOne({ where: { bookingId: booking.id } });
        if (!payment) return res.status(404).json({ error: 'No payment record for this booking' });

        const total = Number(payment.totalPackagePrice);
        const alreadyPaid = Number(payment.amountPaid);
        if (alreadyPaid + value > total) {
            return res.status(400).json({
                error: `Payment exceeds the remaining balance of ${(total - alreadyPaid).toFixed(2)}`,
            });
        }

        const entry = await PaymentHistory.create({
            paymentId: payment.id,
            amount: value,
            method: method || 'Card',
            note: note || null,
        });

        const newPaid = alreadyPaid + value;
        payment.amountPaid = newPaid;
        payment.paymentStatus = newPaid >= total ? 'FullyPaid' : 'PartiallyPaid';
        await payment.save();

        if (payment.paymentStatus === 'FullyPaid' &&
            ['Pending', 'Processing', 'AwaitingPayment'].includes(booking.status)) {
            booking.status = 'PaymentReceived';
            await booking.save();
        }

        await notifyCustomer(
            booking.customerId,
            'PaymentReceived',
            `Payment of ${value.toFixed(2)} received for booking ${booking.bookingReference}.`
        );

        res.status(201).json({
            message: 'Payment recorded',
            receiptId: entry.id,
            remainingBalance: Math.max(total - newPaid, 0),
            paymentStatus: payment.paymentStatus,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: issue a refund. Records a negative history entry and marks the payment Refunded. */
async function issueRefund(req, res) {
    try {
        const { amount, note } = req.body;
        const value = Number(amount);
        if (!value || value <= 0) {
            return res.status(400).json({ error: 'amount must be a positive number' });
        }

        const booking = await Booking.findByPk(req.params.bookingId);
        if (!booking) return res.status(404).json({ error: 'Booking not found' });

        const payment = await Payment.findOne({ where: { bookingId: booking.id } });
        if (!payment) return res.status(404).json({ error: 'No payment record for this booking' });

        const alreadyPaid = Number(payment.amountPaid);
        if (value > alreadyPaid) {
            return res.status(400).json({ error: `Refund exceeds the amount paid (${alreadyPaid.toFixed(2)})` });
        }

        await PaymentHistory.create({
            paymentId: payment.id,
            amount: -value,
            method: 'Refund',
            note: note || null,
        });

        payment.amountPaid = alreadyPaid - value;
        payment.paymentStatus = 'Refunded';
        await payment.save();

        await notifyCustomer(
            booking.customerId,
            'Refund',
            `A refund of ${value.toFixed(2)} was issued for booking ${booking.bookingReference}.`
        );

        res.status(201).json({
            message: 'Refund issued',
            amountPaid: Number(payment.amountPaid),
            paymentStatus: payment.paymentStatus,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Customer (own booking) or staff: receipt for a single payment history entry */
async function getReceipt(req, res) {
    try {
        const booking = await loadBookingWithAccess(req, res);
        if (!booking) return;

        const payment = await Payment.findOne({ where: { bookingId: booking.id } });
        if (!payment) return res.status(404).json({ error: 'No payment record for this booking' });

        const entry = await PaymentHistory.findOne({
            where: { id: req.params.receiptId, paymentId: payment.id },
        });
        if (!entry) return res.status(404).json({ error: 'Receipt not found' });

        res.json({
            receiptNumber: `RCPT-${String(entry.id).padStart(6, '0')}`,
            bookingReference: booking.bookingReference,
            destination: booking.destination,
            amount: Number(entry.amount),
            method: entry.method,
            paymentDate: entry.paymentDate,
            note: entry.note,
            totalPackagePrice: Number(payment.totalPackagePrice),
            amountPaidToDate: Number(payment.amountPaid),
            remainingBalance: Math.max(Number(payment.totalPackagePrice) - Number(payment.amountPaid), 0),
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = { getPayment, recordPayment, issueRefund, getReceipt };