const express = require('express');
const router = express.Router();
const controller = require('../controllers/customerAdminController');
const { requireAuth, requireStaff } = require('../middleware/auth');

// Every staff role can view customers and add contact notes
router.get('/', requireAuth, requireStaff, controller.listCustomers);
router.get('/:id', requireAuth, requireStaff, controller.getCustomer);
router.post('/:id/notes', requireAuth, requireStaff, controller.addContactNote);

module.exports = router;