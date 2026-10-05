const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Transfer = sequelize.define('Transfer', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    pickupLocation: { type: DataTypes.STRING, allowNull: true },
    pickupTime: { type: DataTypes.DATE, allowNull: true },
    dropoffLocation: { type: DataTypes.STRING, allowNull: true },
    transferStatus: {
        type: DataTypes.ENUM('Pending', 'Confirmed', 'Completed', 'Cancelled'),
        defaultValue: 'Pending',
    },
}, {
    tableName: 'transfers',
    timestamps: true,
});

module.exports = Transfer;