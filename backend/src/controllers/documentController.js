const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const multer = require('multer');
const { Booking, Document } = require('../models/index');
const { generateToken, verifyToken } = require('../utils/jwt');
const { requireAuth } = require('../middleware/auth');
const { notifyCustomer } = require('../utils/notify');
const { sendError } = require('../utils/sendError');

const UPLOAD_DIR = path.join(__dirname, '..', '..', 'uploads', 'documents');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const ALLOWED_TYPES = ['application/pdf', 'image/png', 'image/jpeg'];
const VALID_DOCUMENT_TYPES = [
    'BookingConfirmation', 'FlightTickets', 'HotelVoucher', 'TransferVoucher',
    'TravelInsurance', 'VisaDocuments', 'ATOLCertificate', 'Invoice', 'PaymentReceipt',
];

const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, UPLOAD_DIR),
    // Random stored name: the original filename is kept in the database only,
    // so stored files can never be guessed or collide.
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        cb(null, `${crypto.randomBytes(16).toString('hex')}${ext}`);
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 10 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        if (!ALLOWED_TYPES.includes(file.mimetype)) {
            return cb(new Error('Only PDF, PNG, and JPEG files are allowed'));
        }
        cb(null, true);
    },
});

async function loadBookingWithAccess(req, res) {
    const booking = await Booking.findByPk(req.params.bookingId);
    if (!booking) {
        res.status(404).json({ error: 'Booking not found' });
        return null;
    }
    if (req.user.type === 'customer' && booking.customerId !== req.user.id) {
        res.status(403).json({ error: 'You do not have access to this booking' });
        return null;
    }
    return booking;
}

/** Staff: upload a document for a booking. Form fields: documentType, file */
async function uploadDocument(req, res) {
    try {
        const booking = await Booking.findByPk(req.params.bookingId);
        if (!booking) {
            if (req.file) fs.unlinkSync(req.file.path);
            return res.status(404).json({ error: 'Booking not found' });
        }

        const { documentType } = req.body;
        if (!VALID_DOCUMENT_TYPES.includes(documentType)) {
            if (req.file) fs.unlinkSync(req.file.path);
            return res.status(400).json({
                error: `documentType must be one of: ${VALID_DOCUMENT_TYPES.join(', ')}`,
            });
        }
        if (!req.file) {
            return res.status(400).json({ error: 'A file is required' });
        }

        const document = await Document.create({
            bookingId: booking.id,
            documentType,
            fileName: req.file.originalname,
            filePath: req.file.filename,
        });

        await notifyCustomer(
            booking.customerId,
            'DocumentAvailable',
            `A new document (${documentType}) is available for booking ${booking.bookingReference}.`
        );

        res.status(201).json({
            id: document.id,
            documentType: document.documentType,
            fileName: document.fileName,
            uploadedAt: document.uploadedAt,
        });
    } catch (err) {
        sendError(res, err);
    }
}

/** Customer (own booking) or staff: list documents for a booking */
async function listDocuments(req, res) {
    try {
        const booking = await loadBookingWithAccess(req, res);
        if (!booking) return;

        const documents = await Document.findAll({
            where: { bookingId: booking.id },
            attributes: ['id', 'documentType', 'fileName', 'uploadedAt'],
            order: [['uploadedAt', 'DESC']],
        });
        res.json(documents);
    } catch (err) {
        sendError(res, err);
    }
}

const LINK_SECONDS = 90;

/**
 * Looks up a document and checks that this user may access it.
 * Returns { document } or { status, error }.
 */
async function findDocumentForUser(user, documentId) {
    const document = await Document.findByPk(documentId);
    if (!document) return { status: 404, error: 'Document not found' };

    const booking = await Booking.findByPk(document.bookingId);
    if (user.type === 'customer' && booking.customerId !== user.id) {
        return { status: 403, error: 'You do not have access to this document' };
    }
    return { document };
}

/**
 * Customer (own booking) or staff: get a short lived download link.
 * Apps open this link in the browser or system viewer, which cannot send an
 * Authorization header. The link works for one document and expires quickly.
 */
async function createDocumentLink(req, res) {
    try {
        const found = await findDocumentForUser(req.user, req.params.id);
        if (found.error) return res.status(found.status).json({ error: found.error });

        const token = generateToken(
            { purpose: 'document', docId: found.document.id, userId: req.user.id, userType: req.user.type },
            `${LINK_SECONDS}s`
        );
        res.json({
            url: `/api/documents/${found.document.id}/download?t=${token}`,
            expiresInSeconds: LINK_SECONDS,
        });
    } catch (err) {
        sendError(res, err);
    }
}

/** Accepts either a normal login token or a signed document link (?t=...). */
function authenticateDownload(req, res, next) {
    const linkToken = typeof req.query.t === 'string' ? req.query.t : null;
    if (!linkToken) return requireAuth(req, res, next);

    try {
        const payload = verifyToken(linkToken);
        if (payload.purpose !== 'document' || String(payload.docId) !== String(req.params.id)) {
            throw new Error('wrong link');
        }
        req.user = { id: payload.userId, type: payload.userType };
        next();
    } catch (err) {
        res.status(401).json({ error: 'Download link is invalid or has expired' });
    }
}

/** Customer (own booking) or staff: download one document after an ownership check */
async function downloadDocument(req, res) {
    try {
        const found = await findDocumentForUser(req.user, req.params.id);
        if (found.error) return res.status(found.status).json({ error: found.error });
        const { document } = found;

        const fullPath = path.join(UPLOAD_DIR, document.filePath);
        if (!fs.existsSync(fullPath)) {
            return res.status(404).json({ error: 'File is missing from storage' });
        }

        // inline: PDFs and images open in the viewer instead of silently downloading
        res.sendFile(fullPath, {
            headers: {
                'Content-Disposition': `inline; filename*=UTF-8''${encodeURIComponent(document.fileName)}`,
                'Cache-Control': 'private, no-store',
            },
        });
    } catch (err) {
        sendError(res, err);
    }
}

/** Staff: delete a document and its stored file */
async function deleteDocument(req, res) {
    try {
        const document = await Document.findByPk(req.params.id);
        if (!document) return res.status(404).json({ error: 'Document not found' });

        const fullPath = path.join(UPLOAD_DIR, document.filePath);
        if (fs.existsSync(fullPath)) fs.unlinkSync(fullPath);

        await document.destroy();
        res.json({ message: 'Document deleted' });
    } catch (err) {
        sendError(res, err);
    }
}

module.exports = {
    upload,
    uploadDocument,
    listDocuments,
    createDocumentLink,
    authenticateDownload,
    downloadDocument,
    deleteDocument,
};