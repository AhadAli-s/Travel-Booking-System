const { Booking, Flight, Hotel, Transfer, Passenger } = require('../models/index');
const { pick } = require('../utils/pick');
const { sendError } = require('../utils/sendError');

const FLIGHT_FIELDS = [
    'airline', 'flightNumber', 'departureAirport', 'arrivalAirport', 'departureTime', 'arrivalTime',
    'returnFlightNumber', 'returnDepartureTime', 'returnArrivalTime', 'baggageAllowance',
];
const HOTEL_FIELDS = [
    'hotelName', 'hotelAddress', 'roomType', 'numRooms', 'boardBasis',
    'checkInDate', 'checkOutDate', 'confirmationNumber',
];
const TRANSFER_FIELDS = ['pickupLocation', 'pickupTime', 'dropoffLocation', 'transferStatus'];
const PASSENGER_FIELDS = [
    'fullName', 'dateOfBirth', 'passengerType', 'passportNumber', 'passportExpiry',
    'specialAssistance', 'mealPreference', 'baggage',
];

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
            await flight.update(pick(req.body, FLIGHT_FIELDS));
        } else {
            flight = await Flight.create({ ...pick(req.body, FLIGHT_FIELDS), bookingId: booking.id });
        }
        res.json(flight);
    } catch (err) {
        sendError(res, err);
    }
}

// ---------- HOTEL (one per booking) ----------
async function upsertHotel(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        let hotel = await Hotel.findOne({ where: { bookingId: booking.id } });
        if (hotel) {
            await hotel.update(pick(req.body, HOTEL_FIELDS));
        } else {
            hotel = await Hotel.create({ ...pick(req.body, HOTEL_FIELDS), bookingId: booking.id });
        }
        res.json(hotel);
    } catch (err) {
        sendError(res, err);
    }
}

// ---------- TRANSFER (one per booking) ----------
async function upsertTransfer(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        let transfer = await Transfer.findOne({ where: { bookingId: booking.id } });
        if (transfer) {
            await transfer.update(pick(req.body, TRANSFER_FIELDS));
        } else {
            transfer = await Transfer.create({ ...pick(req.body, TRANSFER_FIELDS), bookingId: booking.id });
        }
        res.json(transfer);
    } catch (err) {
        sendError(res, err);
    }
}

// ---------- PASSENGERS (many per booking) ----------
async function addPassenger(req, res) {
    try {
        const booking = await findBookingOr404(req, res);
        if (!booking) return;

        const allowed = Math.max(booking.numAdults + booking.numChildren + booking.numInfants, 1);
        const existing = await Passenger.count({ where: { bookingId: booking.id } });
        if (existing >= allowed) {
            return res.status(400).json({ error: `This booking has ${allowed} traveller(s); no more passengers can be added` });
        }

        const passenger = await Passenger.create({ ...pick(req.body, PASSENGER_FIELDS), bookingId: booking.id });
        res.status(201).json(passenger);
    } catch (err) {
        sendError(res, err);
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
        sendError(res, err);
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
        sendError(res, err);
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

        await passenger.update(pick(req.body, PASSENGER_FIELDS));
        res.json(passenger);
    } catch (err) {
        sendError(res, err);
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
        sendError(res, err);
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