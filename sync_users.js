const admin = require('firebase-admin');

// 1. TO RUN THIS: Go to Firebase Console > Project Settings > Service Accounts
// 2. Click "Generate New Private Key"
// 3. Rename the downloaded file to "serviceAccountKey.json" and put it in this folder.

const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function syncUsers() {
  console.log('--- Starting User Migration ---');
  
  try {
    const listUsersResult = await auth.listUsers(1000);
    const adminEmails = ['admin@gmail.com', 'razz@gmail.com', 'bichitra@gmail.com'];
    
    let count = 0;
    const batch = db.batch();

    listUsersResult.users.forEach((userRecord) => {
      const userRef = db.collection('users').doc(userRecord.uid);
      const role = adminEmails.includes(userRecord.email?.toLowerCase()) ? 'admin' : 'client';

      batch.set(userRef, {
        uid: userRecord.uid,
        email: userRecord.email || '',
        fullName: userRecord.displayName || userRecord.email?.split('@')[0] || 'New User',
        phone: userRecord.phoneNumber || '',
        role: role,
        state: '',
        city: '',
        village: '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      
      count++;
    });

    await batch.commit();
    console.log(`Successfully synced ${count} users to Firestore!`);
    console.log('You can now open your app and the Total User list will be full.');
  } catch (error) {
    console.error('Error syncing users:', error);
  }
}

syncUsers();
