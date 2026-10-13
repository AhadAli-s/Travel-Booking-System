const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const multer = require('multer');
require('dotenv').config();

const REQUIRED_ENV = ['DB_NAME', 'DB_USER', 'DB_PASSWORD', 'JWT_SECRET', 'ENCRYPTION_KEY', 'WEBSITE_API_KEY'];
const missing = REQUIRED_ENV.filter((name) => !process.env[name]);
if (missing.length > 0) {
    console.error(`Missing required environment variables: ${missing.join(', ')}. See .env.example`);
    process.exit(1);
}

const { sequelize } = require('./models/index');
const { authLimiter, lookupLimiter } = require('./middleware/rateLimits');
const authRoutes = require('./routes/authRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const documentRoutes = require('./routes/documentRoutes');
const ticketRoutes = require('./routes/ticketRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const profileRoutes = require('./routes/profileRoutes');
const dashboardRoutes = require('./routes/dashboardRoutes');
const adminDashboardRoutes = require('./routes/adminDashboardRoutes');
const adminCustomerRoutes = require('./routes/adminCustomerRoutes');
const adminStaffRoutes = require('./routes/adminStaffRoutes');

const app = express();

app.use(helmet());
// CORS_ORIGIN is a comma separated list of allowed web origins. Mobile and desktop
// apps are not affected by CORS. When unset, every origin is allowed (development only).
app.use(cors({ origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(',') : true }));
app.use(express.json({ limit: '100kb' }));

app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', message: 'Travel Booking API is running' });
});

app.use('/api/auth', authLimiter, authRoutes);
app.use('/api/bookings/lookup', lookupLimiter);
app.use('/api/bookings/:bookingId/payment', paymentRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api', documentRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/admin/dashboard', adminDashboardRoutes);
app.use('/api/admin/customers', adminCustomerRoutes);
app.use('/api/admin/staff', adminStaffRoutes);

app.use('/api', (req, res) => {
    res.status(404).json({ error: 'Route not found' });
});

// Malformed JSON bodies and upload problems return clean JSON errors
app.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        return res.status(400).json({ error: `Upload error: ${err.message}` });
    }
    if (err.type === 'entity.parse.failed') {
        return res.status(400).json({ error: 'Request body is not valid JSON' });
    }
    if (err.type === 'entity.too.large') {
        return res.status(413).json({ error: 'Request body is too large' });
    }
    if (err.message === 'Only PDF, PNG, and JPEG files are allowed') {
        return res.status(400).json({ error: err.message });
    }
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
});

module.exports = app;

const PORT = process.env.PORT || 5000;

async function startServer() {
    try {
        await sequelize.authenticate();
        console.log('Database connection established successfully.');

        await sequelize.sync({ alter: true });
        console.log('All models synchronized with the database.');

        app.listen(PORT, () => {
            console.log(`Server running on http://localhost:${PORT}`);
        });
    } catch (error) {
        console.error('Unable to connect to the database:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    startServer();
}