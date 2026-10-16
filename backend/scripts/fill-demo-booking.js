/**
 * Fills a booking with realistic data the way agency staff would, so every
 * customer screen has something to show: flight, hotel, transfer, two passengers,
 * a 1000 deposit, a PDF confirmation, and status Confirmed.
 *
 *   node scripts/fill-demo-booking.js TB-ABC123
 *
 * Uses the seeded staff accounts. Override with AGENT_EMAIL, AGENT_PASSWORD,
 * ACCOUNTS_EMAIL and ACCOUNTS_PASSWORD in the environment if you changed them.
 */
require('dotenv').config();

const reference = (process.argv[2] || '').trim().toUpperCase();
if (!reference) {
    console.error('Usage: node scripts/fill-demo-booking.js <booking reference>');
    process.exit(1);
}

const BASE = `${process.env.API_URL || `http://localhost:${process.env.PORT || 5000}`}/api`;

async function call(method, path, { token, body, form } = {}) {
    const headers = {};
    if (token) headers.Authorization = `Bearer ${token}`;
    if (body !== undefined) headers['Content-Type'] = 'application/json';
    const res = await fetch(BASE + path, {
        method,
        headers,
        body: form || (body !== undefined ? JSON.stringify(body) : undefined),
    });
    const json = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(`${method} ${path} failed (${res.status}): ${json.error || 'unknown error'}`);
    return json;
}

/** Smallest valid one page PDF, with a correct cross reference table. */
function makePdf(lines) {
    const text = lines
        .map((line, i) => `BT /F1 ${i === 0 ? 20 : 12} Tf 60 ${760 - i * 26} Td (${line.replace(/[()\\]/g, '')}) Tj ET`)
        .join('\n');
    const objects = [
        '<< /Type /Catalog /Pages 2 0 R >>',
        '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
        '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
        `<< /Length ${Buffer.byteLength(text)} >>\nstream\n${text}\nendstream`,
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
    ];
    let pdf = '%PDF-1.4\n';
    const offsets = [];
    objects.forEach((obj, i) => {
        offsets.push(Buffer.byteLength(pdf));
        pdf += `${i + 1} 0 obj\n${obj}\nendobj\n`;
    });
    const xref = Buffer.byteLength(pdf);
    pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
    offsets.forEach((o) => { pdf += `${String(o).padStart(10, '0')} 00000 n \n`; });
    pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF\n`;
    return Buffer.from(pdf);
}

async function main() {
    const login = async (email, password) =>
        (await call('POST', '/auth/staff/login', { body: { email, password } })).token;

    const agent = await login(
        process.env.AGENT_EMAIL || 'agent@travelagency.com',
        process.env.AGENT_PASSWORD || 'Agent@123'
    );
    const accounts = await login(
        process.env.ACCOUNTS_EMAIL || 'accounts@travelagency.com',
        process.env.ACCOUNTS_PASSWORD || 'Accounts@123'
    );

    const all = await call('GET', '/bookings', { token: agent });
    const list = Array.isArray(all) ? all : all.bookings || [];
    const match = list.find((b) => b.bookingReference === reference);
    if (!match) throw new Error(`No booking with reference ${reference}`);
    const id = match.id;

    const booking = await call('GET', `/bookings/${id}`, { token: agent });
    const travel = String(booking.travelDate).slice(0, 10);
    const back = String(booking.returnDate).slice(0, 10);

    await call('PUT', `/bookings/${id}/flight`, {
        token: agent,
        body: {
            airline: 'Jet2',
            flightNumber: 'LS123',
            departureAirport: booking.departureAirport || 'MAN',
            arrivalAirport: 'AYT',
            departureTime: `${travel}T06:00:00Z`,
            arrivalTime: `${travel}T12:10:00Z`,
            returnFlightNumber: 'LS124',
            returnDepartureTime: `${back}T13:00:00Z`,
            returnArrivalTime: `${back}T17:10:00Z`,
            baggageAllowance: '1 x 22kg hold bag and 1 x 10kg cabin bag per adult',
        },
    });
    await call('PUT', `/bookings/${id}/hotel`, {
        token: agent,
        body: {
            hotelName: 'Sunrise Resort',
            hotelAddress: 'Lara Beach, Antalya, Turkey',
            roomType: 'Double room, sea view',
            numRooms: 1,
            boardBasis: 'All Inclusive',
            checkInDate: travel,
            checkOutDate: back,
            confirmationNumber: 'HC-99812',
        },
    });
    await call('PUT', `/bookings/${id}/transfer`, {
        token: agent,
        body: {
            pickupLocation: 'Antalya Airport (AYT)',
            pickupTime: `${travel}T12:45:00Z`,
            dropoffLocation: 'Sunrise Resort',
            transferStatus: 'Confirmed',
        },
    });

    const existing = await call('GET', `/bookings/${id}/passengers`, { token: agent });
    if (existing.length === 0) {
        const people = [
            { fullName: 'Demo Traveller One', dateOfBirth: '1990-04-12', passengerType: 'Adult', passportNumber: 'AB1234567', passportExpiry: '2031-04-11', mealPreference: 'Vegetarian', baggage: '22kg' },
            { fullName: 'Demo Traveller Two', dateOfBirth: '1992-09-30', passengerType: 'Adult', passportNumber: 'CD7654321', passportExpiry: '2030-09-29', specialAssistance: 'Wheelchair assistance at airport' },
        ];
        const slots = booking.numAdults + booking.numChildren + booking.numInfants;
        for (const person of people.slice(0, slots)) {
            await call('POST', `/bookings/${id}/passengers`, { token: agent, body: person });
        }
    }

    const form = new FormData();
    form.append('documentType', 'BookingConfirmation');
    form.append(
        'file',
        new Blob([makePdf(['Booking Confirmation', `Reference: ${reference}`, `Destination: ${booking.destination}`, 'Thank you for booking with us.'])], { type: 'application/pdf' }),
        `${reference}-confirmation.pdf`
    );
    await call('POST', `/bookings/${id}/documents`, { token: agent, form });

    await call('POST', `/bookings/${id}/payment`, { token: accounts, body: { amount: 1000, method: 'Card', note: 'Deposit' } });
    await call('PATCH', `/bookings/${id}/status`, { token: agent, body: { status: 'Confirmed' } });

    console.log(`Booking ${reference} now has flight, hotel, transfer, passengers, a document, a 1000 deposit and status Confirmed.`);
}

main().catch((err) => {
    console.error(err.message);
    process.exit(1);
});