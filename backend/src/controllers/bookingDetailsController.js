const { Booking, Flight, Hotel, Transfer, Passenger } = require('../models/index');

/**
 * Shared helper: confirms the booking exists AND that the requester is
 * allowed to touch it — a customer may only access sub-resources (flight,
 * hotel, transfer, passengers) on their own booking; staff may access any.
 * Returns null (after sending the appropriate error response) if access
 * should be denied, so callers can just `if (!booking) return;`.
 */
async function findBookingOr404(req, res) {
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

// ---------- FLIGHT (one per booking) ----------
async function upsertFlight(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        let flight = await Flight.findOne({ where: { bookingId: booking.id } });
        if (flight) {
            await flight.update(req.body);
        } else {
            flight = await Flight.create({ ...req.body, bookingId: booking.id });
        }
        res.json(flight);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

// ---------- HOTEL (one per booking) ----------
async function upsertHotel(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        let hotel = await Hotel.findOne({ where: { bookingId: booking.id } });
        if (hotel) {
            await hotel.update(req.body);
        } else {
            hotel = await Hotel.create({ ...req.body, bookingId: booking.id });
        }
        res.json(hotel);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

// ---------- TRANSFER (one per booking) ----------
async function upsertTransfer(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        let transfer = await Transfer.findOne({ where: { bookingId: booking.id } });
        if (transfer) {
            await transfer.update(req.body);
        } else {
            transfer = await Transfer.create({ ...req.body, bookingId: booking.id });
        }
        res.json(transfer);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

// ---------- PASSENGERS (many per booking) ----------
async function addPassenger(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        const passenger = await Passenger.create({ ...req.body, bookingId: booking.id });
        res.status(201).json(passenger);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function listPassengers(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        // Passport number/expiry deliberately excluded here — only the single-passenger
        // detail endpoint (getPassengerDetail) returns those fields.
        const passengers = await Passenger.findAll({
            where: { bookingId: booking.id },
            attributes: { exclude: ['passportNumber', 'passportExpiry'] },
        });
        res.json(passengers);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

/**
 * Single passenger detail, including passportNumber. This is the ONLY
 * endpoint that returns the passport number — list views and general
 * booking detail should never include it, per the spec's requirement that
 * passenger data be "properly protected."
 */
async function getPassengerDetail(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        const passenger = await Passenger.findOne({
            where: { id: req.params.passengerId, bookingId: req.params.bookingId },
        });
        if (!passenger) return res.status(404).json({ error: 'Passenger not found' });
        res.json(passenger);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function updatePassenger(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        const passenger = await Passenger.findOne({
            where: { id: req.params.passengerId, bookingId: req.params.bookingId },
        });
        if (!passenger) return res.status(404).json({ error: 'Passenger not found' });

        await passenger.update(req.body);
        res.json(passenger);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function deletePassenger(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        const passenger = await Passenger.findOne({
            where: { id: req.params.passengerId, bookingId: req.params.bookingId },
        });
        if (!passenger) return res.status(404).json({ error: 'Passenger not found' });

        await passenger.destroy();
        res.json({ message: 'Passenger removed' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = {
    upsertFlight,
    upsertHotel,
    upsertTransfer,
    addPassenger,
    listPassengers,
    getPassengerDetail,
    updatePassenger,
    deletePassenger,
};