const sequelize = require('../config/database');

const Customer = require('./Customer');
const Staff = require('./Staff');
const Booking = require('./Booking');
const Flight = require('./Flight');
const Hotel = require('./Hotel');
const Transfer = require('./Transfer');
const Payment = require('./Payment');
const PaymentHistory = require('./PaymentHistory');
const Document = require('./Document');
const Passenger = require('./Passenger');
const SupportTicket = require('./SupportTicket');
const TicketReply = require('./TicketReply');
const Notification = require('./Notification');

// --- Customer <-> Booking ---
Customer.hasMany(Booking, { foreignKey: 'customerId', onDelete: 'CASCADE' });
Booking.belongsTo(Customer, { foreignKey: 'customerId' });

// --- Staff assigned to Booking ---
Staff.hasMany(Booking, { foreignKey: 'assignedStaffId', onDelete: 'SET NULL' });
Booking.belongsTo(Staff, { foreignKey: 'assignedStaffId', as: 'assignedStaff' });

// --- Booking <-> Flight (one booking can have one outbound+return flight record) ---
Booking.hasOne(Flight, { foreignKey: 'bookingId', onDelete: 'CASCADE' });
Flight.belongsTo(Booking, { foreignKey: 'bookingId' });

// --- Booking <-> Hotel ---
Booking.hasOne(Hotel, { foreignKey: 'bookingId', onDelete: 'CASCADE' });
Hotel.belongsTo(Booking, { foreignKey: 'bookingId' });

// --- Booking <-> Transfer ---
Booking.hasOne(Transfer, { foreignKey: 'bookingId', onDelete: 'CASCADE' });
Transfer.belongsTo(Booking, { foreignKey: 'bookingId' });

// --- Booking <-> Payment ---
Booking.hasOne(Payment, { foreignKey: 'bookingId', onDelete: 'CASCADE' });
Payment.belongsTo(Booking, { foreignKey: 'bookingId' });

// --- Payment <-> PaymentHistory ---
Payment.hasMany(PaymentHistory, { foreignKey: 'paymentId', onDelete: 'CASCADE' });
PaymentHistory.belongsTo(Payment, { foreignKey: 'paymentId' });

// --- Booking <-> Document ---
Booking.hasMany(Document, { foreignKey: 'bookingId', onDelete: 'CASCADE' });
Document.belongsTo(Booking, { foreignKey: 'bookingId' });

// --- Booking <-> Passenger ---
Booking.hasMany(Passenger, { foreignKey: 'bookingId', onDelete: 'CASCADE' });
Passenger.belongsTo(Booking, { foreignKey: 'bookingId' });

// --- Customer <-> SupportTicket, Booking <-> SupportTicket (optional) ---
Customer.hasMany(SupportTicket, { foreignKey: 'customerId', onDelete: 'CASCADE' });
SupportTicket.belongsTo(Customer, { foreignKey: 'customerId' });

Booking.hasMany(SupportTicket, { foreignKey: 'bookingId', onDelete: 'SET NULL' });
SupportTicket.belongsTo(Booking, { foreignKey: 'bookingId' });

Staff.hasMany(SupportTicket, { foreignKey: 'assignedStaffId', onDelete: 'SET NULL' });
SupportTicket.belongsTo(Staff, { foreignKey: 'assignedStaffId', as: 'assignedStaff' });

// --- SupportTicket <-> TicketReply ---
SupportTicket.hasMany(TicketReply, { foreignKey: 'ticketId', onDelete: 'CASCADE' });
TicketReply.belongsTo(SupportTicket, { foreignKey: 'ticketId' });

// --- Customer <-> Notification ---
Customer.hasMany(Notification, { foreignKey: 'customerId', onDelete: 'CASCADE' });
Notification.belongsTo(Customer, { foreignKey: 'customerId' });

module.exports = {
    sequelize,
    Customer,
    Staff,
    Booking,
    Flight,
    Hotel,
    Transfer,
    Payment,
    PaymentHistory,
    Document,
    Passenger,
    SupportTicket,
    TicketReply,
    Notification,
};