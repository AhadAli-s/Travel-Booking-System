const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Staff = sequelize.define('Staff', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    fullName: { type: DataTypes.STRING, allowNull: false },
    email: { type: DataTypes.STRING, allowNull: false, unique: true, validate: { isEmail: true } },
    passwordHash: { type: DataTypes.STRING, allowNull: false },
    role: {
        type: DataTypes.ENUM('Administrator', 'BookingAgent', 'AccountsStaff', 'SupportAgent'),
        allowNull: false,
    },
    status: { type: DataTypes.ENUM('Active', 'Inactive'), defaultValue: 'Active' },
}, {
    tableName: 'staff',
    timestamps: true,
});

module.exports = Staff;