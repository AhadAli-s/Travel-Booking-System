const crypto = require('crypto');

/**
 * Generates a booking reference in the style real travel agencies use,
 * e.g. "TB-7F3K9Q". Uses crypto.randomInt so references cannot be predicted.
 * The caller still verifies uniqueness against the database
 * (see bookingController.js).
 */
function generateBookingReference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to avoid confusion
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars[crypto.randomInt(chars.length)];
    }
    return `TB-${code}`;
}

module.exports = { generateBookingReference };