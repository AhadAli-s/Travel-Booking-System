const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Payment = sequelize.define('Payment', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    totalPackagePrice: { type: DataTypes.DECIMAL(10, 2), allowNull: false },
    amountPaid: { type: DataTypes.DECIMAL(10, 2), defaultValue: 0 },
    paymentDueDate: { type: DataTypes.DATEONLY, allowNull: true },
    paymentStatus: {
        type: DataTypes.ENUM('Unpaid', 'PartiallyPaid', 'FullyPaid', 'Refunded'),
        defaultValue: 'Unpaid',
    },
}, {
    tableName: 'payments',
    timestamps: true,
});

module.exports = Payment;