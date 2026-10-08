const express = require('express');
const router = express.Router({ mergeParams: true });
const paymentController = require('../controllers/paymentController');
const { requireAuth, requireRole } = require('../middleware/auth');

// Customer (own booking) or staff
router.get('/', requireAuth, paymentController.getPayment);
router.get('/receipts/:receiptId', requireAuth, paymentController.getReceipt);

// Money-moving actions: Administrator and AccountsStaff only
router.post('/', requireAuth, requireRole('Administrator', 'AccountsStaff'), paymentController.recordPayment);
router.post('/refund', requireAuth, requireRole('Administrator', 'AccountsStaff'), paymentController.issueRefund);

module.exports = router;