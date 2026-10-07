const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const detailsController = require('../controllers/bookingDetailsController');
const { requireAuth, requireStaff, requireRole } = require('../middleware/auth');

// --- Public (no login — the "enter Booking Reference & Email" flow) ---
router.post('/lookup', bookingController.lookupBooking);

// --- Website integration simulation ---
// In production this should be protected by an API key shared only with the
// website's own backend, not a customer/staff JWT. Left open here to keep
// the simulation simple, since no real external website exists to call it.
router.post('/website-sync', bookingController.createBookingFromWebsite);

// --- Customer (logged in) ---
router.get('/my', requireAuth, bookingController.getMyBookings);

// --- Staff ---
router.get('/', requireAuth, requireStaff, bookingController.listAllBookings);
router.post('/', requireAuth, requireRole('Administrator', 'BookingAgent'), bookingController.createBookingByStaff);
router.patch('/:id', requireAuth, requireStaff, bookingController.updateBooking);
router.patch('/:id/status', requireAuth, requireStaff, bookingController.updateBookingStatus);
router.patch('/:id/assign', requireAuth, requireRole('Administrator', 'BookingAgent'), bookingController.assignStaff);

// --- Shared: get single booking (customer: own only; staff: any) ---
router.get('/:id', requireAuth, bookingController.getBookingById);

// --- Sub-resources: flight / hotel / transfer (staff manage these) ---
router.put('/:bookingId/flight', requireAuth, requireStaff, detailsController.upsertFlight);
router.put('/:bookingId/hotel', requireAuth, requireStaff, detailsController.upsertHotel);
router.put('/:bookingId/transfer', requireAuth, requireStaff, detailsController.upsertTransfer);

// --- Sub-resources: passengers ---
router.get('/:bookingId/passengers', requireAuth, detailsController.listPassengers);
router.post('/:bookingId/passengers', requireAuth, detailsController.addPassenger);
router.get('/:bookingId/passengers/:passengerId', requireAuth, detailsController.getPassengerDetail);
router.patch('/:bookingId/passengers/:passengerId', requireAuth, detailsController.updatePassenger);
router.delete('/:bookingId/passengers/:passengerId', requireAuth, detailsController.deletePassenger);

module.exports = router;