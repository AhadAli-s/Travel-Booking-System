const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { sequelize } = require('./models/index');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', message: 'Travel Booking API is running' });
});

const PORT = process.env.PORT || 5000;

async function startServer() {
    try {
        await sequelize.authenticate();
        console.log('Database connection established successfully.');

        // Creates all 13 tables (and their foreign keys) if they don't exist yet.
        // alter: true lets Sequelize adjust existing tables to match the models
        // during development, without needing a full migration tool yet.
        await sequelize.sync({ alter: true });
        console.log('All models synchronized with the database.');

        app.listen(PORT, () => {
            console.log(`Server running on http://localhost:${PORT}`);
        });
    } catch (error) {
        console.error('Unable to connect to the database:', error);
        process.exit(1);
    }
}

startServer();