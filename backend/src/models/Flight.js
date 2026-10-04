const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Flight = sequelize.define('Flight', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    airline: { type: DataTypes.STRING, allowNull: false },
    flightNumber: { type: DataTypes.STRING, allowNull: false },
    departureAirport: { type: DataTypes.STRING, allowNull: false },
    arrivalAirport: { type: DataTypes.STRING, allowNull: false },
    departureTime: { type: DataTypes.DATE, allowNull: false },
    arrivalTime: { type: DataTypes.DATE, allowNull: false },
    returnFlightNumber: { type: DataTypes.STRING, allowNull: true },
    returnDepartureTime: { type: DataTypes.DATE, allowNull: true },
    returnArrivalTime: { type: DataTypes.DATE, allowNull: true },
    baggageAllowance: { type: DataTypes.STRING, allowNull: true },
}, {
    tableName: 'flights',
    timestamps: true,
});

module.exports = Flight;