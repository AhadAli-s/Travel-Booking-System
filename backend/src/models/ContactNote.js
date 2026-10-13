const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ContactNote = sequelize.define('ContactNote', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    channel: {
        type: DataTypes.ENUM('Phone', 'Email', 'InApp', 'InPerson', 'Other'),
        allowNull: false,
        defaultValue: 'Phone',
    },
    note: { type: DataTypes.TEXT, allowNull: false },
}, {
    tableName: 'contact_notes',
    timestamps: true,
});

module.exports = ContactNote;