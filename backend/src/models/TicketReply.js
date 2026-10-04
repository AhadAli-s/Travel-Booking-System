const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const TicketReply = sequelize.define('TicketReply', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    senderType: { type: DataTypes.ENUM('Customer', 'Staff'), allowNull: false },
    message: { type: DataTypes.TEXT, allowNull: false },
}, {
    tableName: 'ticket_replies',
    timestamps: true,
});

module.exports = TicketReply;