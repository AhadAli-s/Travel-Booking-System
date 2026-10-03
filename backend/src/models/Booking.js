const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Booking = sequelize.define('Booking', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    bookingReference: { type: DataTypes.STRING, allowNull: false, unique: true },
    bookingDate: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
    status: {
        type: DataTypes.ENUM(
            'Pending', 'Processing', 'AwaitingPayment', 'PaymentReceived', 'Confirmed',
            'DocumentsPending', 'DocumentsIssued', 'ReadyToTravel', 'TravelCompleted',
            'Cancelled', 'Closed'
        ),
        defaultValue: 'Pending',
    },
    numAdults: { type: DataTypes.INTEGER, defaultValue: 1 },
    numChildren: { type: DataTypes.INTEGER, defaultValue: 0 },
    numInfants: { type: DataTypes.INTEGER, defaultValue: 0 },
    destination: { type: DataTypes.STRING, allowNull: false },
    departureCity: { type: DataTypes.STRING, allowNull: true },
    departureAirport: { type: DataTypes.STRING, allowNull: true },
    travelDate: { type: DataTypes.DATEONLY, allowNull: false },
    returnDate: { type: DataTypes.DATEONLY, allowNull: false },
    numNights: { type: DataTypes.INTEGER, allowNull: true },
    notes: { type: DataTypes.TEXT, allowNull: true },
}, {
    tableName: 'bookings',
    timestamps: true,
});

module.exports = Booking;