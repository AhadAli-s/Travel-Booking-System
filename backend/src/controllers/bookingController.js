const bcrypt = require('bcrypt');
const {
    Booking, Customer, Staff, Flight, Hotel, Transfer, Payment, Passenger, Document,
} = require('../models/index');
const { generateBookingReference } = require('../utils/generateReference');

const FULL_INCLUDE = [
    { model: Flight },
    { model: Hotel },
    { model: Transfer },
    { model: Payment },
    // Passport number/expiry excluded here — only the single-passenger detail
    // endpoint (GET /bookings/:bookingId/passengers/:passengerId) returns those.
    { model: Passenger, attributes: { exclude: ['passportNumber', 'passportExpiry'] } },
    { model: Document },
    { model: Customer, attributes: ['id', 'fullName', 'email', 'phone'] },
    { model: Staff, as: 'assignedStaff', attributes: ['id', 'fullName', 'role'] },
];

async function generateUniqueReference() {
    let reference;
    let exists = true;
    while (exists) {
        reference = generateBookingReference();
        exists = await Booking.findOne({ where: { bookingReference: reference } });
    }
    return reference;
}

/**
 * Simulates the travel agency website pushing a new booking into the system.
 * In a real deployment this would be called by the website's own backend
 * (ideally behind an API key / shared secret, not open to the public internet).
 * If no customer exists for the given email yet, one is created automatically
 * so the booking is immediately visible once they register/log in with that email.
 */
