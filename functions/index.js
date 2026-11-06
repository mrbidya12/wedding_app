const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * 🧠 THE BRAIN: User Creation Watcher
 * Automatically creates a profile and sets initial data when anyone signs up.
 */
exports.onUserSignup = functions.auth.user().onCreate(async (user) => {
    const userRef = db.collection('users').doc(user.uid);
    const email = user.email || '';
    
    // Default "Brain" logic for roles
    let role = 'client';
    const admins = ['admin@gmail.com', 'razz@gmail.com', 'bichitra@gmail.com'];
    if (admins.includes(email.toLowerCase())) {
        role = 'admin';
    }

    console.log(`🧠 Brain: New User Detected (${email}). Assigning role: ${role}`);

    return userRef.set({
        uid: user.uid,
        email: email,
        fullName: user.displayName || email.split('@')[0] || 'New Member',
        role: role,
        status: 'active',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
});

/**
 * 🧠 THE BRAIN: Booking Processor
 * When a booking is created, this logic handles calculations or notifications.
 */
exports.processNewBooking = functions.firestore
    .document('bookings/{bookingId}')
    .onCreate(async (snap, context) => {
        const booking = snap.data();
        console.log(`🧠 Brain: Processing new booking ${context.params.bookingId}`);
        
        // Example Brain Logic: Update vendor's total booking count
        const vendorId = booking.vendorId;
        if (vendorId) {
            const vendorRef = db.collection('vendors').doc(vendorId);
            await vendorRef.update({
                totalBookings: admin.firestore.FieldValue.increment(1)
            });
        }
    });
