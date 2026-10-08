const bcrypt = require('bcrypt');
const { sequelize, Staff } = require('./models/index');

const DEFAULT_STAFF = [
    { fullName: 'System Administrator', email: 'admin@travelagency.com', role: 'Administrator', password: 'Admin@123' },
    { fullName: 'Booking Agent', email: 'agent@travelagency.com', role: 'BookingAgent', password: 'Agent@123' },
    { fullName: 'Accounts Staff', email: 'accounts@travelagency.com', role: 'AccountsStaff', password: 'Accounts@123' },
    { fullName: 'Support Agent', email: 'support@travelagency.com', role: 'SupportAgent', password: 'Support@123' },
];

async function seed() {
    try {
        await sequelize.authenticate();
        await sequelize.sync({ alter: true });

        for (const entry of DEFAULT_STAFF) {
            const existing = await Staff.findOne({ where: { email: entry.email } });
            if (existing) {
                console.log(`Skipped (already exists): ${entry.email}`);
                continue;
            }
            const passwordHash = await bcrypt.hash(entry.password, 10);
            await Staff.create({
                fullName: entry.fullName,
                email: entry.email,
                passwordHash,
                role: entry.role,
                status: 'Active',
            });
            console.log(`Created ${entry.role}: ${entry.email}`);
        }

        console.log('Seeding complete.');
        process.exit(0);
    } catch (err) {
        console.error('Seeding failed:', err);
        process.exit(1);
    }
}

seed();