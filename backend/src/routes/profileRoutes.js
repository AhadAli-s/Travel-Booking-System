const express = require('express');
const router = express.Router();
const profileController = require('../controllers/profileController');
const { requireAuth, requireCustomer } = require('../middleware/auth');

router.get('/', requireAuth, requireCustomer, profileController.getProfile);
router.patch('/', requireAuth, requireCustomer, profileController.updateProfile);

module.exports = router;
