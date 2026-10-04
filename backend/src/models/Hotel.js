const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Hotel = sequelize.define('Hotel', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    hotelName: { type: DataTypes.STRING, allowNull: false },
    hotelAddress: { type: DataTypes.STRING, allowNull: true },
    roomType: { type: DataTypes.STRING, allowNull: true },
    numRooms: { type: DataTypes.INTEGER, defaultValue: 1 },
    boardBasis: { type: DataTypes.STRING, allowNull: true },
    checkInDate: { type: DataTypes.DATEONLY, allowNull: false },
    checkOutDate: { type: DataTypes.DATEONLY, allowNull: false },
    confirmationNumber: { type: DataTypes.STRING, allowNull: true },
}, {
    tableName: 'hotels',
    timestamps: true,
});

module.exports = Hotel;