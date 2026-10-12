const bcrypt = require('bcrypt');
const crypto = require('crypto');
const {
    Booking, Customer, Staff, Flight, Hotel, Transfer, Payment, Passenger, Document,
} = require('../models/index');
const { generateBookingReference } = require('../utils/generateReference');
const { notifyCustomer } = require('../utils/notify');
const { pick } = require('../utils/pick');
const { sendError } = require('../utils/sendError');
const { normalizeEmail, isValidEmail } = require('../utils/authValidation');
const { parseDate, nightsBetween, toCount, toPrice, cleanText } = require('../utils/bookingValidation');

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
 * Website integration: the agency website pushes a new booking here.
 * Protected by the x-api-key header (see middleware/apiKey.js).
 * If no customer exists for the email yet, one is created with an unusable
 * random password. The customer claims the account through "Forgot Password".
 */
async function createBookingFromWebsite(req, res) {
    try {
        const email = normalizeEmail(req.body.customerEmail);
        const travelDate = parseDate(req.body.travelDate);
        const returnDate = parseDate(req.body.returnDate);
        const destination = cleanText(req.body.destination);
        const price = toPrice(req.body.totalPackagePrice);
        const numAdults = toCount(req.body.numAdults, 1);
        const numChildren = toCount(req.body.numChildren, 0);
        const numInfants = toCount(req.body.numInfants, 0);
        const paymentDueDate = req.body.paymentDueDate ? parseDate(req.body.paymentDueDate) : null;

        if (!email || !isValidEmail(email) || !destination || !travelDate || !returnDate || price === null) {
            return res.status(400).json({
                error: 'Valid customerEmail, destination, travelDate (YYYY-MM-DD), returnDate (YYYY-MM-DD) and totalPackagePrice are required',
            });
        }
        if (returnDate < travelDate) {
            return res.status(400).json({ error: 'returnDate cannot be before travelDate' });
        }
        if (numAdults === null || numChildren === null || numInfants === null || numAdults < 1) {
            return res.status(400).json({ error: 'Traveller counts must be whole numbers with at least 1 adult' });
        }
        if (req.body.paymentDueDate && !paymentDueDate) {
            return res.status(400).json({ error: 'paymentDueDate must be YYYY-MM-DD' });
        }

        let customer = await Customer.findOne({ where: { email } });
        if (!customer) {
            const unusablePassword = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
            customer = await Customer.create({
                fullName: cleanText(req.body.customerName) || 'New Customer',
                email,
                passwordHash: unusablePassword,
            });
        }

        const reference = await generateUniqueReference();
        const booking = await Booking.create({
            bookingReference: reference,
            customerId: customer.id,
            destination,
            departureCity: cleanText(req.body.departureCity),
            departureAirport: cleanText(req.body.departureAirport),
            travelDate,
            returnDate,
            numNights: nightsBetween(travelDate, returnDate),
            numAdults,
            numChildren,
            numInfants,
            status: 'Pending',
        });

        await Payment.create({
            bookingId: booking.id,
            totalPackagePrice: price,
            amountPaid: 0,
            paymentDueDate,
            paymentStatus: 'Unpaid',
        });

        res.status(201).json({
            message: 'Booking created from website',
            bookingReference: booking.bookingReference,
            bookingId: booking.id,
        });
    } catch (err) {
        sendError(res, err);
    }
}

