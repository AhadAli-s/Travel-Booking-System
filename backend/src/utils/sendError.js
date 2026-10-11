/**
 * Central error responder. Validation problems become 400s with a readable
 * message. Anything unexpected is logged on the server and the client only
 * sees a generic message, so database internals never leak.
 */
function sendError(res, err) {
    if (err.name === 'SequelizeValidationError' || err.name === 'SequelizeUniqueConstraintError') {
        const message = err.errors?.map((e) => e.message).join(', ') || 'Invalid data';
        return res.status(400).json({ error: message });
    }
    if (err.name === 'SequelizeDatabaseError') {
        console.error(err);
        return res.status(400).json({ error: 'Invalid request data' });
    }
    console.error(err);
    return res.status(500).json({ error: 'Internal server error' });
}

module.exports = { sendError };