async function createBookingFromWebsite(req, res) {
    try {
        const {
            customerEmail, customerName, destination, departureCity, departureAirport,
            travelDate, returnDate, numAdults, numChildren, numInfants,
            totalPackagePrice, paymentDueDate,
        } = req.body;

        if (!customerEmail || !destination || !travelDate || !returnDate || !totalPackagePrice) {
            return res.status(400).json({
                error: 'customerEmail, destination, travelDate, returnDate, and totalPackagePrice are required',
            });
        }

        let customer = await Customer.findOne({ where: { email: customerEmail } });
        if (!customer) {
            // Website bookings can arrive before the customer ever registers in the app.
            // A random password is set; they'll use "Forgot Password" to claim the account.
            const randomPassword = await bcrypt.hash(Math.random().toString(36), 10);
            customer = await Customer.create({
                fullName: customerName || 'New Customer',
                email: customerEmail,
                passwordHash: randomPassword,
            });
        }

        const nights = Math.round((new Date(returnDate) - new Date(travelDate)) / (1000 * 60 * 60 * 24));
        const reference = await generateUniqueReference();

        const booking = await Booking.create({
            bookingReference: reference,
            customerId: customer.id,
            destination,
            departureCity,
            departureAirport,
            travelDate,
            returnDate,
            numNights: nights >= 0 ? nights : null,
            numAdults: numAdults || 1,
            numChildren: numChildren || 0,
            numInfants: numInfants || 0,
            status: 'Pending',
        });

        await Payment.create({
            bookingId: booking.id,
            totalPackagePrice,
            amountPaid: 0,
            paymentDueDate: paymentDueDate || null,
            paymentStatus: 'Unpaid',
        });

        res.status(201).json({
            message: 'Booking created from website',
            bookingReference: booking.bookingReference,
            bookingId: booking.id,
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff manually creating a booking (e.g. phone booking) */
async function createBookingByStaff(req, res) {
    try {
        const { customerId, destination, travelDate, returnDate, totalPackagePrice } = req.body;
        if (!customerId || !destination || !travelDate || !returnDate || !totalPackagePrice) {
            return res.status(400).json({
                error: 'customerId, destination, travelDate, returnDate, and totalPackagePrice are required',
            });
        }

        const customer = await Customer.findByPk(customerId);
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        const reference = await generateUniqueReference();
        const nights = Math.round((new Date(returnDate) - new Date(travelDate)) / (1000 * 60 * 60 * 24));

        const booking = await Booking.create({
            ...req.body,
            bookingReference: reference,
            numNights: nights >= 0 ? nights : null,
        });

        await Payment.create({
            bookingId: booking.id,
            totalPackagePrice,
            paymentDueDate: req.body.paymentDueDate || null,
        });

        res.status(201).json(booking);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Customer's own bookings, split into previous/active/upcoming */
async function getMyBookings(req, res) {
    try {
        const bookings = await Booking.findAll({
            where: { customerId: req.user.id },
            include: [{ model: Payment }],
            order: [['travelDate', 'DESC']],
        });

        const now = new Date();
        const categorized = { upcoming: [], active: [], previous: [] };

        for (const booking of bookings) {
            const travel = new Date(booking.travelDate);
            const returnD = new Date(booking.returnDate);
            if (['Cancelled', 'Closed', 'TravelCompleted'].includes(booking.status) || returnD < now) {
                categorized.previous.push(booking);
            } else if (travel <= now && returnD >= now) {
                categorized.active.push(booking);
            } else {
                categorized.upcoming.push(booking);
            }
        }

        res.json(categorized);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Public lookup — booking reference + email, no login required (per spec's core flow) */
async function lookupBooking(req, res) {
    try {
        const { bookingReference, email } = req.body;
        if (!bookingReference || !email) {
            return res.status(400).json({ error: 'bookingReference and email are required' });
        }

        const booking = await Booking.findOne({
            where: { bookingReference },
            include: FULL_INCLUDE,
        });

        if (!booking || booking.Customer.email.toLowerCase() !== email.toLowerCase()) {
            return res.status(404).json({ error: 'No booking found matching that reference and email' });
        }

        res.json(booking);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Get a single booking's full detail. Customers may only view their own; staff may view any. */
async function getBookingById(req, res) {
    try {
        const booking = await Booking.findByPk(req.params.id, { include: FULL_INCLUDE });
        if (!booking) {
            return res.status(404).json({ error: 'Booking not found' });
        }

        if (req.user.type === 'customer' && booking.customerId !== req.user.id) {
            return res.status(403).json({ error: 'You do not have access to this booking' });
        }

        res.json(booking);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: list all bookings, optionally filtered by status */
async function listAllBookings(req, res) {
    try {
        const where = {};
        if (req.query.status) where.status = req.query.status;

        const bookings = await Booking.findAll({
            where,
            include: [
                { model: Customer, attributes: ['id', 'fullName', 'email'] },
                { model: Staff, as: 'assignedStaff', attributes: ['id', 'fullName'] },
                { model: Payment },
            ],
            order: [['createdAt', 'DESC']],
        });

        res.json(bookings);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: edit booking fields (destination, dates, notes, etc.) */
async function updateBooking(req, res) {
    try {
        const booking = await Booking.findByPk(req.params.id);
        if (!booking) return res.status(404).json({ error: 'Booking not found' });

        await booking.update(req.body);
        res.json(booking);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

const VALID_STATUSES = [
    'Pending', 'Processing', 'AwaitingPayment', 'PaymentReceived', 'Confirmed',
    'DocumentsPending', 'DocumentsIssued', 'ReadyToTravel', 'TravelCompleted',
    'Cancelled', 'Closed',
];

/** Staff: change booking status (confirm, cancel, close, progress through the timeline) */
async function updateBookingStatus(req, res) {
    try {
        const { status } = req.body;
        if (!VALID_STATUSES.includes(status)) {
            return res.status(400).json({ error: `Invalid status. Must be one of: ${VALID_STATUSES.join(', ')}` });
        }

        const booking = await Booking.findByPk(req.params.id);
        if (!booking) return res.status(404).json({ error: 'Booking not found' });

        booking.status = status;
        await booking.save();

        res.json({ message: 'Status updated', booking });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/** Staff: assign a booking to a staff member */
async function assignStaff(req, res) {
    try {
        const { staffId } = req.body;
        const booking = await Booking.findByPk(req.params.id);
        if (!booking) return res.status(404).json({ error: 'Booking not found' });

        if (staffId) {
            const staff = await Staff.findByPk(staffId);
            if (!staff) return res.status(404).json({ error: 'Staff member not found' });
        }

        booking.assignedStaffId = staffId || null;
        await booking.save();

        res.json({ message: 'Booking assignment updated', booking });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = {
    createBookingFromWebsite,
    createBookingByStaff,
    getMyBookings,
    lookupBooking,
    getBookingById,
    listAllBookings,
    updateBooking,
    updateBookingStatus,
    assignStaff,
};