const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const { requireAuth, requireCustomer } = require('../middleware/auth');

router.get('/', requireAuth, requireCustomer, notificationController.listNotifications);
router.get('/unread-count', requireAuth, requireCustomer, notificationController.getUnreadCount);
router.patch('/read-all', requireAuth, requireCustomer, notificationController.markAllAsRead);
router.patch('/:id/read', requireAuth, requireCustomer, notificationController.markAsRead);

module.exports = router;
