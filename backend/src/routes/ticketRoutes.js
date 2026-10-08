const express = require('express');
const router = express.Router();
const ticketController = require('../controllers/ticketController');
const { requireAuth, requireStaff } = require('../middleware/auth');

// Customer
router.post('/', requireAuth, ticketController.createTicket);
router.get('/my', requireAuth, ticketController.getMyTickets);

// Staff dashboard
router.get('/', requireAuth, requireStaff, ticketController.listAllTickets);

// Shared (customer: own only, staff: any)
router.get('/:id', requireAuth, ticketController.getTicket);
router.post('/:id/replies', requireAuth, ticketController.addReply);

// Staff actions
router.patch('/:id/status', requireAuth, requireStaff, ticketController.updateTicketStatus);
router.patch('/:id/assign', requireAuth, requireStaff, ticketController.assignTicket);

module.exports = router;