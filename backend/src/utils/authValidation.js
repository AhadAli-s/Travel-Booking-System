const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const MIN_PASSWORD_LENGTH = 8;
const MIN_NAME_LENGTH = 2;

function normalizeEmail(email) {
    return typeof email === 'string' ? email.trim().toLowerCase() : '';
}

function isValidEmail(email) {
    return EMAIL_REGEX.test(email);
}

function validatePassword(password) {
    if (typeof password !== 'string' || password.length < MIN_PASSWORD_LENGTH) {
        return `password must be at least ${MIN_PASSWORD_LENGTH} characters`;
    }
    return null;
}

function validateRegistrationBody(body) {
    const fullName = typeof body.fullName === 'string' ? body.fullName.trim() : '';
    const email = normalizeEmail(body.email);
    const password = body.password;
    const phone = body.phone != null && body.phone !== ''
        ? String(body.phone).trim()
        : null;

    if (!fullName || fullName.length < MIN_NAME_LENGTH) {
        return { error: `fullName is required (at least ${MIN_NAME_LENGTH} characters)` };
    }
    if (!email) {
        return { error: 'email is required' };
    }
    if (!isValidEmail(email)) {
        return { error: 'email must be a valid email address' };
    }
    const passwordError = validatePassword(password);
    if (passwordError) {
        return { error: passwordError };
    }

    return { fullName, email, password, phone };
}

function validateLoginBody(body) {
    const email = normalizeEmail(body.email);
    const password = body.password;

    if (!email || password == null || password === '') {
        return { error: 'email and password are required' };
    }
    if (!isValidEmail(email)) {
        return { error: 'email must be a valid email address' };
    }

    return { email, password };
}

function validateResetPasswordBody(body) {
    const resetToken = body.resetToken;
    const newPassword = body.newPassword;

    if (!resetToken || !newPassword) {
        return { error: 'resetToken and newPassword are required' };
    }
    const passwordError = validatePassword(newPassword);
    if (passwordError) {
        return { error: passwordError };
    }

    return { resetToken, newPassword };
}

module.exports = {
    normalizeEmail,
    validateRegistrationBody,
    validateLoginBody,
    validateResetPasswordBody,
};
