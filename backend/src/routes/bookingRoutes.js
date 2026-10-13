const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const detailsController = require('../controllers/bookingDetailsController');
const { requireAuth, requireCustomer, requireStaff, requireRole } = require('../middleware/auth');
const { requireApiKey } = require('../middleware/apiKey');

// Staff roles allowed to change bookings and their flight/hotel/transfer details
const bookingEditors = requireRole('Administrator', 'BookingAgent');

// --- Public (no login: the "enter Booking Reference & Email" flow). Rate limited in server.js ---
router.post('/lookup', bookingController.lookupBooking);

// --- Website integration: only the agency website, identified by x-api-key ---
router.post('/website-sync', requireApiKey, bookingController.createBookingFromWebsite);

// --- Customer (logged in) ---
router.get('/my', requireAuth, requireCustomer, bookingController.getMyBookings);

// --- Staff: every role can view, only Administrator and BookingAgent can change ---
router.get('/', requireAuth, requireStaff, bookingController.listAllBookings);
router.post('/', requireAuth, requireStaff, bookingEditors, bookingController.createBookingByStaff);
router.patch('/:id', requireAuth, requireStaff, bookingEditors, bookingController.updateBooking);
router.patch('/:id/status', requireAuth, requireStaff, bookingEditors, bookingController.updateBookingStatus);
router.patch('/:id/assign', requireAuth, requireStaff, bookingEditors, bookingController.assignStaff);

// --- Shared: get single booking (customer: own only; staff: any) ---
router.get('/:id', requireAuth, bookingController.getBookingById);

// --- Sub-resources: flight / hotel / transfer (staff manage these) ---
router.put('/:bookingId/flight', requireAuth, requireStaff, bookingEditors, detailsController.upsertFlight);
router.put('/:bookingId/hotel', requireAuth, requireStaff, bookingEditors, detailsController.upsertHotel);
router.put('/:bookingId/transfer', requireAuth, requireStaff, bookingEditors, detailsController.upsertTransfer);

// --- Sub-resources: passengers (customer: own booking only; staff: any) ---
router.get('/:bookingId/passengers', requireAuth, detailsController.listPassengers);
router.post('/:bookingId/passengers', requireAuth, detailsController.addPassenger);
router.get('/:bookingId/passengers/:passengerId', requireAuth, detailsController.getPassengerDetail);
router.patch('/:bookingId/passengers/:passengerId', requireAuth, detailsController.updatePassenger);
router.delete('/:bookingId/passengers/:passengerId', requireAuth, detailsController.deletePassenger);

module.exports = router;