/** Staff manually creating a booking (e.g. phone booking) */
async function createBookingByStaff(req, res) {
    try {
        const travelDate = parseDate(req.body.travelDate);
        const returnDate = parseDate(req.body.returnDate);
        const destination = cleanText(req.body.destination);
        const price = toPrice(req.body.totalPackagePrice);
        const numAdults = toCount(req.body.numAdults, 1);
        const numChildren = toCount(req.body.numChildren, 0);
        const numInfants = toCount(req.body.numInfants, 0);
        const paymentDueDate = req.body.paymentDueDate ? parseDate(req.body.paymentDueDate) : null;

        if (!req.body.customerId || !destination || !travelDate || !returnDate || price === null) {
            return res.status(400).json({
                error: 'customerId, destination, travelDate, returnDate and totalPackagePrice are required',
            });
        }
        if (returnDate < travelDate) {
            return res.status(400).json({ error: 'returnDate cannot be before travelDate' });
        }
        if (numAdults === null || numChildren === null || numInfants === null || numAdults < 1) {
            return res.status(400).json({ error: 'Traveller counts must be whole numbers with at least 1 adult' });
        }
        if (req.body.paymentDueDate && !paymentDueDate) {
            return res.status(400).json({ error: 'paymentDueDate must be YYYY-MM-DD' });
        }

        const customer = await Customer.findByPk(req.body.customerId);
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }

        const booking = await Booking.create({
            bookingReference: await generateUniqueReference(),
            customerId: customer.id,
            destination,
            departureCity: cleanText(req.body.departureCity),
            departureAirport: cleanText(req.body.departureAirport),
            travelDate,
            returnDate,
            numNights: nightsBetween(travelDate, returnDate),
            numAdults,
            numChildren,
            numInfants,
            notes: cleanText(req.body.notes, 2000),
            status: 'Pending',
        });

        await Payment.create({
            bookingId: booking.id,
            totalPackagePrice: price,
            paymentDueDate,
        });

        res.status(201).json(booking);
    } catch (err) {
        sendError(res, err);
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
        sendError(res, err);
    }
}

/** Public lookup: booking reference + email, no login required (per spec's core flow) */
async function lookupBooking(req, res) {
    try {
        const reference = typeof req.body.bookingReference === 'string'
            ? req.body.bookingReference.trim().toUpperCase()
            : '';
        const email = normalizeEmail(req.body.email);
        if (!reference || !email) {
            return res.status(400).json({ error: 'bookingReference and email are required' });
        }

        const booking = await Booking.findOne({
            where: { bookingReference: reference },
            include: FULL_INCLUDE,
        });

        if (!booking || booking.Customer.email.toLowerCase() !== email) {
            return res.status(404).json({ error: 'No booking found matching that reference and email' });
        }

        res.json(booking);
    } catch (err) {
        sendError(res, err);
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
        sendError(res, err);
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
        sendError(res, err);
    }
}

/** Staff: edit booking details. Only whitelisted fields can change (status has its own endpoint). */
async function updateBooking(req, res) {
    try {
        const booking = await Booking.findByPk(req.params.id);
        if (!booking) return res.status(404).json({ error: 'Booking not found' });

        const changes = pick(req.body, [
            'destination', 'departureCity', 'departureAirport', 'travelDate', 'returnDate',
            'numAdults', 'numChildren', 'numInfants', 'notes',
        ]);

        if ('travelDate' in changes) {
            changes.travelDate = parseDate(changes.travelDate);
            if (!changes.travelDate) return res.status(400).json({ error: 'travelDate must be YYYY-MM-DD' });
        }
        if ('returnDate' in changes) {
            changes.returnDate = parseDate(changes.returnDate);
            if (!changes.returnDate) return res.status(400).json({ error: 'returnDate must be YYYY-MM-DD' });
        }
        for (const key of ['numAdults', 'numChildren', 'numInfants']) {
            if (key in changes) {
                changes[key] = toCount(changes[key], null);
                if (changes[key] === null) return res.status(400).json({ error: `${key} must be a whole number` });
            }
        }
        if ('destination' in changes) {
            changes.destination = cleanText(changes.destination);
            if (!changes.destination) return res.status(400).json({ error: 'destination cannot be empty' });
        }

        const travelDate = changes.travelDate || booking.travelDate;
        const returnDate = changes.returnDate || booking.returnDate;
        if (returnDate < travelDate) {
            return res.status(400).json({ error: 'returnDate cannot be before travelDate' });
        }
        if ('travelDate' in changes || 'returnDate' in changes) {
            changes.numNights = nightsBetween(travelDate, returnDate);
        }

        await booking.update(changes);
        res.json(booking);
    } catch (err) {
        sendError(res, err);
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

        await notifyCustomer(
            booking.customerId,
            'BookingStatus',
            `Your booking ${booking.bookingReference} is now ${status}.`
        );

        res.json({ message: 'Status updated', booking });
    } catch (err) {
        sendError(res, err);
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
        sendError(res, err);
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