const express = require('express');
const router = express.Router();
const documentController = require('../controllers/documentController');
const { requireAuth, requireStaff, requireRole } = require('../middleware/auth');

// Administrator, BookingAgent and AccountsStaff (invoices, receipts) manage documents
const documentStaff = requireRole('Administrator', 'BookingAgent', 'AccountsStaff');

// Booking-scoped
router.get('/bookings/:bookingId/documents', requireAuth, documentController.listDocuments);
router.post(
    '/bookings/:bookingId/documents',
    requireAuth,
    requireStaff,
    documentStaff,
    documentController.upload.single('file'),
    documentController.uploadDocument
);

// Document-scoped
router.get('/documents/:id/link', requireAuth, documentController.createDocumentLink);
router.get('/documents/:id/download', documentController.authenticateDownload, documentController.downloadDocument);
router.delete('/documents/:id', requireAuth, requireStaff, documentStaff, documentController.deleteDocument);

module.exports = router;