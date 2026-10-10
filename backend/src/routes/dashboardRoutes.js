const express = require('express');
const router = express.Router();
const dashboardController = require('../controllers/dashboardController');
const { requireAuth, requireCustomer } = require('../middleware/auth');

router.get('/', requireAuth, requireCustomer, dashboardController.getCustomerDashboard);

module.exports = router;
