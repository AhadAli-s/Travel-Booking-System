const { Notification } = require('../models/index');

/** Customer's in-app notifications, newest first. */
async function listNotifications(req, res) {
    try {
        const notifications = await Notification.findAll({
            where: { customerId: req.user.id },
            order: [['createdAt', 'DESC']],
        });
        res.json(notifications);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function getUnreadCount(req, res) {
    try {
        const unreadCount = await Notification.count({
            where: { customerId: req.user.id, isRead: false },
        });
        res.json({ unreadCount });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function markAsRead(req, res) {
    try {
        const notification = await Notification.findByPk(req.params.id);
        if (!notification || notification.customerId !== req.user.id) {
            return res.status(404).json({ error: 'Notification not found' });
        }

        notification.isRead = true;
        await notification.save();
        res.json(notification);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

async function markAllAsRead(req, res) {
    try {
        await Notification.update(
            { isRead: true },
            { where: { customerId: req.user.id, isRead: false } }
        );
        res.json({ message: 'All notifications marked as read' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
}

module.exports = { listNotifications, getUnreadCount, markAsRead, markAllAsRead };
