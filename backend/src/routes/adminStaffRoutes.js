const express = require('express');
const router = express.Router();
const controller = require('../controllers/staffController');
const { requireAuth, requireStaff, requireRole } = require('../middleware/auth');

// Administrator only
router.get('/', requireAuth, requireStaff, requireRole('Administrator'), controller.listStaff);
router.post('/', requireAuth, requireStaff, requireRole('Administrator'), controller.createStaff);
router.patch('/:id', requireAuth, requireStaff, requireRole('Administrator'), controller.updateStaff);

module.exports = router;