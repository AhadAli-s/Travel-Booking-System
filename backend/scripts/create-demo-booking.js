/**
 * Simulates the travel agency website pushing a booking into the system.
 * Reads WEBSITE_API_KEY and PORT from backend/.env, so nothing secret is typed or printed.
 *
 *   node scripts/create-demo-booking.js you@example.com "Your Name" "Antalya, Turkey"
 *
 * Trip starts in 14 days, lasts 7 nights, package price 2450, payment due in 10 days.
 */
require('dotenv').config();

const [email, name = 'Demo Customer', destination = 'Antalya, Turkey'] = process.argv.slice(2);
if (!email) {
    console.error('Usage: node scripts/create-demo-booking.js <customer email> ["Customer Name"] ["Destination"]');
    process.exit(1);
}
if (!process.env.WEBSITE_API_KEY) {
    console.error('WEBSITE_API_KEY is missing from backend/.env');
    process.exit(1);
}

function isoDate(daysFromToday) {
    const d = new Date();
    d.setDate(d.getDate() + daysFromToday);
    return d.toISOString().slice(0, 10);
}

const base = process.env.API_URL || `http://localhost:${process.env.PORT || 5000}`;

fetch(`${base}/api/bookings/website-sync`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-api-key': process.env.WEBSITE_API_KEY },
    body: JSON.stringify({
        customerEmail: email,
        customerName: name,
        destination,
        departureCity: 'Manchester',
        departureAirport: 'MAN',
        travelDate: isoDate(14),
        returnDate: isoDate(21),
        numAdults: 2,
        numChildren: 0,
        numInfants: 0,
        totalPackagePrice: 2450,
        paymentDueDate: isoDate(10),
    }),
})
    .then(async (res) => {
        const body = await res.json();
        if (!res.ok) {
            console.error(`Failed (${res.status}):`, body.error);
            process.exit(1);
        }
        console.log(`Booking created: ${body.bookingReference} for ${email}`);
    })
    .catch((err) => {
        console.error(`Cannot reach the API at ${base}. Is the server running? (${err.message})`);
        process.exit(1);
    });