const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const SupportTicket = sequelize.define('SupportTicket', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    category: {
        type: DataTypes.ENUM(
            'Flight', 'Hotel', 'Payment', 'Transfer', 'Document',
            'PassengerDetails', 'CancellationRequest', 'GeneralSupport'
        ),
        allowNull: false,
    },
    subject: { type: DataTypes.STRING, allowNull: false },
    description: { type: DataTypes.TEXT, allowNull: false },
    status: {
        type: DataTypes.ENUM('Open', 'InProgress', 'WaitingForCustomer', 'Resolved', 'Closed'),
        defaultValue: 'Open',
    },
}, {
    tableName: 'support_tickets',
    timestamps: true,
});

module.exports = SupportTicket;