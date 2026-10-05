/**
 * Generates a booking reference in the style real travel agencies use,
 * e.g. "TB-7F3K9Q". Collision risk is negligible at this scale, but the
 * caller should still verify uniqueness against the database before saving
 * (see bookingController.js).
 */
function generateBookingReference() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I to avoid confusion
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars[Math.floor(Math.random() * chars.length)];
    }
    return `TB-${code}`;
}

module.exports = { generateBookingReference };