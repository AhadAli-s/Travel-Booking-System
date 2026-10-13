# Travel Booking API reference

Base URL: `http://localhost:5000/api`
Auth: `Authorization: Bearer <token>` on every route except those marked Public.
All bodies are JSON unless noted. Errors are always `{ "error": "message" }`.
Money fields inside booking objects arrive as strings (`"2450.00"`), so parse them in the app.
Dates are `YYYY-MM-DD`. Date times are ISO 8601.

Status codes: 400 validation, 401 missing, invalid or inactive token, 403 wrong role or not your data, 404 not found, 409 duplicate, 429 rate limited.

## Roles

| Role | Can do |
|---|---|
| Customer | Own bookings, payments view, documents, passengers, tickets, notifications, profile |
| Administrator | Everything, including staff management |
| BookingAgent | Create and edit bookings, status, assignment, flight, hotel, transfer, documents |
| AccountsStaff | Record payments and refunds, upload documents, view bookings and customers |
| SupportAgent | Change ticket status and assignment, reply to tickets, view bookings and customers |

Every staff role can view bookings, customers, tickets and the admin dashboard, reply to tickets and add contact notes.

## Enums

Booking status: Pending, Processing, AwaitingPayment, PaymentReceived, Confirmed, DocumentsPending, DocumentsIssued, ReadyToTravel, TravelCompleted, Cancelled, Closed
Payment status: Unpaid, PartiallyPaid, FullyPaid, Refunded
Ticket status: Open, InProgress, WaitingForCustomer, Resolved, Closed
Ticket category: Flight, Hotel, Payment, Transfer, Document, PassengerDetails, CancellationRequest, GeneralSupport
Document type: BookingConfirmation, FlightTickets, HotelVoucher, TransferVoucher, TravelInsurance, VisaDocuments, ATOLCertificate, Invoice, PaymentReceipt
Passenger type: Adult, Child, Infant
Transfer status: Pending, Confirmed, Completed, Cancelled
Contact channel: Phone, Email, InApp, InPerson, Other
Staff role: Administrator, BookingAgent, AccountsStaff, SupportAgent. Staff status: Active, Inactive

## Auth (rate limited, 100 requests per 15 min per IP)

| Method and path | Body | Response |
|---|---|---|
| POST /auth/register (Public) | fullName, email, password (min 8), phone? | 201 `{ token, customer:{id,fullName,email} }` |
| POST /auth/login (Public) | email, password | `{ token, customer }` |
| POST /auth/staff/login (Public) | email, password | `{ token, staff:{id,fullName,email,role} }` |
| POST /auth/logout | none | `{ message }` (app deletes its stored token) |
| POST /auth/forgot-password (Public) | email | `{ message, devResetToken? }` (token only outside production) |
| POST /auth/reset-password (Public) | resetToken, newPassword | `{ message }` |

Customer tokens last 7 days, staff tokens 12 hours. A staff token stops working at once if the account is deactivated.

## Public booking access

| Method and path | Notes |
|---|---|
| POST /bookings/lookup | Body `{ bookingReference, email }`. Returns the full booking. Rate limited to 20 per 15 min. Reference and email are case insensitive |
| POST /bookings/website-sync | Header `x-api-key: <WEBSITE_API_KEY>`. Body: customerEmail, customerName?, destination, departureCity?, departureAirport?, travelDate, returnDate, numAdults?, numChildren?, numInfants?, totalPackagePrice, paymentDueDate?. Returns 201 `{ bookingReference, bookingId }` |

## Customer

| Method and path | Response |
|---|---|
| GET /dashboard | `{ upcomingTrip:{bookingId,bookingReference,destination,departureCity,travelDate,returnDate,status,daysUntilTravel} or null, payment:{totalPackagePrice,amountPaid,remainingBalance,paymentDueDate,paymentStatus}, documents:{available}, support:{activeTickets} }` |
| GET /bookings/my | `{ upcoming:[], active:[], previous:[] }` of bookings, each with `Payment` |
| GET /bookings/:id | Full booking (own only): Flight, Hotel, Transfer, Payment, Passengers (no passport), Documents, Customer, assignedStaff |
| GET /bookings/:bookingId/payment | `{ totalPackagePrice, amountPaid, remainingBalance, paymentDueDate, paymentStatus, history:[{id,amount,paymentDate,method,note}] }` (numbers) |
| GET /bookings/:bookingId/payment/receipts/:receiptId | Receipt for one payment history entry |
| GET /bookings/:bookingId/documents | `[{id,documentType,fileName,uploadedAt}]` |
| GET /documents/:id/download | File bytes. Send the Authorization header, so save the bytes in the app instead of opening a plain link |
| GET /bookings/:bookingId/passengers | List without passport fields |
| GET /bookings/:bookingId/passengers/:passengerId | Detail including passportNumber and passportExpiry |
| POST /bookings/:bookingId/passengers | fullName, dateOfBirth, passengerType, passportNumber?, passportExpiry?, specialAssistance?, mealPreference?, baggage?. Limited to the number of travellers on the booking |
| PATCH /bookings/:bookingId/passengers/:passengerId | Same fields, all optional |
| DELETE /bookings/:bookingId/passengers/:passengerId | `{ message }` |
| POST /tickets | category, subject, description, bookingId? |
| GET /tickets/my | List |
| GET /tickets/:id | Ticket plus `replies:[{senderType:'Customer'|'Staff',message,createdAt}]` |
| POST /tickets/:id/replies | message (max 5000) |
| GET /notifications | `[{id,type,message,isRead,createdAt}]` newest first |
| GET /notifications/unread-count | `{ unreadCount }` |
| PATCH /notifications/:id/read, PATCH /notifications/read-all | |
| GET /profile, PATCH /profile | `{id,fullName,email,phone,createdAt}` |

