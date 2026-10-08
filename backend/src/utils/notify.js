const { Notification } = require('../models/index');

/**
 * Creates an in-app notification for a customer.
 * Failures are logged but never thrown, so a notification problem
 * can never break the main action (recording a payment, uploading a document).
 */
async function notifyCustomer(customerId, type, message) {
    try {
        await Notification.create({ customerId, type, message });
    } catch (err) {
        console.error('Failed to create notification:', err.message);
    }
}

module.exports = { notifyCustomer };