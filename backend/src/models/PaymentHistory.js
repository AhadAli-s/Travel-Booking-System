const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const PaymentHistory = sequelize.define('PaymentHistory', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    amount: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
    paymentDate: { type: DataTypes.DATE, allowNull: false, defaultValue: DataTypes.NOW },
    method: { type: DataTypes.STRING, allowNull: true },
    note: { type: DataTypes.STRING, allowNull: true },
}, {
    tableName: 'payment_history',
    timestamps: true,
});

module.exports = PaymentHistory;