const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

// NOTE: passportNumber is sensitive data. It should never be returned in a
// plain list/summary endpoint — only on an explicit, authorized single-passenger
// detail request. See passenger controller for the field-filtering logic.
const Passenger = sequelize.define('Passenger', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    fullName: { type: DataTypes.STRING, allowNull: false },
    dateOfBirth: { type: DataTypes.DATEONLY, allowNull: false },
    passengerType: {
        type: DataTypes.ENUM('Adult', 'Child', 'Infant'),
        allowNull: false,
    },
    passportNumber: { type: DataTypes.STRING, allowNull: true },
    passportExpiry: { type: DataTypes.DATEONLY, allowNull: true },
    specialAssistance: { type: DataTypes.STRING, allowNull: true },
    mealPreference: { type: DataTypes.STRING, allowNull: true },
    baggage: { type: DataTypes.STRING, allowNull: true },
}, {
    tableName: 'passengers',
    timestamps: true,
});

module.exports = Passenger;