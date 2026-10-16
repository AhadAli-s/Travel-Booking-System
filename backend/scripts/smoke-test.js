/**
 * End to end smoke test for the API. Run with the server already running:
 *   node scripts/smoke-test.js            (uses http://localhost:5000)
 *   API_URL=http://localhost:5055 WEBSITE_API_KEY=xxx node scripts/smoke-test.js
 * Needs the seeded staff accounts (npm run seed or node src/seed.js).
 */
require('dotenv').config();
const BASE = process.env.API_URL || `http://localhost:${process.env.PORT || 5000}`;
const WEBSITE_KEY = process.env.WEBSITE_API_KEY;
let passed = 0;
let failed = 0;

async function call(method, path, { token, body, headers = {}, form } = {}) {
    const opts = { method, headers: { ...headers } };
    if (token) opts.headers.Authorization = `Bearer ${token}`;
    if (form) {
        opts.body = form;
    } else if (body !== undefined) {
        opts.headers['Content-Type'] = 'application/json';
        opts.body = JSON.stringify(body);
    }
    const res = await fetch(BASE + path, opts);
    const text = await res.text();
    let json = null;
    try { json = JSON.parse(text); } catch (e) { /* binary or empty body */ }
    return { status: res.status, json, text };
}

function check(name, condition, detail = '') {
    if (condition) { passed++; console.log(`  PASS  ${name}`); }
    else { failed++; console.log(`  FAIL  ${name} ${detail}`); }
}

