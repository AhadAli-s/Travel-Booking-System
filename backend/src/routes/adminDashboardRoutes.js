const express = require('express');
const router = express.Router();
const adminDashboardController = require('../controllers/adminDashboardController');
const { requireAuth, requireStaff } = require('../middleware/auth');

router.get('/', requireAuth, requireStaff, adminDashboardController.getAdminDashboard);

module.exports = router;