## Staff: bookings

| Method and path | Roles | Notes |
|---|---|---|
| GET /bookings?status= | any staff | Each item has Customer, assignedStaff, Payment |
| POST /bookings | Administrator, BookingAgent | customerId, destination, travelDate, returnDate, totalPackagePrice, numAdults?, numChildren?, numInfants?, departureCity?, departureAirport?, paymentDueDate?, notes? |
| PATCH /bookings/:id | Administrator, BookingAgent | Only destination, departureCity, departureAirport, travelDate, returnDate, numAdults, numChildren, numInfants, notes. Other fields are ignored |
| PATCH /bookings/:id/status | Administrator, BookingAgent | `{ status }`. Notifies the customer |
| PATCH /bookings/:id/assign | Administrator, BookingAgent | `{ staffId }` or null to unassign |
| PUT /bookings/:bookingId/flight | Administrator, BookingAgent | airline, flightNumber, departureAirport, arrivalAirport, departureTime, arrivalTime required. returnFlightNumber, returnDepartureTime, returnArrivalTime, baggageAllowance optional |
| PUT /bookings/:bookingId/hotel | Administrator, BookingAgent | hotelName, checkInDate, checkOutDate required. hotelAddress, roomType, numRooms, boardBasis, confirmationNumber optional |
| PUT /bookings/:bookingId/transfer | Administrator, BookingAgent | pickupLocation, pickupTime, dropoffLocation, transferStatus |
| POST /bookings/:bookingId/documents | Administrator, BookingAgent, AccountsStaff | multipart: documentType, file (PDF, PNG, JPEG, max 10 MB). Notifies the customer |
| DELETE /documents/:id | Administrator, BookingAgent, AccountsStaff | |

## Staff: payments

| Method and path | Roles | Notes |
|---|---|---|
| POST /bookings/:bookingId/payment | Administrator, AccountsStaff | `{ amount, method?, note? }`. Cannot exceed the remaining balance |
| POST /bookings/:bookingId/payment/refund | Administrator, AccountsStaff | Refund entry |

## Staff: tickets

| Method and path | Roles |
|---|---|
| GET /tickets?status= | any staff |
| POST /tickets/:id/replies | any staff (staff reply sets WaitingForCustomer) |
| PATCH /tickets/:id/status | Administrator, SupportAgent. `{ status }` |
| PATCH /tickets/:id/assign | Administrator, SupportAgent. `{ staffId }` |

## Staff: dashboard, customers, staff accounts

| Method and path | Roles | Response |
|---|---|---|
| GET /admin/dashboard | any staff | `{ totalBookings, pendingBookings, confirmedBookings, cancelledBookings, travellingSoon, outstandingPayments, openSupportTickets }` |
| GET /admin/customers?search=&limit=&offset= | any staff | `{ total, customers:[{id,fullName,email,phone,createdAt,totalBookings,activeBookings}] }` |
| GET /admin/customers/:id | any staff | `{ customer, bookings (with Payment), tickets, contactHistory:[{id,channel,note,bookingId,createdAt,author:{id,fullName,role}}] }` |
| POST /admin/customers/:id/notes | any staff | `{ note, channel?, bookingId? }` |
| GET /admin/staff | Administrator | `[{id,fullName,email,role,status,createdAt}]` |
| POST /admin/staff | Administrator | `{ fullName, email, password, role }` |
| PATCH /admin/staff/:id | Administrator | `{ fullName?, role?, status?, password? }`. Cannot demote or deactivate yourself, and the last active administrator is protected |

## Seeded staff (run `npm run seed`)

admin@travelagency.com / Admin@123, agent@travelagency.com / Agent@123, accounts@travelagency.com / Accounts@123, support@travelagency.com / Support@123. Change these before any real demo.