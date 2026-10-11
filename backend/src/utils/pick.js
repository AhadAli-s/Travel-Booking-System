/**
 * Returns a new object containing only the listed keys from source.
 * Used to whitelist request body fields so clients can never set
 * columns they should not control (status, customerId, bookingReference).
 */
function pick(source, keys) {
    const result = {};
    if (!source || typeof source !== 'object') return result;
    for (const key of keys) {
        if (Object.prototype.hasOwnProperty.call(source, key) && source[key] !== undefined) {
            result[key] = source[key];
        }
    }
    return result;
}

module.exports = { pick };