async function main() {
    const stamp = Date.now();
    const email = `Smoke.${stamp}@Example.com`; // mixed case on purpose
    console.log(`Testing ${BASE}\n`);

    const health = await call('GET', '/api/health');
    check('health endpoint', health.status === 200);

    console.log('\nStaff login and roles');
    const login = async (e, p) => (await call('POST', '/api/auth/staff/login', { body: { email: e, password: p } })).json?.token;
    const admin = await login('admin@travelagency.com', 'Admin@123');
    const agent = await login('agent@travelagency.com', 'Agent@123');
    const accounts = await login('accounts@travelagency.com', 'Accounts@123');
    const support = await login('support@travelagency.com', 'Support@123');
    check('all four seeded staff can log in', admin && agent && accounts && support);

    console.log('\nWebsite sync API key');
    const payload = {
        customerEmail: email, customerName: 'Smoke Tester', destination: 'Antalya, Turkey',
        departureCity: 'Manchester', departureAirport: 'MAN', travelDate: '2026-12-12', returnDate: '2026-12-19',
        numAdults: 2, numChildren: 0, numInfants: 0, totalPackagePrice: 2450, paymentDueDate: '2026-11-15',
    };
    check('no key is rejected', (await call('POST', '/api/bookings/website-sync', { body: payload })).status === 401);
    check('wrong key is rejected', (await call('POST', '/api/bookings/website-sync', { body: payload, headers: { 'x-api-key': 'nope' } })).status === 401);
    const sync = await call('POST', '/api/bookings/website-sync', { body: payload, headers: { 'x-api-key': WEBSITE_KEY } });
    check('valid key creates booking', sync.status === 201 && sync.json?.bookingReference, JSON.stringify(sync.json));
    const ref = sync.json?.bookingReference;
    const bookingId = sync.json?.bookingId;
    const bad = await call('POST', '/api/bookings/website-sync', { body: { ...payload, returnDate: '2026-12-01' }, headers: { 'x-api-key': WEBSITE_KEY } });
    check('return date before travel date is rejected', bad.status === 400);
    const second = await call('POST', '/api/bookings/website-sync', { body: payload, headers: { 'x-api-key': WEBSITE_KEY } });
    check('second booking for same email reuses the customer', second.status === 201);

    console.log('\nPublic lookup');
    const wrongEmail = await call('POST', '/api/bookings/lookup', { body: { bookingReference: ref, email: 'other@example.com' } });
    check('wrong email gives 404', wrongEmail.status === 404);
    const lookup = await call('POST', '/api/bookings/lookup', { body: { bookingReference: ref.toLowerCase(), email: email.toUpperCase() } });
    check('reference and email match ignoring case', lookup.status === 200 && lookup.json?.bookingReference === ref);

    console.log('\nCustomer account claim, reset token');
    const forgot = await call('POST', '/api/auth/forgot-password', { body: { email } });
    const resetToken = forgot.json?.devResetToken;
    check('forgot password returns a dev token outside production', !!resetToken);
    const reset = await call('POST', '/api/auth/reset-password', { body: { resetToken, newPassword: 'Smoke@12345' } });
    check('reset password works', reset.status === 200, JSON.stringify(reset.json));
    check('reset token cannot be reused', (await call('POST', '/api/auth/reset-password', { body: { resetToken, newPassword: 'Another@123' } })).status === 400);
    const cust = await call('POST', '/api/auth/login', { body: { email, password: 'Smoke@12345' } });
    const customer = cust.json?.token;
    check('customer can log in', !!customer);
    const mine = await call('GET', '/api/bookings/my', { token: customer });
    const mineCount = (mine.json?.upcoming?.length || 0) + (mine.json?.active?.length || 0);
    check('my bookings lists both website bookings', mineCount === 2, JSON.stringify(mine.json && Object.keys(mine.json)));

    console.log('\nMass assignment protection');
    const patch = await call('PATCH', `/api/bookings/${bookingId}`, { token: agent, body: { destination: 'Dalaman, Turkey', status: 'Closed', customerId: 1, bookingReference: 'HACKED', travelDate: '2026-12-13' } });
    check('allowed fields change', patch.status === 200 && patch.json?.destination === 'Dalaman, Turkey' && patch.json?.numNights === 6, JSON.stringify(patch.json));
    check('status and reference are ignored', patch.json?.status === 'Pending' && patch.json?.bookingReference === ref);
    check('accounts staff cannot edit bookings', (await call('PATCH', `/api/bookings/${bookingId}`, { token: accounts, body: { notes: 'x' } })).status === 403);
    check('support agent cannot change booking status', (await call('PATCH', `/api/bookings/${bookingId}/status`, { token: support, body: { status: 'Confirmed' } })).status === 403);
    check('invalid status is rejected', (await call('PATCH', `/api/bookings/${bookingId}/status`, { token: agent, body: { status: 'Bogus' } })).status === 400);
    check('agent can confirm booking', (await call('PATCH', `/api/bookings/${bookingId}/status`, { token: agent, body: { status: 'Confirmed' } })).status === 200);

    console.log('\nFlight, hotel, validation errors');
    const flightBad = await call('PUT', `/api/bookings/${bookingId}/flight`, { token: agent, body: { airline: 'Only airline' } });
    check('incomplete flight gives 400, not 500', flightBad.status === 400, JSON.stringify(flightBad.json));
    const flightOk = await call('PUT', `/api/bookings/${bookingId}/flight`, { token: agent, body: { airline: 'Jet2', flightNumber: 'LS123', departureAirport: 'MAN', arrivalAirport: 'AYT', departureTime: '2026-12-13T06:00:00Z', arrivalTime: '2026-12-13T12:00:00Z', id: 999 } });
    check('flight saved', flightOk.status === 200 && flightOk.json?.id !== 999, JSON.stringify(flightOk.json));

    console.log('\nPassengers and passport encryption');
    const p1 = await call('POST', `/api/bookings/${bookingId}/passengers`, { token: customer, body: { fullName: 'Smoke Tester', dateOfBirth: '1990-01-01', passengerType: 'Adult', passportNumber: 'AB1234567', passportExpiry: '2030-01-01' } });
    check('customer adds passenger', p1.status === 201, JSON.stringify(p1.json));
    const p2 = await call('POST', `/api/bookings/${bookingId}/passengers`, { token: customer, body: { fullName: 'Second Tester', dateOfBirth: '1991-01-01', passengerType: 'Adult' } });
    check('second passenger within limit', p2.status === 201);
    const p3 = await call('POST', `/api/bookings/${bookingId}/passengers`, { token: customer, body: { fullName: 'Third', dateOfBirth: '1992-01-01', passengerType: 'Adult' } });
    check('third passenger beyond 2 travellers is rejected', p3.status === 400);
    const list = await call('GET', `/api/bookings/${bookingId}/passengers`, { token: customer });
    check('list hides passport number', list.status === 200 && !JSON.stringify(list.json).includes('AB1234567'));
    const detail = await call('GET', `/api/bookings/${bookingId}/passengers/${p1.json?.id}`, { token: customer });
    check('detail returns decrypted passport number', detail.json?.passportNumber === 'AB1234567', JSON.stringify(detail.json));
    const full = await call('GET', `/api/bookings/${bookingId}`, { token: customer });
    check('booking detail hides passport number', !JSON.stringify(full.json).includes('AB1234567'));
    if (process.env.DB_NAME) {
        const { sequelize } = require('../src/models/index');
        const [rows] = await sequelize.query(`SELECT "passportNumber" FROM passengers WHERE id = ${Number(p1.json?.id)}`);
        check('passport number is encrypted in the database', rows[0]?.passportNumber?.startsWith('enc:'), rows[0]?.passportNumber);
        await sequelize.close();
    }

    console.log('\nPayments by role');
    check('support agent cannot record payment', (await call('POST', `/api/bookings/${bookingId}/payment`, { token: support, body: { amount: 100, method: 'Card' } })).status === 403);
    const pay = await call('POST', `/api/bookings/${bookingId}/payment`, { token: accounts, body: { amount: 1000, method: 'Card' } });
    check('accounts staff records 1000 deposit', pay.status === 201 || pay.status === 200, JSON.stringify(pay.json));
    const summary = await call('GET', `/api/bookings/${bookingId}/payment`, { token: customer });
    check('customer sees 1450 remaining', summary.json?.remainingBalance === 1450, JSON.stringify(summary.json));
    check('overpayment rejected', (await call('POST', `/api/bookings/${bookingId}/payment`, { token: accounts, body: { amount: 5000 } })).status === 400);

    console.log('\nDocuments');
    const form = new FormData();
    form.append('documentType', 'Invoice');
    form.append('file', new Blob(['%PDF-1.4 smoke'], { type: 'application/pdf' }), 'invoice.pdf');
    const up = await call('POST', `/api/bookings/${bookingId}/documents`, { token: agent, form });
    check('booking agent uploads a document', up.status === 201, JSON.stringify(up.json));
    const dl = await call('GET', `/api/documents/${up.json?.id}/download`, { token: customer });
    check('owner downloads it', dl.status === 200 && dl.text.includes('smoke'));
    const link = await call('GET', `/api/documents/${up.json?.id}/link`, { token: customer });
    check('owner gets a short lived download link', link.status === 200 && link.json?.url?.includes('?t='), JSON.stringify(link.json));
    const viaLink = await fetch(BASE + link.json?.url);
    check('link downloads the file without an Authorization header', viaLink.status === 200 && (await viaLink.text()).includes('smoke'));
    check('link is tied to one document', (await fetch(BASE + link.json?.url.replace(`/documents/${up.json?.id}/`, `/documents/${Number(up.json?.id) + 1000}/`))).status === 401);
    check('link token cannot be used as a login token', (await call('GET', '/api/bookings/my', { token: link.json?.url.split('?t=')[1] })).status === 401);
    check('tampered link is rejected', (await fetch(BASE + link.json?.url + 'x')).status === 401);
    check('support agent cannot upload documents', (await call('POST', `/api/bookings/${bookingId}/documents`, { token: support, form })).status === 403);

    console.log('\nTickets');
    const t = await call('POST', '/api/tickets', { token: customer, body: { category: 'Hotel', subject: 'Smoke ticket', description: 'Testing', bookingId } });
    check('customer opens ticket', t.status === 201);
    check('staff reply works', (await call('POST', `/api/tickets/${t.json?.id}/replies`, { token: support, body: { message: 'Hello' } })).status === 201);
    check('empty reply rejected', (await call('POST', `/api/tickets/${t.json?.id}/replies`, { token: support, body: { message: '   ' } })).status === 400);
    check('accounts staff cannot change ticket status', (await call('PATCH', `/api/tickets/${t.json?.id}/status`, { token: accounts, body: { status: 'Resolved' } })).status === 403);
    check('support agent resolves ticket', (await call('PATCH', `/api/tickets/${t.json?.id}/status`, { token: support, body: { status: 'Resolved' } })).status === 200);

    console.log('\nCustomer management');
    const custList = await call('GET', `/api/admin/customers?search=${encodeURIComponent('smoke')}`, { token: support });
    check('staff searches customers', custList.status === 200 && custList.json?.customers?.length >= 1 && custList.json.customers[0].totalBookings === 2, JSON.stringify(custList.json));
    check('customer list never exposes password data', !JSON.stringify(custList.json).includes('passwordHash'));
    const custId = custList.json?.customers?.[0]?.id;
    const note = await call('POST', `/api/admin/customers/${custId}/notes`, { token: agent, body: { note: 'Called about transfer', channel: 'Phone', bookingId } });
    check('staff adds contact note', note.status === 201, JSON.stringify(note.json));
    const det = await call('GET', `/api/admin/customers/${custId}`, { token: accounts });
    check('customer detail has bookings, tickets and history', det.json?.bookings?.length === 2 && det.json?.tickets?.length === 1 && det.json?.contactHistory?.length === 1, JSON.stringify(det.json && Object.keys(det.json)));
    check('customer token cannot use admin customer routes', (await call('GET', '/api/admin/customers', { token: customer })).status === 403);

    console.log('\nStaff management');
    check('booking agent cannot list staff', (await call('GET', '/api/admin/staff', { token: agent })).status === 403);
    const newStaff = await call('POST', '/api/admin/staff', { token: admin, body: { fullName: 'Temp Agent', email: `temp${stamp}@travelagency.com`, password: 'Temp@12345', role: 'BookingAgent' } });
    check('administrator creates staff', newStaff.status === 201 && !newStaff.json?.passwordHash, JSON.stringify(newStaff.json));
    check('duplicate staff email rejected', (await call('POST', '/api/admin/staff', { token: admin, body: { fullName: 'Temp Agent', email: `temp${stamp}@travelagency.com`, password: 'Temp@12345', role: 'BookingAgent' } })).status === 409);
    const tempToken = await login(`temp${stamp}@travelagency.com`, 'Temp@12345');
    check('new staff can log in', !!tempToken);
    const adminList = await call('GET', '/api/admin/staff', { token: admin });
    const adminSelf = adminList.json?.find((s) => s.email === 'admin@travelagency.com');
    check('administrator cannot deactivate self', (await call('PATCH', `/api/admin/staff/${adminSelf?.id}`, { token: admin, body: { status: 'Inactive' } })).status === 400);
    check('administrator deactivates temp staff', (await call('PATCH', `/api/admin/staff/${newStaff.json?.id}`, { token: admin, body: { status: 'Inactive' } })).status === 200);
    check('deactivated staff token stops working immediately', (await call('GET', '/api/bookings', { token: tempToken })).status === 401);
    check('deactivated staff cannot log in', !(await login(`temp${stamp}@travelagency.com`, 'Temp@12345')));

    console.log('\nDashboards');
    check('customer dashboard', (await call('GET', '/api/dashboard', { token: customer })).status === 200);
    check('admin dashboard', (await call('GET', '/api/admin/dashboard', { token: admin })).status === 200);

    console.log('\nRate limit on public lookup');
    let limited = false;
    for (let i = 0; i < 25 && !limited; i++) {
        limited = (await call('POST', '/api/bookings/lookup', { body: { bookingReference: 'TB-AAAAAA', email: 'x@example.com' } })).status === 429;
    }
    check('lookup is rate limited', limited);

    console.log(`\n${passed} passed, ${failed} failed`);
    process.exit(failed ? 1 : 0);
}

main().catch((err) => { console.error(err); process.exit(1); });