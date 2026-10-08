const express = require('express');
const router = express.Router();
const documentController = require('../controllers/documentController');
const { requireAuth, requireStaff } = require('../middleware/auth');

// Booking-scoped
router.get('/bookings/:bookingId/documents', requireAuth, documentController.listDocuments);
router.post(
    '/bookings/:bookingId/documents',
    requireAuth,
    requireStaff,
    documentController.upload.single('file'),
    documentController.uploadDocument
);

// Document-scoped
router.get('/documents/:id/download', requireAuth, documentController.downloadDocument);
router.delete('/documents/:id', requireAuth, requireStaff, documentController.deleteDocument);

module.exports = router;