const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Document = sequelize.define('Document', {
    id: { type: DataTypes.INTEGER, primaryKey: true, autoIncrement: true },
    documentType: {
        type: DataTypes.ENUM(
            'BookingConfirmation', 'FlightTickets', 'HotelVoucher', 'TransferVoucher',
            'TravelInsurance', 'VisaDocuments', 'ATOLCertificate', 'Invoice', 'PaymentReceipt'
        ),
        allowNull: false,
    },
    fileName: { type: DataTypes.STRING, allowNull: false },
    filePath: { type: DataTypes.STRING, allowNull: false },
    uploadedAt: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
}, {
    tableName: 'documents',
    timestamps: true,
});

module.exports = Document;